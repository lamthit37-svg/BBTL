-- 2022春节主界面
-- 单页效果
local g_Frame_UnifiedPosition

--活动按钮小红点
local g_ButtonShowList = {}

-- 活动等级限制
local g_LimitLevel = 30

--显隐列表
local g_ButtonShowList = {}
local g_is1stStart = 1		-- 是否启动第一阶段
local g_is2ndStart = 1		-- 是否启动第二阶段
local g_is3rdStart = 1		-- 是否启动第三阶段
local g_is4thStart = 1		-- 是否启动第四阶段

--=========
-- PreLoad
--=========
function SpringFestival3_Guide_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("CLOSE_SPRINGFES_GUIDE", false);

end

--=========
-- OnLoad
--=========
function SpringFestival3_Guide_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival3_Guide_Frame:GetProperty("UnifiedPosition") 

	g_ButtonShowList = 
	{
		[1] = { btn = SpringFestival3_Guide_HuameiBtn, tips = SpringFestival3_Guide_HuameiBtn_Tips, image=nil,  
			starttime = -1, endtime = -1, showtime = -1, nScriptID = -1, nUICommandID = -1, bTipShow = 0, bBtnShow = 0, 
			btntips_unbeg="", btntips_doing="", btntips_end="", }, --未占用
		[2] = { btn = SpringFestival3_Guide_RiliBtn, tips = SpringFestival3_Guide_RiliBtn_Tips, image=nil, 
			starttime = 20260205, endtime = 20260216, showtime = 20260205, nScriptID = 890801, nUICommandID = 89080102, bTipShow = 0, bBtnShow = g_is1stStart, 
			btntips_unbeg="#{LYYJ_181206_68}", btntips_doing="#{LYYJ_181206_67}", btntips_end="#{LYYJ_181206_69}", }, --千秋辞岁
		[3] = { btn = SpringFestival3_Guide_ZhuanpanBtn, tips = SpringFestival3_Guide_ZhuanpanBtn_Tips, image=nil, 
			starttime = 20260205, endtime = 20260215, showtime = 20260205, nScriptID = 890803, nUICommandID = 89080302, bTipShow = 0, bBtnShow = g_is1stStart, 
			btntips_unbeg="#{LYYJ_181206_71}", btntips_doing="#{LYYJ_181206_70}", btntips_end="#{LYYJ_181206_69}", }, --竹爆平安
		[4] = { btn = SpringFestival3_Guide_LicaiBtn, tips = SpringFestival3_Guide_LicaiBtn_Tips, image=nil, 
			starttime = 20260205, endtime = 20260315, showtime = 20260205, nScriptID = 998332, nUICommandID = 99833202, bTipShow = 0, bBtnShow = g_is1stStart, 
			btntips_unbeg="#{RACL_201224_38}", btntips_doing="#{MTNC_221101_1}", btntips_end="#{MTNC_221101_2}", }, --金铢整合活动
		[5] = { btn = SpringFestival3_Guide_WXH5Btn, tips = SpringFestival3_Guide_WXH5Btn_Tips, image=nil, 
			starttime = -1, endtime = -1, showtime = -1, nScriptID = -1, nUICommandID = -1, bTipShow = 0, bBtnShow = 0, 
			btntips_unbeg="", btntips_doing="", btntips_end="", }, --未占用
		[6] = { btn = SpringFestival3_Guide_GiftBtn, tips = SpringFestival3_Guide_GiftBtn_Tips, image=nil, 
			starttime = 20260205, endtime = 20260215, showtime = 20260205, nScriptID = 888328, nUICommandID = 88832802, bTipShow = 0, bBtnShow = g_is1stStart, 
			btntips_unbeg="#{RACL_201224_43}", btntips_doing="#{RACL_201224_13}", btntips_end="#{RACL_201224_40}", }, --春日礼包
		[7] = { btn = SpringFestival3_Guide_ClothBtn, tips = SpringFestival3_Guide_ClothBtn_Tips, image=nil, 
			starttime = 20260205, endtime = 20260318, showtime = 20260205, nScriptID = 998897, nUICommandID = 99889702, bTipShow = 0, bBtnShow = g_is1stStart, 
			btntips_unbeg="#{CJSZ_211124_02}", btntips_doing="#{CJSZ_211124_01}", btntips_end="#{CJSZ_211124_03}", }, --春节时装
		[8] = { btn = SpringFestival3_Guide_YingJingBtn, tips = SpringFestival3_Guide_YingJingBtn_Tips, image=nil, 
			starttime = 20260205, endtime = 20260215, showtime = 20260205, nScriptID = 998965, nUICommandID = 99896502, bTipShow = 0, bBtnShow = g_is1stStart, 
			btntips_unbeg="#{XXJQ_20231130_1}", btntips_doing="#{XXJQ_20231130_4}", btntips_end="#{XXJQ_20231130_5}", }, --春节应景活动
		[9] = { btn = SpringFestival3_Guide_WeaponBtn, tips = SpringFestival3_Guide_WeaponBtn_Tips, image=nil, 
			starttime = 20260224, endtime = 20260315, showtime = 20260224, nScriptID = 888345, nUICommandID = 88834502, bTipShow = 0, bBtnShow = g_is4thStart, 
			btntips_unbeg="#{YHSQ_210105_05}", btntips_doing="#{YHSQ_210105_05}", btntips_end="#{YHSQ_210105_05}", }, --游会赏趣
		[10] = { btn = SpringFestival3_Guide_MiaohuiShopBtn, tips = SpringFestival3_Guide_MiaohuiShopBtn_Tips, image=nil, 
			starttime = 20260224, endtime = 20260318, showtime = 20260224, nScriptID = 890712, nUICommandID = 89071204, bTipShow = 0, bBtnShow = g_is4thStart, 
			btntips_unbeg="#{RACL_201224_38}", btntips_doing="#{MHSD_210104_16}", btntips_end="#{RACL_201224_40}", }, --百戏集市
		[11] = { btn = SpringFestival3_Guide_AuctionBtn, tips = SpringFestival3_Guide_AuctionBtn_Tips, image=nil, 
			starttime = 20260224, endtime = 20260311, showtime = 20260224, nScriptID = 440003, nUICommandID = 44000306, bTipShow = 0, bBtnShow = g_is4thStart, 
			btntips_unbeg="#{CJPM_191126_24}", btntips_doing="#{CJPM_191126_24}", btntips_end="#{CJPM_191126_24}", }, --山海风物赏
		[12] = { btn = SpringFestival3_Guide_HuoyueBtn, tips = SpringFestival3_Guide_HuoyueBtn_Tips, image=nil, 
			starttime = 20260224, endtime = 20260315, showtime = 20260224, nScriptID = 891711, nUICommandID = 89171101, bTipShow = 0, bBtnShow = g_is4thStart, 
			btntips_unbeg="#{QCBF_260105_6}", btntips_doing="#{QCBF_260105_1}", btntips_end="#{QCBF_260105_7}", }, --多人活跃
		[13] = { btn = SpringFestival3_Guide_RiddleBtn, tips = SpringFestival3_Guide_RiddleBtn_Tips, image=nil, 
			starttime = 20260224, endtime = 20260315, showtime = 20260224, nScriptID = 892384, nUICommandID = 89238400, bTipShow = 0, bBtnShow = g_is4thStart, 
			btntips_unbeg="#{YXCDM_210108_02}", btntips_doing="#{YXCDM_210108_01}", btntips_end="#{YXCDM_210108_03}", }, --花灯隐语
		[14] = { btn = SpringFestival3_Guide_PigBtn, tips = SpringFestival3_Guide_PigBtn_Tips, image=nil, 
			starttime = 20260224, endtime = 20260315, showtime = 20260224, nScriptID = 892980, nUICommandID = 89298008, bTipShow = 0, bBtnShow = g_is4thStart, 
			btntips_unbeg="#{KWCQ_201225_09}", btntips_doing="#{KWCQ_201225_05}", btntips_end="#{KWCQ_201225_06}", }, --三仙归位
		[15] = { btn = SpringFestival3_Guide_ShootBtn, tips = SpringFestival3_Guide_ShootBtn_Tips, image=nil, 
			starttime = 20260224, endtime = 20260315, showtime = 20260224, nScriptID = 893021, nUICommandID = 89302126, bTipShow = 0, bBtnShow = g_is4thStart, 
			btntips_unbeg="#{YXSJ_181204_78}", btntips_doing="#{YXSJ_181204_77}", btntips_end="#{YXSJ_181204_79}", }, --神射竞春
	}
	
	--请求所有小红点
	SpringFestival3_Guide_InitRedPoint()

end

--=========
-- 初始化活动小红点
--=========
function SpringFestival3_Guide_InitRedPoint()

	-- 清空小红点
	for i = 1, table.getn(g_ButtonShowList) do
		g_ButtonShowList[i].bTipShow = 0
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateAllRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()

	-- 更新主界面快捷按钮小红点
	SpringFestival3_Guide_UpdateQuickEnter()
	
end

--=========
-- 更新活动小红点
--=========
function SpringFestival3_Guide_UpdateRedPoint()

	--活动小红点
	for i = 1, table.getn(g_ButtonShowList) do
		if g_ButtonShowList[i].tips ~= nil then
			if g_ButtonShowList[i].bTipShow == 1 then
				g_ButtonShowList[i].tips:Show()
			else
				g_ButtonShowList[i].tips:Hide()
			end
		end
	end
	
end

--=========
-- 更新主界面快捷按钮小红点
--=========
function SpringFestival3_Guide_UpdateQuickEnter()

	local bTipShow = 0
	
	for i = 1, table.getn(g_ButtonShowList) do
		if 1 == g_ButtonShowList[i].bTipShow then
			bTipShow = 1
			break
		end
	end
	
	--PushEvent("SPRINGGUIDEMISSION_QUICKENTER", bTipShow)
	Lua_ShowQuickEnterPointTip(15, bTipShow)
end

--=========
-- OnEvent
--=========
function SpringFestival3_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89298502 then

		--SpringFestival3_Guide_InitRedPoint()--请求所有小红点
		local nCount = Get_XParam_INT(0)
		local bUpdate = Get_XParam_INT(1)
		if bUpdate == 1 then
			if this:IsVisible() then
				--显示金珠数量
				SpringFestival3_Guide_UpdateJinzhu(nCount)				
				--显示隐藏按钮
				SpringFestival3_Guide_BtnShowByTime()
			end
		else
			SpringFestival3_Guide_Update(nCount)
		end
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88832801) then	--节日礼包特写
	
		local btnShow = Get_XParam_INT(0)
		if btnShow == 2 then
			g_ButtonShowList[6].btn:Hide()
		end
				
	elseif event == "UI_COMMAND" then
	
		for i = 1, table.getn(g_ButtonShowList) do
			if tonumber( arg0 ) == tonumber(g_ButtonShowList[i].nUICommandID) then
				local nScriptID = Get_XParam_INT(0)
				local bTipShow = Get_XParam_INT(1)
				if tonumber( nScriptID ) ~= nil and tonumber( nScriptID ) > 0 and tonumber( nScriptID ) == tonumber(g_ButtonShowList[i].nScriptID) then
					g_ButtonShowList[i].bTipShow = bTipShow
					--刷新界面
					if this:IsVisible() then
						--更新活动小红点
						SpringFestival3_Guide_UpdateRedPoint()
						--更新主界面快捷按钮小红点
						SpringFestival3_Guide_UpdateQuickEnter()
					else
						--更新主界面快捷按钮小红点
						SpringFestival3_Guide_UpdateQuickEnter()
					end
				end
				--跳出
				break
			end
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival3_Guide_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival3_Guide_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		SpringFestival3_Guide_Close()
		
	elseif (event == "CLOSE_SPRINGFES_GUIDE") then
	
		SpringFestival3_Guide_Close()
		
	end

end

--=========
-- 重置
--=========
function SpringFestival3_Guide_On_ResetPos()

	SpringFestival3_Guide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
--显示金珠数量
--=========
function SpringFestival3_Guide_UpdateJinzhu(nCount)
	SpringFestival_Jinzhu_AccountText:SetText(ScriptGlobal_Format("#{JZZH_211125_47}", nCount))
end

--=========
-- 打开
--=========
function SpringFestival3_Guide_Update(nCount)

	-- 显示
	this:Show()	
	
	--显示金珠数量
	SpringFestival3_Guide_UpdateJinzhu(nCount)
		
	-- 显示隐藏按钮
	SpringFestival3_Guide_BtnShowByTime()

	--更新活动小红点
	SpringFestival3_Guide_UpdateRedPoint()
	--更新主界面快捷按钮小红点
	SpringFestival3_Guide_UpdateQuickEnter()
	
end

--=========
-- 分阶段显示内容
--=========
function SpringFestival3_Guide_BtnShowByTime()

	local listcount = table.getn(g_ButtonShowList)
	for i=1, listcount do
		local item = g_ButtonShowList[i]
		if item ~= nil then
			if item.starttime == -1 or item.endtime == -1 or item.showtime == -1 or item.bBtnShow < 1 then
				item.btn:Hide()
				if item.image ~= nil then
					item.image:Hide()
				end
			else
				local curDay = tonumber(DataPool:GetServerDayTime())
				local curMinute = tonumber(DataPool:GetServerMinuteTime())					
				local curHour = math.floor(curMinute/10000)
				if curDay >= item.showtime and curDay <= item.endtime then
					item.btn:Show()
					if item.image ~= nil then
						item.image:Show()
					end
					--增加按钮tips分时间显示
					if curDay < item.starttime then
						item.btn:SetToolTip(item.btntips_unbeg)
					elseif curDay >= item.starttime and curDay <= item.endtime then
						item.btn:SetToolTip(item.btntips_doing)
					elseif curDay > item.endtime then
						item.btn:SetToolTip(item.btntips_end)
					end					
				else
					item.btn:Hide()
					if item.image ~= nil then
						item.image:Hide()
					end
				end
			end
		end
	end
	
	if Pneuma:GetMF(5326) == 1 then--节日礼包特写
		g_ButtonShowList[6].btn:Hide()
	end

end

function SpringFestival3_Guide_BtnHideByTime()
	local listcount = table.getn(g_ButtonShowList)
	for i=1, listcount do
		local item = g_ButtonShowList[i]
		if item ~= nil then	
			item.btn:Hide()
			if item.image ~= nil then
				item.image:Hide()
			end
		end
	end
end

--=========
-- 是否正确的时间
--=========
function SpringFestival3_Guide_IsRightTime(nIndex)
	-- 判定边界
	local listcount = table.getn(g_ButtonShowList)
	if nIndex < 1 or listcount < nIndex then
		return 0
	end

	-- 判定时间
	local item = g_ButtonShowList[nIndex]
	if item ~= nil then
		-- 默认为无效时间
		if item.starttime == -1 or item.endtime == -1 then
			return 0
		else
			local curDay = tonumber(DataPool:GetServerDayTime())
			if curDay >= item.starttime and curDay <= item.endtime then
				return 1
			elseif curDay > item.endtime then
				return -1
			end

		end
	end

	return 0
end

--=========
-- 关闭
--=========
function SpringFestival3_Guide_Close()

	SpringFestival3_Guide_OnHiden()
	this:Hide()
	
end

--=========
-- 隐藏
--=========
function SpringFestival3_Guide_OnHiden()
end

--=========
-- 更新指定功能小红点
--=========
function SpringFestival3_Guide_UpdateTheRedPoint(callScriptId)
	if callScriptId == nil or callScriptId <= 0 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0, callScriptId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========
-- 点击事件
--=========
function SpringFestival3_Guide_Clicked(clickId)
	local curDay = DataPool:GetServerDayTime()
	
	if clickId == 1 then 	
		--未占用
	elseif clickId == 2 then
		--千秋辞岁
		local isrighttime = SpringFestival3_Guide_IsRightTime(clickId)
		if isrighttime > 0 then
		else
			PushDebugMessage("#{RACL_181206_443}")
			return
		end
		local nLevel = Player:GetLevel()
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{RACL_181206_444}")
			return
		end	
		if(IsWindowShow("SpringFirst_Calender")) then
			CloseWindow("SpringFirst_Calender", true)
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID( 890801 )
			Set_XSCRIPT_Function_Name( "OnOpenLaYueSiRiLiUI" )
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()	
	elseif clickId == 3 then
		--竹爆平安
		local isrighttime = SpringFestival3_Guide_IsRightTime(clickId)
		if isrighttime > 0 then
		else
			PushDebugMessage("#{RACL_181206_443}")
			return
		end
		local nLevel = Player:GetLevel()
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{RACL_181206_444}")
			return
		end

		--打开一个新增界面
		OpenWindow( "SpringFestival_Firecracker" )
		SpringFestival3_Guide_Close()	
	elseif clickId == 4 then
		--金铢整合活动

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskOpenMainUI")
			Set_XSCRIPT_ScriptID(998332)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 5 then
		--未占用
  elseif clickId == 6 then
		--春日礼包
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenUI")
			Set_XSCRIPT_ScriptID(888328)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 7 then
		--2024春节时装获取
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenUI")
			Set_XSCRIPT_ScriptID(998897)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif clickId == 8 then
		--春节应景活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenUI")
			Set_XSCRIPT_ScriptID(998965)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 9 then
		--游会赏趣
		local nLevel = Player:GetLevel()
		if nLevel < 30 then
			PushDebugMessage("#{YHSQ_210105_06}")
			return
		end	
		local isRightTime = SpringFestival3_Guide_IsRightTime(clickId)	
		if isRightTime > 0 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnOpenHuanwu")
				Set_XSCRIPT_ScriptID(888345) 
				Set_XSCRIPT_ParamCount(0)
	    Send_XSCRIPT()
			SpringFestival3_Guide_UpdateTheRedPoint(888345)		
	    SpringFestival3_Guide_Close()
		else
			PushDebugMessage("#{YHSQ_210105_07}")
		end
	elseif clickId == 10 then
		--百戏集市
		local isrighttime = SpringFestival3_Guide_IsRightTime(clickId)
		if isrighttime <= 0 then
			PushDebugMessage("#{RACL_181206_443}")
			return
		end	
		local nLevel = Player:GetLevel()
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{RACL_181206_444}")
			return
		end	
		if(IsWindowShow("YuanXiao_Shop")) then
			CloseWindow("YuanXiao_Shop", true)
			return
		end		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenFairShop" )
			Set_XSCRIPT_ScriptID( 890713 )
			Set_XSCRIPT_Parameter(0, -1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif clickId == 11 then
		--山海风物赏
		local isrighttime = SpringFestival3_Guide_IsRightTime(clickId)
		if isrighttime <= 0 then
			PushDebugMessage("#{CJPM_191126_22}")
			return
		end		
		local nLevel = Player:GetLevel()
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{CJPM_191126_23}")
			return
		end	
	  Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowClientUI")
			Set_XSCRIPT_ScriptID(440003)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	  SpringFestival3_Guide_Close()
	elseif clickId == 12 then
		--多人活跃
		local isrighttime = SpringFestival3_Guide_IsRightTime(clickId)
		if isrighttime <= 0 then
			PushDebugMessage("#{QCBF_260105_3}")
			return
		end
		local nLevel = Player:GetLevel()
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{QCBF_260105_2}")
			return
		end	

		PushEvent("OPEN_YINGJINGACTIVITY2")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateRedPoint" );
			Set_XSCRIPT_ScriptID( 891711 );	
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount( 1 );
		Send_XSCRIPT()			
		SpringFestival3_Guide_Close()

	elseif clickId == 13 then
		--花灯隐语
		local isrighttime = SpringFestival3_Guide_IsRightTime(clickId)
		if isrighttime <= 0 then
			PushDebugMessage("#{RACL_181206_443}")
			return
		end
		local nLevel = Player:GetLevel()
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{RACL_181206_444}")
			return
		end	
		local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(171) > 0 then  --卡级
			if nTodayActivePoint < 150 then
				PushDebugMessage("#{YXCDM_251210_01}")
				return		
			end
		else
			if nTodayActivePoint < 450 then
				PushDebugMessage("#{YXCDM_251210_01}")
				return		
			end
		end			
		--AutoRuntoTargetExWithName(274, 341, 0, "蔡弥")
		PushEvent("YUANXIAO_DENGMI")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateRedPoint" );
			Set_XSCRIPT_ScriptID( 892384 );	
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount( 1 );
		Send_XSCRIPT()			
		SpringFestival3_Guide_Close()
	elseif clickId == 14 then
		--三仙归位
		local isrighttime = SpringFestival3_Guide_IsRightTime(clickId)
		if isrighttime <= 0 then
			PushDebugMessage("#{KWCQ_201225_07}")
			return
		end	
		local nLevel = Player:GetLevel()
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{KWCQ_201225_08}")
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnDispatchOpenEnter" );
			Set_XSCRIPT_ScriptID( 892980 );	
			Set_XSCRIPT_ParamCount( 0 );
		Send_XSCRIPT()	
		-- PushEvent("OPEN_CAIQIUENTER", 1)
		SpringFestival3_Guide_Close()
	elseif clickId == 15 then
		--神射竞春
		local isrighttime = SpringFestival3_Guide_IsRightTime(clickId)
		if isrighttime <= 0 then
			PushDebugMessage("#{RACL_181206_443}")
			return
		end	
		local nLevel = Player:GetLevel();
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{RACL_181206_444}")
			return
		end	
		PushEvent("SHENSHE_ACTIVITY")
	
		SpringFestival3_Guide_UpdateTheRedPoint(893021)		
		--PushDebugMessage("#{RACL_181206_657}")
		SpringFestival3_Guide_Close()
	end
		
end

--=========
-- 小问号
--=========
function SpringFestival_Jinzhu_Help()
	PushEvent("CCSHOP_HELP", 141)
end


