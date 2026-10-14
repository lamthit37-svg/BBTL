-- XiariZhanling 夏日拉收战令 lishilong
-- !!!reloadscript =XiariZhanling
--

local g_XiariZhanling_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 			= 3.0
local g_nObjCaredIDClient 		= -1
local g_nServerObjID 			= -1
local bCaredItem 				= 0
local bCaredObj 				= 0
local bCaredMoney 				= 0
local bCaredYuanBao				= 0
local g_nComfirmParam1			= 0

-- 服务器传参	
local g_nHuoDongStep			= 0
local g_nRemainDay				= 0
local g_nPointTotal				= 0
local g_nPointToday				= 0
local g_nRewardMDNormal			= 0
local g_nRewardMDRMB			= 0
local g_bIsActRMBReward			= 0
local g_bShowHotPoint			= 0
local g_tWaiGuaiBuyState 		= {1, 1, 1}
local g_bPlayAnimate			= 0

-- 轮播时间 10s
-- local g_nImageTimerCD			= 10000
-- local g_nCurShowImageIndex		= 1
-- local g_tShowImageInfo			= 
-- {
-- 	[1] = "set:XiariZhanling2 image:XiariZhanling_LeftBK_Jinling",
-- 	[2] = "set:XiariZhanling2 image:XiariZhanling_LeftBK_Lixia",
-- }

-- 控件
-- local g_cLevelShowText 		= {}
-- local g_cNormalActionButton 	= {}
-- local g_cNormalLockImg		= {}
-- local g_cNormalTips			= {}
-- local g_cNormalGetedMark		= {}
-- local g_cRMBActionButton 	= {}
-- local g_cRMBLockImg			= {}
-- local g_cRMBTips				= {}
-- local g_cRMBGetedMark		= {}
local g_cWaiGuanActionButton	= {}
local g_cWaiGuanUnLockText		= {}
local g_cWaiGuanCostYBText		= {}
local g_cWaiGuanCostYBDaZheText	= {}
local g_cWaiGuanGeted			= {}
local g_cWaiGuanBuyButton		= {}
local g_cListActionButton		= {}

-- 最大支持战阶 页面加载会重新赋值
local g_nLimitZhanJieNew		= 32

-- 每页显示的等级数
local g_nShowNumPerPage			= 6
-- 当前显示页数
-- local g_nCurShowPage			= 0
-- 滚动条位置
local g_Position_Scroll			= 0

-- 外观信息
--	PushEvent("OPEN_DRESSPREVIEW", 10125233, 74, 46)
-- 38008243		头饰背饰礼盒
-- 10192236		高级幻武
-- 38008244		时装礼盒

-- 38008252		背饰
-- 10192236		高级幻武	10192235
-- 38008244		时装礼盒

local g_tWaiGuanInfo		= 
{
	[1] = {nItemID = 38008252, nUnLoskMsg = "xxxxxxxxxxxxxxxxx", nCostYB = 8888, 	nCostYBDaZhe = 6588,	},
	[2] = {nItemID = 10192235, nUnLoskMsg = "#{XRZL_250508_58}", nCostYB = 16888, 	nCostYBDaZhe = 11888,	},
	[3] = {nItemID = 38008244, nUnLoskMsg = "#{XRZL_250508_59}", nCostYB = 15888, 	nCostYBDaZhe = 10888,	},
}

local g_tWaiGuanShowInfo	= 
{
	[1] = {nShowDressId = 10128528, nShowHairId = 281, nShowFaceId = 205,},
	[2] = {nShowDressId = 10128528, nShowHairId = 281, nShowFaceId = 205,},
}


local g_nMainScriptID		= 791150
local g_nUICommandID		= 79115001

--=========================================================
-- PreLoad
--=========================================================
function XiariZhanling_PreLoad()
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
end

--=========================================================
-- OnLoad
--=========================================================
function XiariZhanling_OnLoad()
	g_XiariZhanling_Frame_UnifiedPosition = XiariZhanling_Frame:GetProperty("UnifiedPosition")

	-- XiariZhanling_OK_Button : SetEvent("Clicked", "XiariZhanling_ConfirmClick()")

	-- g_cLevelShowText[1] 		= XiariZhanling_Icon_ListTitle1
	-- g_cLevelShowText[2] 		= XiariZhanling_Icon_ListTitle2
	-- g_cLevelShowText[3] 		= XiariZhanling_Icon_ListTitle3
	-- g_cLevelShowText[4] 		= XiariZhanling_Icon_ListTitle4
	-- g_cLevelShowText[5] 		= XiariZhanling_Icon_ListTitle5
	-- g_cLevelShowText[6] 		= XiariZhanling_Icon_ListTitle6

	-- g_cNormalActionButton[1] 	= XiariZhanling_Icon1
	-- g_cNormalActionButton[2] 	= XiariZhanling_Icon2
	-- g_cNormalActionButton[3] 	= XiariZhanling_Icon3
	-- g_cNormalActionButton[4] 	= XiariZhanling_Icon4
	-- g_cNormalActionButton[5] 	= XiariZhanling_Icon5
	-- g_cNormalActionButton[6] 	= XiariZhanling_Icon6
	-- g_cRMBActionButton[1] 		= XiariZhanling_Icon7
	-- g_cRMBActionButton[2] 		= XiariZhanling_Icon8
	-- g_cRMBActionButton[3] 		= XiariZhanling_Icon9
	-- g_cRMBActionButton[4] 		= XiariZhanling_Icon10
	-- g_cRMBActionButton[5] 		= XiariZhanling_Icon11
	-- g_cRMBActionButton[6] 		= XiariZhanling_Icon12

	-- g_cNormalLockImg[1] 		= XiariZhanling_Icon1_LockImg
	-- g_cNormalLockImg[2] 		= XiariZhanling_Icon2_LockImg
	-- g_cNormalLockImg[3] 		= XiariZhanling_Icon3_LockImg
	-- g_cNormalLockImg[4] 		= XiariZhanling_Icon4_LockImg
	-- g_cNormalLockImg[5] 		= XiariZhanling_Icon5_LockImg
	-- g_cNormalLockImg[6] 		= XiariZhanling_Icon6_LockImg
	-- g_cRMBLockImg[1] 			= XiariZhanling_Icon7_LockImg
	-- g_cRMBLockImg[2] 			= XiariZhanling_Icon8_LockImg
	-- g_cRMBLockImg[3] 			= XiariZhanling_Icon9_LockImg
	-- g_cRMBLockImg[4] 			= XiariZhanling_Icon10_LockImg
	-- g_cRMBLockImg[5] 			= XiariZhanling_Icon11_LockImg
	-- g_cRMBLockImg[6] 			= XiariZhanling_Icon12_LockImg

	-- g_cNormalTips[1] 			= XiariZhanling_Icon1_Tips
	-- g_cNormalTips[2] 			= XiariZhanling_Icon2_Tips
	-- g_cNormalTips[3] 			= XiariZhanling_Icon3_Tips
	-- g_cNormalTips[4] 			= XiariZhanling_Icon4_Tips
	-- g_cNormalTips[5] 			= XiariZhanling_Icon5_Tips
	-- g_cNormalTips[6] 			= XiariZhanling_Icon6_Tips
	-- g_cRMBTips[1] 				= XiariZhanling_Icon7_Tips
	-- g_cRMBTips[2] 				= XiariZhanling_Icon8_Tips
	-- g_cRMBTips[3] 				= XiariZhanling_Icon9_Tips
	-- g_cRMBTips[4] 				= XiariZhanling_Icon10_Tips
	-- g_cRMBTips[5] 				= XiariZhanling_Icon11_Tips
	-- g_cRMBTips[6] 				= XiariZhanling_Icon12_Tips

	-- g_cNormalGetedMark[1] 		= XiariZhanling_Icon1_Mark
	-- g_cNormalGetedMark[2] 		= XiariZhanling_Icon2_Mark
	-- g_cNormalGetedMark[3] 		= XiariZhanling_Icon3_Mark
	-- g_cNormalGetedMark[4] 		= XiariZhanling_Icon4_Mark
	-- g_cNormalGetedMark[5] 		= XiariZhanling_Icon5_Mark
	-- g_cNormalGetedMark[6] 		= XiariZhanling_Icon6_Mark
	-- g_cRMBGetedMark[1] 			= XiariZhanling_Icon7_Mark
	-- g_cRMBGetedMark[2] 			= XiariZhanling_Icon8_Mark
	-- g_cRMBGetedMark[3] 			= XiariZhanling_Icon9_Mark
	-- g_cRMBGetedMark[4] 			= XiariZhanling_Icon10_Mark
	-- g_cRMBGetedMark[5] 			= XiariZhanling_Icon11_Mark
	-- g_cRMBGetedMark[6] 			= XiariZhanling_Icon12_Mark

	g_cWaiGuanActionButton[1] 	= XiariZhanling_Down_Item1_Icon
	g_cWaiGuanActionButton[2] 	= XiariZhanling_Down_Item2_Icon
	g_cWaiGuanActionButton[3] 	= XiariZhanling_Down_Item3_Icon
	-- g_cWaiGuanActionButton[4] 	= XiariZhanling_Down_Item4_Icon

	g_cWaiGuanUnLockText[1] 	= XiariZhanling_Down_Item1_Text1
	g_cWaiGuanUnLockText[2] 	= XiariZhanling_Down_Item2_Text1
	g_cWaiGuanUnLockText[3] 	= XiariZhanling_Down_Item3_Text1
	-- g_cWaiGuanUnLockText[4] 	= XiariZhanling_Down_Item4_Text1

	g_cWaiGuanCostYBText[1] 	= XiariZhanling_Down_Item1_Money
	g_cWaiGuanCostYBText[2] 	= XiariZhanling_Down_Item2_Money
	g_cWaiGuanCostYBText[3] 	= XiariZhanling_Down_Item3_Money
	-- g_cWaiGuanCostYBText[4] 	= XiariZhanling_Down_Item4_Money

	g_cWaiGuanCostYBDaZheText[1]	= XiariZhanling_Down_Item1_PriceMoney
	g_cWaiGuanCostYBDaZheText[2]	= XiariZhanling_Down_Item2_PriceMoney
	g_cWaiGuanCostYBDaZheText[3]	= XiariZhanling_Down_Item3_PriceMoney

	g_cWaiGuanGeted[1] 			= XiariZhanling_Down_Item1_Received
	g_cWaiGuanGeted[2] 			= XiariZhanling_Down_Item2_Received
	g_cWaiGuanGeted[3] 			= XiariZhanling_Down_Item3_Received
	-- g_cWaiGuanGeted[4] 			= XiariZhanling_Down_Item4_Received

	g_cWaiGuanBuyButton[1] 		= XiariZhanling_Down_Item1_Get
	g_cWaiGuanBuyButton[2] 		= XiariZhanling_Down_Item2_Get
	g_cWaiGuanBuyButton[3] 		= XiariZhanling_Down_Item3_Get
	-- g_cWaiGuanBuyButton[4] 		= XiariZhanling_Down_Item4_Get

end

--=========================================================
-- OnEvent
--=========================================================
function XiariZhanling_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				XiariZhanling_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						XiariZhanling_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_XiariZhanling()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	XiariZhanling_OnClose()
			-- end
			XiariZhanling_Reset()
			XiariZhanling_Frame_On_ResetPos()
			this:Show()
			XiariZhanling_ParamInit()
			XiariZhanling_MoneyUpdate()
			XiariZhanling_YuanBaoUpdate()
			XiariZhanling_Update(1)

			-- KillTimer("XiariZhanling_OnTimerEnd()");	
			-- SetTimer("XiariZhanling","XiariZhanling_OnTimerEnd()", g_nImageTimerCD)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						XiariZhanling_OnClose()
					end
				end
			end
			if this:IsVisible() then
				XiariZhanling_ParamInit()
				
				-- 只有打开页面时刷新页面才记录上一次的滚动条
				g_Position_Scroll = XiariZhanling_IconList : GetScrollPosition()

				XiariZhanling_Update(0)

				-- 动画 放在这里吧 防止刷新顶掉
				-- if 1 == g_bPlayAnimate then
				-- 	-- PushDebugMessage("1 == g_bPlayAnimate")
				-- 	XiariZhanling_Icon_Img2_Animate : Show()
				-- 	XiariZhanling_Icon_Img2_Animate : Play(true)
				-- else
				-- 	-- PushDebugMessage("1 == g_bPlayAnimate hide")
				-- 	XiariZhanling_Icon_Img2_Animate : Hide()
				-- end
	
			end
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
			XiariZhanling_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			XiariZhanling_Update(0)
		end

	-- 金钱改变
	elseif (event == "UNIT_MONEY" or event == "MONEYJZ_CHANGE") and 1 == bCaredMoney then
		XiariZhanling_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		XiariZhanling_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		XiariZhanling_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		XiariZhanling_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiariZhanling_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function XiariZhanling_ParamInit()
	-- 参数1：界面操作类型（0 关闭，1打开， 2刷新）
	-- 参数2：活动阶段
	-- 参数3：活动剩余天数
	-- 参数4：玩家共计战令点数
	-- 参数5：玩家当日战令点数

	-- 参数6：普通奖励MD（从最低位开始，按位取标记即可，最大支持32个战阶）
	-- 参数7：RMB奖励MD（从最低位开始，按位取标记即可，最大支持32个战阶）
	-- 参数8：是否激活RMB奖励
	-- 参数9：是否显示红点
	-- 参数10、11、12、13 1-4号外观购买状态 0 未领取 1 已领取 -1 未到可领取时间
	-- 参数14：是否播放激活动画
	
	-- 客户端参数id少1
	g_nHuoDongStep			= Get_XParam_INT(1)
	g_nRemainDay			= Get_XParam_INT(2)
	g_nPointTotal			= Get_XParam_INT(3)
	g_nPointToday			= Get_XParam_INT(4)
	g_nRewardMDNormal		= Get_XParam_INT(5)
	g_nRewardMDRMB			= Get_XParam_INT(6)
	g_bIsActRMBReward		= Get_XParam_INT(7)
	g_bShowHotPoint			= Get_XParam_INT(8)
	g_tWaiGuaiBuyState[1]	= Get_XParam_INT(9)
	g_tWaiGuaiBuyState[2]	= Get_XParam_INT(10)
	g_tWaiGuaiBuyState[3]	= Get_XParam_INT(11)
	-- g_tWaiGuaiBuyState[4]	= Get_XParam_INT(12)
	g_bPlayAnimate			= Get_XParam_INT(12)

	local bRet, nNeedPoint, nRecordNum = GetSummerZhanLingPrizeInfo(1)
	if nil == bRet or 1 ~= bRet then
		PushDebugMessage("页面数据加载失败，请重新打开页面。")
		XiariZhanling_OnClose()
	end

	g_nLimitZhanJieNew = nRecordNum

end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =XiariZhanling
function XiariZhanling_Update(bOpen)

	local nCurLevel, nCurLevelHaveExp, nCurLevelTotalExp, bMaxLevel = XiariZhanling_GetCurLevelAndExpInfo()
	if nCurLevel < 0 then 
		PushDebugMessage("页面数据加载失败，请重新打开页面。")
		XiariZhanling_OnClose()
	end

	-- 今日获取点数显示
	if 1 == g_bIsActRMBReward then
		XiariZhanling_Up_Text5 : SetText( ScriptGlobal_Format("#{XRZL_250508_90}", g_nPointToday) )
	else
		XiariZhanling_Up_Text5 : SetText( ScriptGlobal_Format("#{XRZL_250508_89}", g_nPointToday) )
	end

	if 1 ~= bMaxLevel and 1 == g_nHuoDongStep then
		XiariZhanling_Up_Text5 : Show()
	else
		XiariZhanling_Up_Text5 : Hide()
	end

	-- 等级追赶提示仅在一阶段显示
	if 1 == g_nHuoDongStep then
		XiariZhanling_Up_Text4 : Show()
	else
		XiariZhanling_Up_Text4 : Hide()
	end

	-- 等级设置
	XiariZhanling_Up_Text1 : SetText( ScriptGlobal_Format("#{XRZL_250508_75}", nCurLevel) )

	-- 显示经验
	XiariZhanling_Up_Text2 : SetText( ScriptGlobal_Format("#{XRZL_250508_11}", nCurLevelHaveExp, nCurLevelTotalExp) )
	if 1 == bMaxLevel then
		XiariZhanling_Up_Text2 : SetText( "#{XRZL_250508_34}" )
	end

	-- 进度条设置
	XiariZhanling_Progress : SetProgress(nCurLevelHaveExp, nCurLevelTotalExp)

	-- 解锁按钮
	if 1 == g_bIsActRMBReward then
		XiariZhanling_Icon2_AwardBrn : Hide()
	else
		XiariZhanling_Icon2_AwardBrn : Show()
	end
	
	-- 剩余天数
	if g_nRemainDay >= 1 then
		XiariZhanling_Up_Text3 : SetText( ScriptGlobal_Format("#{XRZL_250508_12}", g_nRemainDay) )
	else
		XiariZhanling_Up_Text3 : SetText( "#{XRZL_250508_13}" )
	end

	-- 显示具体等级
	-- if 0 == g_nCurShowPage then 

	-- 	if 0 == nCurLevel then
	-- 		g_nCurShowPage = 1
	-- 	else
	-- 		g_nCurShowPage = math.floor( (nCurLevel - 1 ) / g_nShowNumPerPage) + 1
	-- 	end

	-- 	if 0 == g_nCurShowPage then
	-- 		g_nCurShowPage = 1
	-- 	end
	-- end

	-- List 显示
	XiariZhanling_ClearRewardList()
	for i = 1, g_nLimitZhanJieNew do
		local barNew = XiariZhanling_IconList : AddChild("XiariZhanling_IconCommon")
		if not barNew then
			break
		end

		local nShowLevel = i

		local cLevelShowText 			= barNew : GetSubItem("XiariZhanling_Icon_ListTitle1")
		local cNormalActionButton01		= barNew : GetSubItem("XiariZhanling_Icon1")
		local cNormalActionButton02		= barNew : GetSubItem("XiariZhanling_Icon3")
		local cRMBActionButton01		= barNew : GetSubItem("XiariZhanling_Icon2")
		local cRMBActionButton02		= barNew : GetSubItem("XiariZhanling_Icon4")
		local cNormalLockImg01			= barNew : GetSubItem("XiariZhanling_Icon1_LockImg")
		local cNormalLockImg02			= barNew : GetSubItem("XiariZhanling_Icon3_LockImg")
		local cRMBLockImg01				= barNew : GetSubItem("XiariZhanling_Icon2_LockImg")
		local cRMBLockImg02				= barNew : GetSubItem("XiariZhanling_Icon4_LockImg")
		local cNormalGetedMark01		= barNew : GetSubItem("XiariZhanling_Icon1_Mark")
		local cNormalGetedMark02		= barNew : GetSubItem("XiariZhanling_Icon3_Mark")
		local cRMBGetedMark01			= barNew : GetSubItem("XiariZhanling_Icon2_Mark")
		local cRMBGetedMark02			= barNew : GetSubItem("XiariZhanling_Icon4_Mark")

		local cNormalGetButton			= barNew : GetSubItem("XiariZhanling_Icon_Get1")
		local cRMBGetButton				= barNew : GetSubItem("XiariZhanling_Icon_Get2")
		local cNormalGetButtonLock		= barNew : GetSubItem("XiariZhanling_Icon_LockImg1")
		local cRMBGetButtonLock			= barNew : GetSubItem("XiariZhanling_Icon_LockImg2")
		local cNormalGetButtonFinish	= barNew : GetSubItem("XiariZhanling_Icon_Received1")
		local cRMBGetButtonFinish		= barNew : GetSubItem("XiariZhanling_Icon_Received2")

		cLevelShowText					: SetText( "" )
		cNormalActionButton01 			: SetActionItem(-1)
		cNormalActionButton02 			: SetActionItem(-1)
		cRMBActionButton01 				: SetActionItem(-1)
		cRMBActionButton02 				: SetActionItem(-1)
		cNormalLockImg01				: Hide()
		cNormalLockImg02				: Hide()
		cRMBLockImg01					: Hide()
		cRMBLockImg02					: Hide()
		cNormalGetedMark01				: Hide()
		cNormalGetedMark02				: Hide()
		cRMBGetedMark01					: Hide()
		cRMBGetedMark02					: Hide()

		cNormalGetButton				: Hide()
		cRMBGetButton					: Hide()
		cNormalGetButtonLock			: Hide()
		cRMBGetButtonLock				: Hide()
		cNormalGetButtonFinish			: Hide()
		cRMBGetButtonFinish				: Hide()

		-- local bRet, 		
		-- 	nNeedPoint,
		-- 	nRecordNum,
		-- 	nNeedBagSpaceNormal,
		-- 	nNeedMaterialSpaceNormal,
		-- 	nRewardItemIDNormal,
		-- 	nRewardItemShowIDNormal,
		-- 	nRewardItemNumNormal,
		-- 	bRewardItemBindNormal,
		-- 	nNeedBagSpaceRMB,
		-- 	nNeedMaterialSpaceRMB,
		-- 	nRewardItemIDRMB,
		-- 	nRewardItemShowIDRMB,
		-- 	nRewardItemNumRMB,
		-- 	bRewardItemBindRMB = GetSummerZhanLingPrizeInfo(nShowLevel)
		local bRet, 		
			nNeedPoint,
			nRecordNum,
			nNeedBagSpaceNormal,
			nNeedMaterialSpaceNormal,
			nRewardItemIDNormal01,
			nRewardItemShowIDNormal01,
			nRewardItemNumNormal01,
			bRewardItemBindNormal01,
			nRewardItemIDNormal02,
			nRewardItemShowIDNormal02,
			nRewardItemNumNormal02,
			bRewardItemBindNormal02,
			nRewardItemIDNormal03,
			nRewardItemShowIDNormal03,
			nRewardItemNumNormal03,
			bRewardItemBindNormal03,
			nNeedBagSpaceRMB,
			nNeedMaterialSpaceRMB,
			nRewardItemIDRMB01,
			nRewardItemShowIDRMB01,
			nRewardItemNumRMB01,
			bRewardItemBindRMB01,
			nRewardItemIDRMB02,
			nRewardItemShowIDRMB02,
			nRewardItemNumRMB02,
			bRewardItemBindRMB02,
			nRewardItemIDRMB03,
			nRewardItemShowIDRMB03,
			nRewardItemNumRMB03,
			bRewardItemBindRMB03
			= GetSummerZhanLingPrizeInfo(nShowLevel)

		if nil == bRet or 1 ~= bRet then
			break
		end

		cLevelShowText	: SetText( ScriptGlobal_Format("#{XRZL_250508_32}", nShowLevel ) )

		-- ActionButton
		local theAction1 = nil 
		if 1 == bRewardItemBindNormal01 then
			theAction1 = DataPool:CreateBindActionItemForShow(nRewardItemShowIDNormal01, nRewardItemNumNormal01)
		else
			theAction1 = DataPool:CreateActionItemForShow(nRewardItemShowIDNormal01, nRewardItemNumNormal01)
		end
		if 0 ~= theAction1:GetID() then
			cNormalActionButton01 : SetActionItem(theAction1:GetID())
			-- cNormalActionButton01 : SetEvent("Clicked", string.format( "XiariZhanling_PrizeClickedNew(%d, %d)", nShowLevel, 0 ))
			table.insert( g_cListActionButton, cNormalActionButton01) 
		end

		local theAction2 = nil 
		if 1 == bRewardItemBindRMB01 then
			theAction2 = DataPool:CreateBindActionItemForShow(nRewardItemShowIDRMB01, nRewardItemNumRMB01)
		else
			theAction2 = DataPool:CreateActionItemForShow(nRewardItemShowIDRMB01, nRewardItemNumRMB01)
		end
		if 0 ~= theAction2:GetID() then
			cRMBActionButton01 : SetActionItem(theAction2:GetID())
			-- cRMBActionButton01 : SetEvent("Clicked", string.format( "XiariZhanling_PrizeClickedNew(%d, %d)", nShowLevel, 1 ))
			table.insert( g_cListActionButton, cRMBActionButton01) 
		end

		local theAction3 = nil 
		if 1 == bRewardItemBindNormal02 then
			theAction3 = DataPool:CreateBindActionItemForShow(nRewardItemShowIDNormal02, nRewardItemNumNormal02)
		else
			theAction3 = DataPool:CreateActionItemForShow(nRewardItemShowIDNormal02, nRewardItemNumNormal02)
		end
		if 0 ~= theAction3:GetID() then
			cNormalActionButton02 : SetActionItem(theAction3:GetID())
			-- cNormalActionButton02 : SetEvent("Clicked", string.format( "XiariZhanling_PrizeClickedNew(%d, %d)", nShowLevel, 0 ))
			table.insert( g_cListActionButton, cNormalActionButton02) 
		end

		local theAction4 = nil 
		if 1 == bRewardItemBindRMB02 then
			theAction4 = DataPool:CreateBindActionItemForShow(nRewardItemShowIDRMB02, nRewardItemNumRMB02)
		else
			theAction4 = DataPool:CreateActionItemForShow(nRewardItemShowIDRMB02, nRewardItemNumRMB02)
		end
		if 0 ~= theAction4:GetID() then
			cRMBActionButton02 : SetActionItem(theAction4:GetID())
			-- cRMBActionButton02 : SetEvent("Clicked", string.format( "XiariZhanling_PrizeClickedNew(%d, %d)", nShowLevel, 1 ))
			table.insert( g_cListActionButton, cRMBActionButton02) 
		end

		-- 是否未解锁
		if nCurLevel < nShowLevel then
			cNormalLockImg01		: Show()
			cNormalLockImg02		: Show()
			cRMBLockImg01 			: Show()
			cRMBLockImg02 			: Show()
			cNormalGetButtonLock 	: Show()
			cRMBGetButtonLock 		: Show()

			cNormalGetButtonLock 	: SetToolTip( "#{XRZL_250508_95}")
			cRMBGetButtonLock 		: SetToolTip( "#{XRZL_250508_95}")
		else
			-- 是否领取
			-- nIndex 从0开始
			local bRetNormal, bGetedNormal = GetBitValueInUINT(g_nRewardMDNormal, nShowLevel -1, 1)
			local bRetRMB, bGetedRMB = GetBitValueInUINT(g_nRewardMDRMB, nShowLevel -1, 1)
			if 1 == bRetNormal and 1 == bGetedNormal then
				cNormalGetedMark01 	: Show()						
				cNormalGetedMark02 	: Show()
				cNormalGetButtonFinish	: Show()			
			else
				cNormalGetButton 	: Show()
				cNormalGetButton 	: SetEvent("Clicked", string.format( "XiariZhanling_PrizeClickedNew(%d, %d)", nShowLevel, 0 ))		
			end

			if 1 == bRetRMB and 1 == bGetedRMB then
				cRMBGetedMark01 	: Show()						
				cRMBGetedMark02 	: Show()	
				cRMBGetButtonFinish	: Show()						
			else
				cRMBGetButton 		: Show()
				cRMBGetButton 		: SetEvent("Clicked", string.format( "XiariZhanling_PrizeClickedNew(%d, %d)", nShowLevel, 1 ))
			end
		end

		-- 高级战令未解锁 统一置灰
		if 1 ~= g_bIsActRMBReward then
			cRMBGetedMark01 		: Hide()	
			cRMBGetedMark02 		: Hide()	
			cRMBGetButtonFinish 	: Hide()
			cRMBGetButton 			: Hide()

			cRMBLockImg01 			: Show()
			cRMBLockImg02 			: Show()
			cRMBGetButtonLock 		: Show()

			cRMBGetButtonLock 		: SetToolTip( "#{XRZL_250508_96}")
		end

	end

	XiariZhanling_IconList : SetScrollPosition(g_Position_Scroll)

	-- 根据页计算显示等级
	-- for i = 1, g_nShowNumPerPage do
	-- 	local nShowLevel = (g_nCurShowPage - 1) * 6 + i

	-- 	g_cLevelShowText[i]			: SetText( "" )

	-- 	g_cNormalActionButton[i] 	: SetActionItem(-1)
	-- 	g_cRMBActionButton[i] 		: SetActionItem(-1)
	-- 	g_cNormalLockImg[i]			: Hide()
	-- 	g_cRMBLockImg[i]			: Hide()
	-- 	g_cNormalTips[i]			: Hide()
	-- 	g_cRMBTips[i]				: Hide()
	-- 	g_cNormalGetedMark[i]		: Hide()
	-- 	g_cRMBGetedMark[i]			: Hide()

	-- 	if nShowLevel <= g_nLimitZhanJieNew then
	-- 		local bRet, 		
	-- 			nNeedPoint,
	-- 			nRecordNum,
	-- 			nNeedBagSpaceNormal,
	-- 			nNeedMaterialSpaceNormal,
	-- 			nRewardItemIDNormal,
	-- 			nRewardItemShowIDNormal,
	-- 			nRewardItemNumNormal,
	-- 			bRewardItemBindNormal,
	-- 			nNeedBagSpaceRMB,
	-- 			nNeedMaterialSpaceRMB,
	-- 			nRewardItemIDRMB,
	-- 			nRewardItemShowIDRMB,
	-- 			nRewardItemNumRMB,
	-- 			bRewardItemBindRMB = GetSummerZhanLingPrizeInfo(nShowLevel)
	-- 		if 1 == bRet then

	-- 			g_cLevelShowText[i]	: SetText( ScriptGlobal_Format("#{XRZL_250508_32}", nShowLevel ) )

	-- 			-- ActionButton
	-- 			local theAction1 = DataPool:CreateActionItemForShow(nRewardItemShowIDNormal, 1)
	-- 			if 0 ~= theAction1:GetID() then
	-- 				g_cNormalActionButton[i] : SetActionItem(theAction1:GetID())
	-- 			end
	-- 			local theAction2 = DataPool:CreateActionItemForShow(nRewardItemShowIDRMB, 1)
	-- 			if 0 ~= theAction2:GetID() then
	-- 				g_cRMBActionButton[i] : SetActionItem(theAction2:GetID())
	-- 			end

	-- 			-- 是否未解锁
	-- 			if nCurLevel < nShowLevel then
	-- 				g_cNormalLockImg[i]	: Show()
	-- 				g_cRMBLockImg[i] : Show()
	-- 			else
	-- 				-- 是否领取
	-- 				-- nIndex 从0开始
	-- 				local bRetNormal, bGetedNormal = GetBitValueInUINT(g_nRewardMDNormal, nShowLevel -1, 1)
	-- 				local bRetRMB, bGetedRMB = GetBitValueInUINT(g_nRewardMDRMB, nShowLevel -1, 1)
	-- 				if 1 == bRetNormal and 1 == bGetedNormal then
	-- 					g_cNormalGetedMark[i] : Show()						
	-- 				else
	-- 					g_cNormalTips[i] : Show()
	-- 				end

	-- 				if 1 == bRetRMB and 1 == bGetedRMB then
	-- 					g_cRMBGetedMark[i] : Show()						
	-- 				else
	-- 					g_cRMBTips[i] : Show()
	-- 				end
	-- 			end

	-- 			-- 高级战令未解锁 统一置灰
	-- 			if 1 ~= g_bIsActRMBReward then
	-- 				g_cRMBGetedMark[i] : Hide()	
	-- 				g_cRMBTips[i] : Hide()
	-- 				g_cRMBLockImg[i] : Show()
	-- 			end
	-- 		end
	-- 	end
	-- end

	-- XiariZhanling_Up_LeftArrow_Tips : Hide()
	-- XiariZhanling_Up_RightArrow_Tips : Hide()

	-- -- 计算左翻页奖励红点
	-- if g_nCurShowPage > 1 then
	-- 	local bShowTips = 0
	-- 	for i = 1, g_nCurShowPage - 1 do
	-- 		if 1 == XiariZhanling_IsHaveUnGetedRewardOfPage(i) then
	-- 			bShowTips = 1
	-- 		end
	-- 	end

	-- 	if 1 == bShowTips then
	-- 		XiariZhanling_Up_LeftArrow_Tips : Show()
	-- 	end
	-- end

	-- local nMaxPage = math.floor( (g_nLimitZhanJieNew - 1 ) / g_nShowNumPerPage) + 1

	-- -- 计算右翻页奖励红点
	-- if g_nCurShowPage < nMaxPage then
	-- 	local bShowTips = 0
	-- 	for i = g_nCurShowPage + 1, nMaxPage do
	-- 		if 1 == XiariZhanling_IsHaveUnGetedRewardOfPage(i) then
	-- 			bShowTips = 1
	-- 		end
	-- 	end

	-- 	if 1 == bShowTips then
	-- 		XiariZhanling_Up_RightArrow_Tips : Show()
	-- 	end
	-- end

	-- 外观展示
	for i = 1, table.getn(g_tWaiGuanInfo) do
		local tSubInfo = g_tWaiGuanInfo[i]
		local nState = g_tWaiGuaiBuyState[i]

		-- ActionButton
		local theAction1 = DataPool:CreateActionItemForShow(tSubInfo.nItemID, 1)
		if 0 ~= theAction1:GetID() then
			g_cWaiGuanActionButton[i] : SetActionItem(theAction1:GetID())
		else
			g_cWaiGuanActionButton[i] : SetActionItem(-1)
		end

		-- 消耗元宝
		g_cWaiGuanCostYBText[i] : SetText( ScriptGlobal_Format("#{XRZL_250508_57}", tSubInfo.nCostYB) )
		g_cWaiGuanCostYBDaZheText[i] 	: SetText( ScriptGlobal_Format("#{XRZL_250508_100}", tSubInfo.nCostYBDaZhe) )

		-- 解锁信息
		-- 外观购买状态 0 未购买 1 已购买 -1 未到可购买时间 -2 不可购买了

		g_cWaiGuanBuyButton[i]  	: Hide()
		g_cWaiGuanBuyButton[i]  	: Disable()
		g_cWaiGuanUnLockText[i] 	: Hide()
		g_cWaiGuanGeted[i]  		: Hide()	

		if -2 == nState then
			g_cWaiGuanBuyButton[i]  : Show()	
		end

		if -1 == nState then
			g_cWaiGuanUnLockText[i] : Show()
			g_cWaiGuanUnLockText[i] : SetText( tSubInfo.nUnLoskMsg )			
		end

		if 0 == nState then
			g_cWaiGuanBuyButton[i]  : Show()
			g_cWaiGuanBuyButton[i]  : Enable()
		end

		if 1 == nState then
			g_cWaiGuanGeted[i]  	: Show()
		end

	end

	-- -- 最后一个高级战令时装特写
	-- if 1 == g_bIsActRMBReward then
	-- 	XiariZhanling_Down_Item4_Text2 : Hide()
	-- else
	-- 	XiariZhanling_Down_Item4_Text2 : Show()
	-- 	g_cWaiGuanBuyButton[table.getn(g_tWaiGuanInfo)] : Hide()
	-- end
end

--=========================================================
-- 清空list
--=========================================================
function XiariZhanling_ClearRewardList()
	for i = 1, table.getn(g_cListActionButton) do 
		if g_cListActionButton[i] ~= nil then
			g_cListActionButton[i] : SetActionItem(-1)
			g_cListActionButton[i] = nil
		end
	end
	XiariZhanling_IconList : Clear()	
end

-- --=========================================================
-- -- 切换左轮播图
-- --=========================================================
-- function XiariZhanling_Left()	
-- 	-- if g_nCurShowImageIndex <= 1 then
-- 	-- 	return
-- 	-- end

-- 	XiariZhanling_OnSwitchImage()
-- end

-- --=========================================================
-- -- 切换右轮播图
-- --=========================================================
-- function XiariZhanling_Right()	
-- 	-- if g_nCurShowImageIndex >= table.getn(g_tShowImageInfo) then
-- 	-- 	return
-- 	-- end

-- 	XiariZhanling_OnSwitchImage()
-- end

-- --=========================================================
-- -- 切换轮播图
-- --=========================================================
-- function XiariZhanling_OnSwitchImage()	
-- 	-- g_nCurShowImageIndex = g_nCurShowImageIndex + 1
-- 	-- if g_nCurShowImageIndex > table.getn(g_tShowImageInfo) then
-- 	-- 	g_nCurShowImageIndex = 1
-- 	-- end

-- 	if 1 == g_nCurShowImageIndex then
-- 		g_nCurShowImageIndex = 2
-- 	else
-- 		g_nCurShowImageIndex = 1
-- 	end

-- 	local strImage = g_tShowImageInfo[g_nCurShowImageIndex]

-- 	if nil ~= strImage then		
-- 		XiariZhanling_PageBK_Left : SetProperty( "Image", strImage )
-- 	end

-- 	if 1 == g_nCurShowImageIndex then
-- 		XiariZhanling_Image_ItemPreview 	: Show()
-- 		XiariZhanling_Image_ItemPreview2 	: Hide()
-- 	else
-- 		XiariZhanling_Image_ItemPreview 	: Hide()
-- 		XiariZhanling_Image_ItemPreview2 	: Show()
-- 	end

-- 	KillTimer("XiariZhanling_OnTimerEnd()");	
-- 	SetTimer("XiariZhanling","XiariZhanling_OnTimerEnd()", g_nImageTimerCD)
-- end

-- --=========================================================
-- -- 计时器
-- --=========================================================
-- function XiariZhanling_OnTimerEnd()	
-- 	XiariZhanling_OnSwitchImage()
-- end

--=========================================================
-- 问号
--=========================================================
function XiariZhanling_OnShowHelp()

	-- 1 请求打开购买经验界面
	-- 2 请求解锁高级战令
	-- 3 请求领奖
	-- 4 请求购买外观 1-4
	-- 5 请求购买点数
	-- 6 问号
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUIEvent") 
		Set_XSCRIPT_ScriptID(g_nMainScriptID)
		Set_XSCRIPT_Parameter(0,6)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_Parameter(3,0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 请求打开购买经验界面
--=========================================================
function XiariZhanling_OnAskOpenBuyExpUI()

	-- 1 请求打开购买经验界面
	-- 2 请求解锁高级战令
	-- 3 请求领奖
	-- 4 请求购买外观 1-4
	-- 5 请求购买点数
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUIEvent") 
		Set_XSCRIPT_ScriptID(g_nMainScriptID)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_Parameter(3,0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 请求解锁高级战令
--=========================================================
function XiariZhanling_OnAskActRMBReward()

	-- 1 请求打开购买经验界面
	-- 2 请求解锁高级战令
	-- 3 请求领奖
	-- 4 请求购买外观 1-4
	-- 5 请求购买点数
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUIEvent") 
		Set_XSCRIPT_ScriptID(g_nMainScriptID)
		Set_XSCRIPT_Parameter(0,2)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_Parameter(3,0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 请求领奖new nZhanJie 战阶 bRMBReward 是否是人民币奖励
--=========================================================
function XiariZhanling_PrizeClickedNew(nZhanJie, bRMBReward)

	-- PushDebugMessage("XiariZhanling_PrizeClicked nShowIndex"..nShowIndex.."nZhanJie"..nZhanJie.."bRMBReward"..bRMBReward)

	-- 1 请求打开购买经验界面
	-- 2 请求解锁高级战令
	-- 3 请求领奖
	-- 4 请求购买外观 1-4
	-- 5 请求购买点数
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUIEvent") 
		Set_XSCRIPT_ScriptID(g_nMainScriptID)
		Set_XSCRIPT_Parameter(0,3)
		Set_XSCRIPT_Parameter(1,nZhanJie)
		Set_XSCRIPT_Parameter(2,bRMBReward)
		Set_XSCRIPT_Parameter(3,0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

-- --=========================================================
-- -- 请求领奖 1-6 普通 7-12 人民币
-- --=========================================================
-- function XiariZhanling_PrizeClicked(nShowIndex)

-- 	local bRMBReward = 0
-- 	if nShowIndex > g_nShowNumPerPage then
-- 		bRMBReward = 1
-- 		nShowIndex = nShowIndex - g_nShowNumPerPage
-- 	end

-- 	local nZhanJie = (g_nCurShowPage - 1) * 6 + nShowIndex

-- 	-- PushDebugMessage("XiariZhanling_PrizeClicked nShowIndex"..nShowIndex.."nZhanJie"..nZhanJie.."bRMBReward"..bRMBReward)

-- 	-- 1 请求打开购买经验界面
-- 	-- 2 请求解锁高级战令
-- 	-- 3 请求领奖
-- 	-- 4 请求购买外观 1-4
-- 	-- 5 请求购买点数
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("OnUIEvent") 
-- 		Set_XSCRIPT_ScriptID(g_nMainScriptID)
-- 		Set_XSCRIPT_Parameter(0,3)
-- 		Set_XSCRIPT_Parameter(1,nZhanJie)
-- 		Set_XSCRIPT_Parameter(2,bRMBReward)
-- 		Set_XSCRIPT_Parameter(3,0)
-- 		Set_XSCRIPT_ParamCount(4)
-- 	Send_XSCRIPT()
-- end

--=========================================================
-- 请求购买外观 1-4
--=========================================================
function XiariZhanling_Down_Click(nIndex)

	-- 1 请求打开购买经验界面
	-- 2 请求解锁高级战令
	-- 3 请求领奖
	-- 4 请求购买外观 1-4
	-- 5 请求购买点数
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUIEvent") 
		Set_XSCRIPT_ScriptID(g_nMainScriptID)
		Set_XSCRIPT_Parameter(0,4)
		Set_XSCRIPT_Parameter(1,nIndex)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_Parameter(3,0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 请求预览外观 1-4
--=========================================================
function XiariZhanling_Down_ItemPreview(nIndex)

	local tSubInfo = g_tWaiGuanShowInfo[nIndex]

	if nil == tSubInfo then
		return
	end

	PushEvent("OPEN_DRESSPREVIEW", tSubInfo.nShowDressId, tSubInfo.nShowHairId, tSubInfo.nShowFaceId) 

	-- local nExteriorRideId = Exterior:LuaFnGetExteriorIdByItem(nItemTableIndex)
	-- PushEvent("OPEN_RIDE_PREVIEW", nExteriorRideId)
end

-- --=========================================================
-- -- 左翻页
-- --=========================================================
-- function XiariZhanling_Up_Page_Left()
-- 	if g_nCurShowPage > 1 then
-- 		g_nCurShowPage = g_nCurShowPage - 1
-- 		XiariZhanling_Update(0)
-- 	end
-- end

-- --=========================================================
-- -- 右翻页
-- --=========================================================
-- function XiariZhanling_Up_Page_Right()
-- 	local nMaxPage = math.floor( (g_nLimitZhanJieNew - 1 ) / g_nShowNumPerPage) + 1
-- 	if g_nCurShowPage < nMaxPage then
-- 		g_nCurShowPage = g_nCurShowPage + 1
-- 		XiariZhanling_Update(0)
-- 	end
-- end

--=========================================================
-- 计算第x页是否有未领取奖励
--=========================================================
function XiariZhanling_IsHaveUnGetedRewardOfPage(nPageIndex)
	local nCurLevel, nCurLevelHaveExp, nCurLevelTotalExp, bMaxLevel = XiariZhanling_GetCurLevelAndExpInfo()
	local bHave = 0
	for i = 1, g_nShowNumPerPage do
		local nShowLevel = (nPageIndex - 1 ) * 6 + i
		if nShowLevel <= g_nLimitZhanJieNew then
			-- local bRet, 
			-- 	nNeedPoint,
			-- 	nRecordNum,
			-- 	nNeedBagSpaceNormal,
			-- 	nNeedMaterialSpaceNormal,
			-- 	nRewardItemIDNormal,
			-- 	nRewardItemShowIDNormal,
			-- 	nRewardItemNumNormal,
			-- 	bRewardItemBindNormal,
			-- 	nNeedBagSpaceRMB,
			-- 	nNeedMaterialSpaceRMB,
			-- 	nRewardItemIDRMB,
			-- 	nRewardItemShowIDRMB,
			-- 	nRewardItemNumRMB,
			-- 	bRewardItemBindRMB = GetSummerZhanLingPrizeInfo(nShowLevel)
			if nCurLevel >= nShowLevel then
				local bRetNormal, bGetedNormal = GetBitValueInUINT(g_nRewardMDNormal, nShowLevel -1, 1)
				local bRetRMB, bGetedRMB = GetBitValueInUINT(g_nRewardMDRMB, nShowLevel -1, 1)
				if 1 == bRetNormal and 0 == bGetedNormal then
					bHave = 1
				end

				if 1 == bRetRMB and 0 == bGetedRMB and 1 == g_bIsActRMBReward then
					bHave = 1
				end
			end
		end
	end

	return bHave
end

--=========================================================
-- 计算当前的战阶和点数信息
--=========================================================
function XiariZhanling_GetCurLevelAndExpInfo()
	
	for i = 1, g_nLimitZhanJieNew do
		local bRet, nNeedPoint = GetSummerZhanLingPrizeInfo(i)
		if 1 ~= bRet then 
			return 0, 0, 0, 9
		end 

		-- 未满级
		if g_nPointTotal < nNeedPoint then
			-- 返回 当前战令等级 当前经验点数 当前等级最大的经验
			local nLastLevelPoint = 0
			if i > 1 then
				local bRet2, nNeedPoint2 = GetSummerZhanLingPrizeInfo(i - 1)
				if 1 == bRet2 then
					nLastLevelPoint = nNeedPoint2
				end
			end
			local nCurLevelTotalExp = nNeedPoint - nLastLevelPoint
			local nCurLevelHaveExp = g_nPointTotal - nLastLevelPoint
			return i - 1, nCurLevelHaveExp, nCurLevelTotalExp, 0
		end

		-- 满级情况
		if i == g_nLimitZhanJieNew and g_nPointTotal >= nNeedPoint then
			return g_nLimitZhanJieNew, 0, 0, 1
		end
	end

	return 0, 0, 0, 0
end

--=========================================================
-- 重置界面
--=========================================================
function XiariZhanling_Reset()
	-- g_nCurShowPage = 0
	g_Position_Scroll = 0
	XiariZhanling_ClearRewardList()
end

--=========================================================
-- 关闭界面
--=========================================================
function XiariZhanling_OnClose()	
	this:Hide()
	StopCareObject_XiariZhanling()
	-- 重置
	XiariZhanling_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="XiariZhanling_OnHidden()," />
--=========================================================
function XiariZhanling_OnHidden()
	StopCareObject_XiariZhanling()
	-- 重置
	XiariZhanling_Reset()

	-- 关掉关联界面
	if IsWindowShow("XiariZhanling_GouMai") then
		CloseWindow("XiariZhanling_GouMai", true);
	end
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_XiariZhanling()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "XiariZhanling")
end

function StopCareObject_XiariZhanling()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "XiariZhanling")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function XiariZhanling_MoneyUpdate()
	-- XiariZhanling_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- XiariZhanling_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function XiariZhanling_YuanBaoUpdate()
	-- XiariZhanling_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function XiariZhanling_Frame_On_ResetPos()
	XiariZhanling_Frame:SetProperty("UnifiedPosition", g_XiariZhanling_Frame_UnifiedPosition)
end