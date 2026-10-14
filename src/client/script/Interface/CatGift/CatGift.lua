--【2021Q2】御猫探宝玩法
-- 御猫探宝界面

local g_Frame_UnifiedPosition

--左侧地图区
local g_MapCtrl = {}

--下方代币奖励
local g_IconCtrl = {}

--任务数据
local g_MissionCount = 5
local g_MissionTime = {0,0,0,0,0}

--代币数据
local g_MaxDaiBiValue = 4000
local g_DaiBiData = 
{
	[1] = { value = 300, tips1 = "#{YMTB_210520_157}", tips2 = "#{YMTB_210520_163}", },
	[2] = { value = 700, tips1 = "#{YMTB_210520_158}", tips2 = "#{YMTB_210520_164}", },
	[3] = { value = 1200, tips1 = "#{YMTB_210520_159}", tips2 = "#{YMTB_210520_165}", },
	[4] = { value = 2000, tips1 = "#{YMTB_210520_160}", tips2 = "#{YMTB_210520_166}", },
	[5] = { value = 3000, tips1 = "#{YMTB_210520_161}", tips2 = "#{YMTB_210520_167}", },
	[6] = { value = 4000, tips1 = "#{YMTB_210520_162}", tips2 = "#{YMTB_210520_168}", },
}

--=========
-- PreLoad()
--=========
function CatGift_PreLoad()

	this:RegisterEvent("UI_COMMAND", false)--打开or刷新界面
	this:RegisterEvent("CATMISSION_OPENTANBAOUI", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function CatGift_OnLoad()
	
	g_Frame_UnifiedPosition = CatGift:GetProperty("UnifiedPosition")
		
	g_MapCtrl = 
	{-- 默认图标 队长图标 搜索中文字 已完成文字 开始按钮 完成按钮 小红点
		[1] = { sign = CatGift_MapPlace1_Sign, icon = CatGift_MapPlace1_Icon, text = CatGift_MapPlace1_Text, begin = CatGift_CoinAItem1_New_Button, finish = CatGift_CoinAItem1_Done_Button, tip = CatGift_CoinAItem1_Done_ButtonTip, },
		[2] = { sign = CatGift_MapPlace2_Sign, icon = CatGift_MapPlace2_Icon, text = CatGift_MapPlace2_Text, begin = CatGift_CoinAItem2_New_Button, finish = CatGift_CoinAItem2_Done_Button, tip = CatGift_CoinAItem2_Done_ButtonTip, },
		[3] = { sign = CatGift_MapPlace3_Sign, icon = CatGift_MapPlace3_Icon, text = CatGift_MapPlace3_Text, begin = CatGift_CoinAItem3_New_Button, finish = CatGift_CoinAItem3_Done_Button, tip = CatGift_CoinAItem3_Done_ButtonTip, },
		[4] = { sign = CatGift_MapPlace4_Sign, icon = CatGift_MapPlace4_Icon, text = CatGift_MapPlace4_Text, begin = CatGift_CoinAItem4_New_Button, finish = CatGift_CoinAItem4_Done_Button, tip = CatGift_CoinAItem4_Done_ButtonTip, },
		[5] = { sign = CatGift_MapPlace5_Sign, icon = CatGift_MapPlace5_Icon, text = CatGift_MapPlace5_Text, begin = CatGift_CoinAItem5_New_Button, finish = CatGift_CoinAItem5_Done_Button, tip = CatGift_CoinAItem5_Done_ButtonTip, },
	}
	
	g_IconCtrl = 
	{-- 奖励图标 小红点 已领取标记
		[1] = { btn = CatGift_Icon1, dot = CatGift_Icon1_RedDot, flag = CatGift_Icon1_Done, },
		[2] = { btn = CatGift_Icon2, dot = CatGift_Icon2_RedDot, flag = CatGift_Icon2_Done, },
		[3] = { btn = CatGift_Icon3, dot = CatGift_Icon3_RedDot, flag = CatGift_Icon3_Done, },
		[4] = { btn = CatGift_Icon4, dot = CatGift_Icon4_RedDot, flag = CatGift_Icon4_Done, },
		[5] = { btn = CatGift_Icon5, dot = CatGift_Icon5_RedDot, flag = CatGift_Icon5_Done, },
		[6] = { btn = CatGift_Icon6, dot = CatGift_Icon6_RedDot, flag = CatGift_Icon6_Done, },
	}

end

--=========
-- Event
--=========
function CatGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88843801) then
	
		CatGift_Close()

	elseif event == "CATMISSION_OPENTANBAOUI" then
	
		local bOpen = tonumber(arg0)
		if bOpen ~= nil and bOpen == 1 then--开界面
			this:Show()
			CatGift_Open()
		else
			if( this:IsVisible() ) then--仅刷新
        CatGift_Open()
			end
		end
				
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		CatGift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		CatGift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		CatGift_On_ResetPos()

	end
end


function CatGift_Close()
	KillTimer("CatGift_TimerProc()")
	this:Hide()
end

--=========
-- 重置
--=========
function CatGift_On_ResetPos()

	CatGift:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function CatGift_Open()

	-- 任务地图
	for nIndex=1, g_MissionCount do
		-- 任务数据
		local bRet,missionId,missionState,remainTime,nCatId1,nCatId2,nCatId3 = DataPool:Lua_GetCatMissionDataByIndex(nIndex-1)
		-- 存在任务数据
		if bRet ~= nil and bRet == 1 and missionId > 0 then
			if missionState == 1 then-- 任务探索中
				g_MapCtrl[nIndex].begin:Hide()
				g_MapCtrl[nIndex].finish:Hide()
				g_MapCtrl[nIndex].tip:Hide()
				-- 剩余时间
				g_MissionTime[nIndex] = remainTime - 1
				g_MapCtrl[nIndex].text:SetText(ScriptGlobal_Format("#{YMTB_210520_15}", remainTime))
				g_MapCtrl[nIndex].text:Show()
				-- 猫猫图标
			  local catId = 0
			  if nCatId1 > 0 then
			  	catId = nCatId1
			  elseif nCatId2 > 0 then
			  	catId = nCatId2
			  elseif nCatId3 > 0 then
			  	catId = nCatId3
			  end
			  if catId > 0 then
					local catCount, _, catName, catIcon, catLevel = DataPool:LuaFnGetFindCatTableInfo(2, catId)
					g_MapCtrl[nIndex].icon:SetProperty("Image", catIcon)	
					g_MapCtrl[nIndex].icon:Show()
				end
			elseif missionState == 2 then-- 任务已完成
				g_MapCtrl[nIndex].begin:Hide()
				g_MapCtrl[nIndex].icon:Hide()
				g_MapCtrl[nIndex].text:Hide()
				g_MissionTime[nIndex] = 0
				-- 领取按钮
				g_MapCtrl[nIndex].finish:Show()
				g_MapCtrl[nIndex].tip:Show()
			elseif missionState <= 0 then-- 任务未派遣
				g_MapCtrl[nIndex].icon:Hide()
				g_MapCtrl[nIndex].text:Hide()
				g_MissionTime[nIndex] = 0
				g_MapCtrl[nIndex].finish:Hide()
				g_MapCtrl[nIndex].tip:Hide()
				-- 派遣按钮
				g_MapCtrl[nIndex].begin:Show()
			end
		end
	end
	--设置计时器
	CatGift_SetTimerProc()
	
	-- 代币
	local nDaiBiValue = DataPool:Lua_GetCatMissionDaiBi()
	CatGift_Huoyue_Text0:SetText(ScriptGlobal_Format("#{YMTB_210520_13}", nDaiBiValue, g_MaxDaiBiValue))
	-- 进度条
	--CatGift_Huoyue:SetProgress(tonumber(nDaiBiValue), g_MaxDaiBiValue)
	-- 奖励显示
	for nIndex = 1, table.getn(g_DaiBiData) do
		-- 小红点+领取标记+tips
		local bFlag = DataPool:Lua_GetCatMissionPrizeFlagByIndex(nIndex-1)
		if bFlag == 1 then--已领取
			g_IconCtrl[nIndex].flag:Show()
			g_IconCtrl[nIndex].dot:Hide()
			g_IconCtrl[nIndex].btn:SetToolTip(g_DaiBiData[nIndex].tips2)
		elseif bFlag == 0 then--未领取
			g_IconCtrl[nIndex].flag:Hide()
			g_IconCtrl[nIndex].btn:SetToolTip(g_DaiBiData[nIndex].tips1)
			if nDaiBiValue >= g_DaiBiData[nIndex].value then--可领取未领取
				g_IconCtrl[nIndex].dot:Show()
			else--不可领取
				g_IconCtrl[nIndex].dot:Hide()
			end
		end
	end	
	
end

--=========
-- 点击派遣
--=========
function CatGift_ClickPaiQian( nIndex )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenPaiQianUI" )
		Set_XSCRIPT_ScriptID( 888438 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
	
end

--=========
-- 点击领取
--=========
function CatGift_ClickReceivePrize( nIndex )
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetMissionPrize" )
		Set_XSCRIPT_ScriptID( 888438 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	

end

--=========
-- 点击领奖
--=========
function CatGift_PrizeClicked( nIndex )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetDaiBiPrize" )
		Set_XSCRIPT_ScriptID( 888438 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
	
end

--=========
-- 帮助按钮
--=========
function CatGift_Description_Clicked()
	PushEvent("CCSHOP_HELP", 133)	
end

--=========
-- 设置计时器
--=========
function CatGift_SetTimerProc()

	KillTimer("CatGift_TimerProc()")
	
	local bFlag = 0
	for i=1, table.getn(g_MissionTime) do
		if g_MissionTime[i] > 0 then
			bFlag = 1
			break
		end
	end
	
	if bFlag == 1 then
		SetTimer("CatGift", "CatGift_TimerProc()", 1000)
	end

end

--=========
-- 显示剩余时间
--=========
function CatGift_TimerProc()
	
	-- 显示时间
	local bContinue = 0
	for i=1, table.getn(g_MissionTime) do
		g_MissionTime[i] = g_MissionTime[i] - 1
		if g_MissionTime[i] > 0 then
			g_MapCtrl[i].text:SetText(ScriptGlobal_Format("#{YMTB_210520_15}", g_MissionTime[i]))
			bContinue = 1
		end
	end
	
	-- 删除定时器
	if bContinue ~= 1 then
		for i=1, table.getn(g_MissionTime) do
			g_MissionTime[i] = 0
			g_MapCtrl[i].text:SetText(ScriptGlobal_Format("#{YMTB_210520_15}", 0))
		end
		KillTimer("CatGift_TimerProc()")
	end
	
end