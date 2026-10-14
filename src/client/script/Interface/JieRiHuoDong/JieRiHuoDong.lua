-- 节日活动整合界面
-- Author: lishilong 2017-7-5

--=========================================================
-- 常量定义
--=========================================================
local g_MAX_FOR_TIMES			= 500		-- 最大for循环次数，活动配表也不可以长过这个数值
local g_Type_NPC				= 1			-- 找NPC兑换开启类型的活动
local g_MAX_BUTTON_NUM			= 10		-- 最大按钮控件数量
--=========================================================
-- 全局变量
--=========================================================
local g_JieRiHuoDong_Frame_UnifiedPosition
local g_nItemNum = 0
local g_nCurSelected = 1
local g_tabButtonControl 	= {}			-- 活动button的控件
local g_tabHotControl 		= {}			-- 活动红点的控件
local g_CurDayBak			= 0				-- 备用当天时间，客户端在未同步服务器之前使用

local g_TableJieRiInfo = {}

-- 特殊的节日活动信息，默认情况下不显示，只有收到对应 UICommand 时才会添加到末尾显示
local g_TableSpecialInfo = {
	[50509802] = { show = "no" },
	[33901501] = { show = "no" }
}

function JieRiHuoDong_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	--this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("JIERIHUODONG_OPEN")		-- 节日活动界面打开
	this:RegisterEvent("JIERIHUODONG_HOT")		-- 节日活动红点设置消息
end

function JieRiHuoDong_OnLoad()
    g_JieRiHuoDong_Frame_UnifiedPosition = JieRiHuoDong_Frame:GetProperty("UnifiedPosition")
	
	-- 控件
	g_tabButtonControl[1] = JieRiHuoDong_Button1
	g_tabButtonControl[2] = JieRiHuoDong_Button2
	g_tabButtonControl[3] = JieRiHuoDong_Button3
	g_tabButtonControl[4] = JieRiHuoDong_Button4
	g_tabButtonControl[5] = JieRiHuoDong_Button5
	g_tabButtonControl[6] = JieRiHuoDong_Button6
	g_tabButtonControl[7] = JieRiHuoDong_Button7
	g_tabButtonControl[8] = JieRiHuoDong_Button8
	g_tabButtonControl[9] = JieRiHuoDong_Button9
	g_tabButtonControl[10] = JieRiHuoDong_Button10
	
	g_tabHotControl[1] = JieRiHuoDong_Button1tips
	g_tabHotControl[2] = JieRiHuoDong_Button2tips
	g_tabHotControl[3] = JieRiHuoDong_Button3tips
	g_tabHotControl[4] = JieRiHuoDong_Button4tips
	g_tabHotControl[5] = JieRiHuoDong_Button5tips
	g_tabHotControl[6] = JieRiHuoDong_Button6tips
	g_tabHotControl[7] = JieRiHuoDong_Button7tips
	g_tabHotControl[8] = JieRiHuoDong_Button8tips
	g_tabHotControl[9] = JieRiHuoDong_Button9tips
	g_tabHotControl[10] = JieRiHuoDong_Button10tips
end

function JieRiHuoDong_OnEvent(event)
    if ( event == "JIERIHUODONG_OPEN" )then
		JieRiHuoDong_OnShow() 
	elseif ( event == "SCENE_TRANSED" ) then 
		JieRiHuoDong_OnClosed()
		-- 用于刷新是否显示快捷入口
		JieRiHuoDong_Init()
		
	elseif (event == "ADJEST_UI_POS" ) then
		JieRiHuoDong_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JieRiHuoDong_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 920170711) then 
		-- 延后的初始化 以及服务器主动要求重新初始化
		--PushDebugMessage("延后的初始化")

		-- 先把g_TableSpecialInfo中的信息重新初始化
		for i, _ in g_TableSpecialInfo do
			g_TableSpecialInfo[i] = { show = "no" }
		end

		g_CurDayBak = Get_XParam_INT(0)
		JieRiHuoDong_Init()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 2022072902) then 
		local type = Get_XParam_INT(0)
		if g_QixiTuanben_FBtype == 0 then
			PushDebugMessage("#{QXTB_220610_08}")
			AutoRuntoTargetExWithName(308, 244, 0, "穆小妹")
		else
			PushDebugMessage("#{QXTB_220610_09}")
			AutoRuntoTargetExWithName(308, 258, 0, "高阳")
		end		
	elseif ( event == "UI_COMMAND" ) then

		local nUICommandID = Get_XParam_INT(0)
		local bIsShow = Get_XParam_INT(1)
		-- PushDebugMessage("nUICommandID"..nUICommandID.."bIsShow"..bIsShow)

		-- 把特殊的节日信息转移到 g_TableJieRiInfo 中
		if g_TableSpecialInfo[nUICommandID] ~= nil then
			local shouldAdd = 1
			local j = g_nItemNum
			while j > 0 do
				if g_TableJieRiInfo[j].nUICommandID == nUICommandID then
					shouldAdd = 0
					break
				end
				j = j - 1
			end
			if shouldAdd == 1 then
				-- PushDebugMessage("nUICommandID:"..nUICommandID.." Add")
				g_nItemNum = g_nItemNum + 1
				g_TableJieRiInfo[g_nItemNum] = g_TableSpecialInfo[nUICommandID]
				g_TableSpecialInfo[nUICommandID].show = "yes"
			end
		end

		-- 红点设置
		if 0 == g_nItemNum then
			return
		end

		for i = 1, g_nItemNum do
			if tonumber( arg0 ) == tonumber(g_TableJieRiInfo[i].nUICommandID) then
				if nUICommandID == g_TableJieRiInfo[i].nUICommandID then
					g_TableJieRiInfo[i].bHot = bIsShow
				end
				--刷新
				if this:IsVisible() then
					JieRiHuoDong_Update()
				else
					JieRiHuoDong_UpdateQuickEnter()
				end
			end
		end
	end
end

function JieRiHuoDong_OnShow()
	JieRiHuoDong_Init()
	if 0 == g_nItemNum then
		return
	end
	
	this:Show()
	
	JieRiHuoDong_ButtonClick(1)
end

function JieRiHuoDong_Update()
	
	if g_nItemNum <= 0 then
		JieRiHuoDong_OnClosed()
		return
	end
	
	-- 左侧的按钮
	for i = 1, g_MAX_BUTTON_NUM do
		if i > g_nItemNum then
			-- 无数据控件
			g_tabButtonControl[i] : Hide()
			g_tabHotControl[i] : Hide()
		else
			-- 有数据控件
			g_tabButtonControl[i] : SetText(g_TableJieRiInfo[i].strName)
			g_tabButtonControl[i] : Show()
			
			-- 红点
			if 0 == g_TableJieRiInfo[i].bHot then
				g_tabHotControl[i] : Hide()
			else
				g_tabHotControl[i] : Show()
			end
			
			-- 选中
			if g_nCurSelected == i then
				g_tabButtonControl[i] : SetProperty("Selected", "True")
			else
				g_tabButtonControl[i] : SetProperty("Selected", "False")
			end
			
		end
	end
	-- 右侧的内容栏
	if g_nCurSelected < 1 or g_nCurSelected > g_nItemNum then
		return
	end
	
	-- 活动描述
	JieRiHuoDong_ExplainText : SetText(g_TableJieRiInfo[g_nCurSelected].strDes)
	-- 活动图片
	JieRiHuoDong_ImageBk : SetProperty("Image", g_TableJieRiInfo[g_nCurSelected].strPic )
	-- 奖励道具
	if g_TableJieRiInfo[g_nCurSelected].nRewardID1 > 0 then 
		local theAction = DataPool:CreateActionItemForShow(g_TableJieRiInfo[g_nCurSelected].nRewardID1, 1)
		JieRiHuoDong_Item1 : SetActionItem(theAction:GetID())
	else
		JieRiHuoDong_Item1 : SetActionItem(-1)
	end
	
	if g_TableJieRiInfo[g_nCurSelected].nRewardID2 > 0 then 
		local theAction = DataPool:CreateActionItemForShow(g_TableJieRiInfo[g_nCurSelected].nRewardID2, 1)
		JieRiHuoDong_Item2 : SetActionItem(theAction:GetID())
	else
		JieRiHuoDong_Item2 : SetActionItem(-1)
	end
	
	if g_TableJieRiInfo[g_nCurSelected].nRewardID3 > 0 then 
		local theAction = DataPool:CreateActionItemForShow(g_TableJieRiInfo[g_nCurSelected].nRewardID3, 1)
		JieRiHuoDong_Item3 : SetActionItem(theAction:GetID())
	else
		JieRiHuoDong_Item3 : SetActionItem(-1)
	end
	
	if g_TableJieRiInfo[g_nCurSelected].nRewardID4 > 0 then 
		local theAction = DataPool:CreateActionItemForShow(g_TableJieRiInfo[g_nCurSelected].nRewardID4, 1)
		JieRiHuoDong_Item4 : SetActionItem(theAction:GetID())
	else
		JieRiHuoDong_Item4 : SetActionItem(-1)
	end
	
	if g_TableJieRiInfo[g_nCurSelected].nRewardID5 > 0 then 
		local theAction = DataPool:CreateActionItemForShow(g_TableJieRiInfo[g_nCurSelected].nRewardID5, 1)
		JieRiHuoDong_Item5 : SetActionItem(theAction:GetID())
	else
		JieRiHuoDong_Item5 : SetActionItem(-1)
	end
	--新月卡服
	if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 99929801 then
		JieRiHuoDong_FaceAuth_SpecialContent()
	end
	-- 刷新快捷入口
	JieRiHuoDong_UpdateQuickEnter()
end

-- 点击左侧活动按钮
function JieRiHuoDong_ButtonClick(nIndex)
	if nIndex < 1 or nIndex > g_nItemNum then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AddYongYanLog" )
		Set_XSCRIPT_ScriptID( 892473)
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
			
	-- 设置当前选择按钮
	g_nCurSelected = nIndex
	
	-- 发送红点状态请求
	if g_TableJieRiInfo[g_nCurSelected].nScriptID > 0 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetTheHotPoint" )
		Set_XSCRIPT_ScriptID( 892463 )
		Set_XSCRIPT_Parameter( 0, 1 )
		Set_XSCRIPT_Parameter( 1, g_TableJieRiInfo[g_nCurSelected].nUICommandID )
		Set_XSCRIPT_Parameter( 2, g_TableJieRiInfo[g_nCurSelected].nScriptID )
		Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	end
	
	--刷新
	JieRiHuoDong_Update()	
end

-- 点击参与活动
function JieRiHuoDong_ActClick(nIndex)
	if g_nCurSelected < 1 or g_nCurSelected > g_nItemNum then 
		-- 非法参数
		PushDebugMessage("非法参数")
		return
	end
	
	if g_TableJieRiInfo[g_nCurSelected].nLevel > Player:GetLevel() then
		-- 等级不够
		local strMsg = ScriptGlobal_Format("#{JRHD_170705_04}", 
			g_TableJieRiInfo[g_nCurSelected].nLevel)
		PushDebugMessage(strMsg)
		return
	end
	
	if 1 ~= g_TableJieRiInfo[g_nCurSelected].nType 
		or g_TableJieRiInfo[g_nCurSelected].nIsGo < 1
		or g_TableJieRiInfo[g_nCurSelected].nGoSceneID < -1 
		or g_TableJieRiInfo[g_nCurSelected].nGoFx < 0 
		or g_TableJieRiInfo[g_nCurSelected].nGoFy < 0 then
		-- 无法寻路
		
		--STM门派罗盘特写
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 810210191 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			local nServerTime = tonumber(DataPool:GetServerMinuteTime())
			if (nServerDay == g_TableJieRiInfo[g_nCurSelected].nDayStart and nServerTime < 110000) or nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{MPPFW_181019_7}")--当前不在活动时间内，无法打开该界面。
				return
			else
				PushDebugMessage(g_TableJieRiInfo[g_nCurSelected].strNoGoMsg)
				return
			end
		end
	
		--青春纪念馆活动特写
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 89321301 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			local nServerTime = tonumber(DataPool:GetServerMinuteTime())
			if (nServerDay == g_TableJieRiInfo[g_nCurSelected].nDayStart and nServerTime < 120000) or nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{QCJN_190809_8}")--当前不在活动时间内，无法打开该界面。
				return
			end
		end

		-- 2020Q2鹊桥剧场活动特写
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 88810801 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			local nServerTime = tonumber(DataPool:GetServerMinuteTime())
			if (nServerDay == g_TableJieRiInfo[g_nCurSelected].nDayStart and nServerTime < 110000) or nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{QQJC_200710_13}") --当前不是活动时间，无法参与该活动。
				return
			end
		end
		
		-- 2020重阳签到活动特写
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 88808801 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			local nServerTime = tonumber(DataPool:GetServerMinuteTime())
			if (nServerDay == g_TableJieRiInfo[g_nCurSelected].nDayStart and nServerTime < 100000) or nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{CYWX_200907_1}")
				return
			end
		end
	
		-- 斗茶活动时间检查（其实不光是这个活动，多数活动都需要进行检查，以防“跨天时界面开着”导致“活动结束了还会提示strNoGoMsg”。所以这个时间检查最好做成所有活动统一的。）
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 20200615 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			if nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{DCWF_200615_04}") --#H当前不在活动时间内，无法查看此活动。
				return
			end
		end

		-- 嘉年华直播特写
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 89324101 then
			local day = tonumber(DataPool:GetServerDayTime())
			if day == 20251017 or day == 20251018 then
				PushDebugMessage("#{XCCJ_201014_33}")
			else
				PushDebugMessage("#{XCCJ_190829_09}")
			end
			return
		end

		-- 2020胡军酒馆寻人活动特写
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 88808802 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			local nServerTime = tonumber(DataPool:GetServerMinuteTime())
			if (nServerDay == g_TableJieRiInfo[g_nCurSelected].nDayStart and nServerTime < 100000) or nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{HJJGXR_201022_01}")--#H当前不在活动时间内，无法参与活动。
				return
			end
		end
		
		-- 卡级服门派第一人
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 61002301 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			if nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{KJMPZP_210823_01}") --#H当前不在活动时间内，无法查看此活动。
				return
			end
		end

		-- 2021Q3从刃第一人活动特写
		-- add: 卡级服宋辽大战奖励升级活动时间检查
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 88876201 or g_TableJieRiInfo[g_nCurSelected].nUICommandID == 5051001 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			if nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{CRDYR_210824_02}") --当前不是活动时间，无法参与该活动。
				return
			end
		end

		-- 卡级服征讨
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 61002401 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			if nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{KJBHZT_210819_01}") --#H当前不在活动时间内，无法查看此活动。
				return
			end
		end

		-- 全年消费回馈礼包
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 88885201 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			if nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{HKLB_211201_01}") --当前不是活动时间，无法参与该活动。
				return
			end
		end

		-- 2022Q1 市场熊猫预热活动
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 88898401 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			if nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{SCXMYR_220317_06}") --当前不是活动时间，无法参与该活动。
				return
			end
		end

		-- 2022Q3 城战测试直播
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 99813104 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			if nServerDay < g_TableJieRiInfo[g_nCurSelected].nDayStart or nServerDay > g_TableJieRiInfo[g_nCurSelected].nDayEnd then
				PushDebugMessage("#{CZZB_220906_01}") --当前不是活动时间，无法参与该活动。
				return
			end
		end

		-- 2023Q3 七夕直播
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 99884401 then
			local day = tonumber(DataPool:GetServerDayTime())
			if day ~= 20230820 then
				PushDebugMessage("#{QXZB_230810_01}")--当前不是活动时间，无法参与该活动。
				return
			end
		end

		-- 嘉年华福利直播特写
		if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 99885401 then
			local nServerDay = tonumber(DataPool:GetServerDayTime())
			if nServerDay ~= 20231015 then
				PushDebugMessage("#{JNZB_20230828_3}")
				return
			end
		end

		PushDebugMessage(g_TableJieRiInfo[g_nCurSelected].strNoGoMsg)
		
		return
	end

	-- 嘉年华特写
	 if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 89321801 then
        local day = tonumber(DataPool:GetServerDayTime())
        if day < 20250910 or day > 20251009 then
            PushDebugMessage("#{JNHD_190813_01}")
            return
        end
	end
	
	--七夕团本特写
	if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 20220802 then
		local day = tonumber(DataPool:GetServerDayTime())
		if day < 20220817 or day > 20220828 then
			PushDebugMessage("#{QXTB_220610_03}")
			return
		else
			--双本，具体去哪个要问服务器
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("AskFubenType")
				Set_XSCRIPT_ScriptID(800996) 
				Set_XSCRIPT_Parameter( 0, 2022072902 );	
				Set_XSCRIPT_ParamCount(1)		
			Send_XSCRIPT()
		end
	end
	
	-- -- 争霸赛竞猜特写
	-- if g_TableJieRiInfo[g_nCurSelected].nUICommandID == 99884501 then
	-- 	local nServerDay = tonumber(DataPool:GetServerDayTime())
	-- 	local nServerTime = tonumber(DataPool:GetServerMinuteTime())
	-- 	if (nServerDay == 20240907 and nServerTime < 120000) or 
	-- 		nServerDay < 20240907 or nServerDay > 20241019 or
	-- 		(nServerDay == 20241019 and nServerTime > 100000) then
	-- 		PushDebugMessage("#{ZBJC_20230810_2}")
	-- 		return
	-- 	end
	-- end


	-- 自动寻路
	local bRet = AutoRuntoTargetExWithName(g_TableJieRiInfo[g_nCurSelected].nGoFx, g_TableJieRiInfo[g_nCurSelected].nGoFy, g_TableJieRiInfo[g_nCurSelected].nGoSceneID, g_TableJieRiInfo[g_nCurSelected].strGoNPCName)
	
	if 0 == bRet then
		PushDebugMessage("#{JRHD_170720_07}")
	end
end

-- 初始化页面
function JieRiHuoDong_Init()
	
	-- 当前服务器天数
	AskServerTimeAgain()
	--local nServerDayTime = tonumber(DataPool:GetServerDayTime())
	local nServerDayTime = tonumber(DataPool:GetServerDayTime())
	-- 客户端启动时，服务器时间可能还未同步过来，此时需要延后初始化
	if nServerDayTime < 20000000 then
		if g_CurDayBak < 20000000 then
			-- 申请服务器时间
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "GetServerDay" )
				Set_XSCRIPT_ScriptID( 892463 )
				Set_XSCRIPT_ParamCount( 0 )
			Send_XSCRIPT()
			--PushDebugMessage("申请服务器时间")
			return
		else
			nServerDayTime = g_CurDayBak
		end
	end
	
	g_nItemNum = 0
	g_TableJieRiInfo = {}
	for i = 1, g_MAX_FOR_TIMES do
		local bRet, strName, nUICommandID, nLevel, nType, nScriptID, nDayStart, nDayEnd, 
				strDes, nIsGo, strNoGoMsg, nGoSceneID, nGoFx, nGoFy,strGoNPCName, 
				strPic, nRewardID1, nRewardID2, nRewardID3, nRewardID4, nRewardID5 
						= GetJieRiHuoDongInfo(i-1)
		
		if 0 == bRet then
			break
		end 
		--PushDebugMessage("g_nItemNum"..g_nItemNum.."i"..i.."nType"..nType.."nDayStart"..nDayStart.."nServerDayTime"..nServerDayTime.."nDayEnd"..nDayEnd)
		if g_Type_NPC == nType  and tonumber(nDayStart) <= nServerDayTime and tonumber(nDayEnd) >= nServerDayTime then
			if (strName == "大宋真人秀" and JieRiHuoDong_FaceAuth_IsShow() == false) then
			elseif(strName == "火麟惊云" and DataPool:GetSelfZoneWorldID() ~= 5175) then
				continue
			else
				-- NPC类型活动，并且在活动开启时间内
				g_nItemNum = g_nItemNum + 1 
				g_TableJieRiInfo[g_nItemNum] = {}
				g_TableJieRiInfo[g_nItemNum].strName 			= strName
				g_TableJieRiInfo[g_nItemNum].nUICommandID 		= nUICommandID
				g_TableJieRiInfo[g_nItemNum].nLevel 			= nLevel
				g_TableJieRiInfo[g_nItemNum].nType 				= nType
				g_TableJieRiInfo[g_nItemNum].nScriptID 			= nScriptID
				g_TableJieRiInfo[g_nItemNum].nDayStart 			= nDayStart
				g_TableJieRiInfo[g_nItemNum].nDayEnd 			= nDayEnd
				g_TableJieRiInfo[g_nItemNum].strDes 			= strDes
				g_TableJieRiInfo[g_nItemNum].nIsGo				= nIsGo
				g_TableJieRiInfo[g_nItemNum].strNoGoMsg 		= strNoGoMsg
				g_TableJieRiInfo[g_nItemNum].nGoSceneID 		= nGoSceneID
				g_TableJieRiInfo[g_nItemNum].nGoFx 				= nGoFx
				g_TableJieRiInfo[g_nItemNum].nGoFy 				= nGoFy
				g_TableJieRiInfo[g_nItemNum].strGoNPCName 		= strGoNPCName
				g_TableJieRiInfo[g_nItemNum].strPic 			= strPic
				g_TableJieRiInfo[g_nItemNum].nRewardID1 		= nRewardID1
				g_TableJieRiInfo[g_nItemNum].nRewardID2 		= nRewardID2
				g_TableJieRiInfo[g_nItemNum].nRewardID3 		= nRewardID3
				g_TableJieRiInfo[g_nItemNum].nRewardID4 		= nRewardID4
				g_TableJieRiInfo[g_nItemNum].nRewardID5 		= nRewardID5
				g_TableJieRiInfo[g_nItemNum].bHot = 0
				--发送红点状态请求
				if nScriptID > 0 then
					Clear_XSCRIPT()
						Set_XSCRIPT_Function_Name( "GetTheHotPoint" )
						Set_XSCRIPT_ScriptID( 892463 )
						Set_XSCRIPT_Parameter( 0, 0 )
						Set_XSCRIPT_Parameter( 1, nUICommandID )
						Set_XSCRIPT_Parameter( 2, nScriptID )
						Set_XSCRIPT_ParamCount( 3 )
					Send_XSCRIPT()
				end	
				-- 特殊的节日活动信息，转移到 g_TableSpecialInfo 中，不让它显示
				if g_TableSpecialInfo[nUICommandID] ~= nil and g_TableSpecialInfo[nUICommandID].show == "no" then
					g_TableSpecialInfo[nUICommandID] = g_TableJieRiInfo[g_nItemNum]
					g_TableSpecialInfo[nUICommandID].show = "no"
					g_TableJieRiInfo[g_nItemNum] = nil
					g_nItemNum = g_nItemNum - 1
					-- PushDebugMessage("nUICommandID:"..nUICommandID.." Remove")
				end
			end
		end
	end
	
	if g_nCurSelected < 1 or g_nCurSelected > g_nItemNum then
		g_nCurSelected = 1
	end
	
	JieRiHuoDong_Update()
	JieRiHuoDong_UpdateQuickEnter()
end

-- 更新快捷入口是否显示，是否红点
function JieRiHuoDong_UpdateQuickEnter() 
	if 0 == g_nItemNum then 
		--Lua_TDU_Log("Lua_ShowQuickEnter(12,0)");
		Lua_ShowQuickEnter(12,0)
		return
	end
	
	local bHot = 0
	for i = 1, g_nItemNum do
		if 1 == g_TableJieRiInfo[i].bHot then
			bHot = 1
			break
		end
	end  
	Lua_ShowQuickEnter(12,1)
	Lua_ShowQuickEnterPointTip(12,bHot)
end

function JieRiHuoDong_OnClosed()
	g_nItemNum = 0
	this:Hide()
end

function JieRiHuoDong_On_ResetPos()
    JieRiHuoDong_Frame:SetProperty("UnifiedPosition", g_JieRiHuoDong_Frame_UnifiedPosition)
end
function JieRiHuoDong_FaceAuth_IsShow()
	local isNewMonthcardServer = DataPool:LuaFnOpenSocialServer()
	if isNewMonthcardServer == 1 then
			return true
	end
	return false
end
--人脸验证显示内容特判
function JieRiHuoDong_FaceAuth_SpecialContent()
	local isNewMonthcardServer , nStartTime,nEndTime = DataPool:LuaFnGetNewMonthcardDate()
	if isNewMonthcardServer == 1 then
		local nSyear = math.floor (nStartTime / 10000) 
		local nSmonth = math.floor(nStartTime / 100)-math.floor(nStartTime/10000)*100
		local nSday =  nStartTime - math.floor(nStartTime/100)*100
		local nEyear = math.floor (nEndTime / 10000) 
		local nEmonth = math.floor(nEndTime / 100)-math.floor(nEndTime/10000)*100
		local nEday =  nEndTime - math.floor(nEndTime/100)*100
		local msg = ScriptGlobal_Format("#{RLYZ_20240516_60}",nSyear,nSmonth,nSday,nEyear,nEmonth,nEday)
		JieRiHuoDong_ExplainText : SetText(msg)
	end
end