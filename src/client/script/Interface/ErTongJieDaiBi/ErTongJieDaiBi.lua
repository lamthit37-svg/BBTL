--【2022Q2】儿童节代币转换
-- 代币界面

local g_Frame_UnifiedPosition

local g_KJ_ERTONGJIEDAIBI = 84--卡级服

local g_Count1 = 0--低级代币数量

--页签2
local g_CostCtrl1 = {}
local g_Cost1 = 0
local g_Prize1 = {0,0,0,0,0}
local g_CostDaiBi1 = 
{
	[1] = { value = 15, tips = "#{DBZH_220419_77}", oritips = "#{DBZH_220419_77}", kajitips = "#{DBZH_220419_82}", },
	[2] = { value = 45, tips = "#{DBZH_220419_78}", oritips = "#{DBZH_220419_78}", kajitips = "#{DBZH_220419_83}", },
	[3] = { value = 90, tips = "#{DBZH_220419_79}", oritips = "#{DBZH_220419_79}", kajitips = "#{DBZH_220419_84}", },
	[4] = { value = 150, tips = "#{DBZH_220419_80}", oritips = "#{DBZH_260507_2}", kajitips = "#{DBZH_220419_85}", },
	[5] = { value = 225, tips = "#{DBZH_220419_81}", oritips = "#{DBZH_220419_81}", kajitips = "#{DBZH_220419_86}", },
}

--活跃领取低级代币
local g_HuoYueValue = 450
local g_KaJiHuoYueValue = 150

--=========
-- PreLoad()
--=========
function ErTongJieDaiBi_PreLoad()
		this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
		this:RegisterEvent("TODAY_ACTIVE_POINT",false);
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ErTongJieDaiBi_OnLoad()	
		g_Frame_UnifiedPosition = ErTongJieDaiBi_Frame:GetProperty("UnifiedPosition")			
		g_CostCtrl1 = 
		{
			[1] = {btn = ErTongJieDaiBi_List2_Icon1, text = ErTongJieDaiBi_Client1_list2_Text1, tip = ErTongJieDaiBi_List2_Icon1_Tips, flag = ErTongJieDaiBi_Client1_List2_1_Mask, },
			[2] = {btn = ErTongJieDaiBi_List2_Icon2, text = ErTongJieDaiBi_Client1_list2_Text2, tip = ErTongJieDaiBi_List2_Icon2_Tips, flag = ErTongJieDaiBi_Client1_List2_2_Mask, },
			[3] = {btn = ErTongJieDaiBi_List2_Icon3, text = ErTongJieDaiBi_Client1_list2_Text3, tip = ErTongJieDaiBi_List2_Icon3_Tips, flag = ErTongJieDaiBi_Client1_List2_3_Mask, },
			[4] = {btn = ErTongJieDaiBi_List2_Icon4, text = ErTongJieDaiBi_Client1_list2_Text4, tip = ErTongJieDaiBi_List2_Icon4_Tips, flag = ErTongJieDaiBi_Client1_List2_4_Mask, },
			[5] = {btn = ErTongJieDaiBi_List2_Icon5, text = ErTongJieDaiBi_Client1_list2_Text5, tip = ErTongJieDaiBi_List2_Icon5_Tips, flag = ErTongJieDaiBi_Client1_List2_5_Mask, },
		}		
end

--=========
-- Event
--=========
function ErTongJieDaiBi_OnEvent(event)
		if event == "UI_COMMAND" and tonumber(arg0) == 99802501 then
				local bOpen = tonumber(Get_XParam_INT(0))
				--关界面
				if bOpen == nil or bOpen == 2 then
						if( this:IsVisible() ) then
				        ErTongJieDaiBi_Close()
						end
						return
				end
				--刷数据
				g_Count1 = tonumber(Get_XParam_INT(1))--低级代币数量
				g_Cost1 = tonumber(Get_XParam_INT(2))--低级代币消耗数量
				local paramIndex = 2
				for nIndex = 1, table.getn(g_Prize1) do
						g_Prize1[nIndex] = tonumber(Get_XParam_INT(paramIndex+nIndex))--低级代币消耗领奖
				end

				--开界面
				if bOpen == 1 then
						this:Show()
						ErTongJieDaiBi_Update2()
				--刷界面
				else
						if( this:IsVisible() ) then
								ErTongJieDaiBi_Update2()
						end
				end
		elseif event == "UI_COMMAND" and tonumber(arg0) == 99802504 then
				AutoRuntoTargetExWithName(268, 347, 0, "莲薇")
				ErTongJieDaiBi_Close()
		elseif event == "TODAY_ACTIVE_POINT" and this:IsVisible() then	
				if g_Page == 2 then
						ErTongJieDaiBi_UpdateHuoYueBtn()
				end
				ErTongJieDaiBi_ShowPageTips()
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				ErTongJieDaiBi_Close()
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				ErTongJieDaiBi_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				ErTongJieDaiBi_On_ResetPos()
		end		
end

--=========
-- 重置
--=========
function ErTongJieDaiBi_On_ResetPos()
		ErTongJieDaiBi_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 清数据
--=========
function ErTongJieDaiBi_Clear()
		g_Count1 = 0
		g_Cost1 = 0
		for nIndex = 1, table.getn(g_Prize1) do
				g_Prize1[nIndex] = 0
		end
end

--=========
-- 关闭界面
--=========
function ErTongJieDaiBi_Close()
		ErTongJieDaiBi_Clear()
		this:Hide()
end

--=========
-- 切换页签
--=========
function ErTongJieDaiBi_SwitchPage(nPage)		
end

--=========
-- 页签2-活跃领奖小红点
--=========
function ErTongJieDaiBi_CanHuoYuePrize()
		--今日活跃值
		local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
		--需要活跃值
		local nHuoYueValue = g_HuoYueValue
		if KaJi:LuaFnGetKaJiType(g_KJ_ERTONGJIEDAIBI) == 1 then--卡级服
				nHuoYueValue = g_KaJiHuoYueValue
		end
		--可领奖且未领奖
		if nToadyActivePoint >= nHuoYueValue and Pneuma:GetMF(3620) ~= 1 then
				return 1
		end
		return 0
end

--=========
-- 页签1-累计领奖小红点
--=========
function ErTongJieDaiBi_CanDuiHuanPrize()
		return 0
end

--=========
-- 页签2-累计领奖小红点
--=========
function ErTongJieDaiBi_CanCostPrize()
		-- 低级代币
		for nIndex = 1, table.getn(g_CostDaiBi1) do
				if g_Cost1 >= g_CostDaiBi1[nIndex].value and g_Prize1[nIndex] ~= 1 then--可领奖且未领奖
						return 1						
				end
		end
		return 0
end

--=========
-- 显示页签小红点
--=========
function ErTongJieDaiBi_ShowPageTips()
end

--=========
-- 页签2-活跃领奖按钮小红点
--=========
function ErTongJieDaiBi_UpdateHuoYueBtn()
		-- 今日活跃值
		local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
		--需要活跃值
		local nHuoYueValue = g_HuoYueValue
		if KaJi:LuaFnGetKaJiType(g_KJ_ERTONGJIEDAIBI) == 1 then--卡级服
				nHuoYueValue = g_KaJiHuoYueValue
		end
		--可领奖
		if nToadyActivePoint >= nHuoYueValue then
				if Pneuma:GetMF(3620) ~= 1 then--未领奖
						ErTongJieDaiBi_Text_Btn_Tips:Show()
				else--已领奖
						ErTongJieDaiBi_Text_Btn_Tips:Hide()
				end
		--不可领奖
		else
				ErTongJieDaiBi_Text_Btn_Tips:Hide()
		end		
end

--=========
-- 更新低级代币数量
--=========
function ErTongJieDaiBi_UpdateCommonData()			
		-- 低级代币
		ErTongJieDaiBi_text3_info2:SetText( ScriptGlobal_Format("#{DBZH_220419_26}",g_Count1) )
		-- 文字描述
		if KaJi:LuaFnGetKaJiType(g_KJ_ERTONGJIEDAIBI) == 1 then--卡级服
				ErTongJieDaiBi_text3_info2:SetToolTip("#{DBZH_250520_23}")
		else
				ErTongJieDaiBi_text3_info2:SetToolTip("#{DBZH_220419_27}")
		end
end

--=========
-- 页签1-代币兑换页签
--=========
function ErTongJieDaiBi_Update1()
end

--=========
-- 页签2-累计领奖页签
--=========
function ErTongJieDaiBi_Update2()
			
		-- 文字描述
		if KaJi:LuaFnGetKaJiType(g_KJ_ERTONGJIEDAIBI) == 1 then--卡级服
				ErTongJieDaiBi_Client1_Text:SetText("#{DBZH_250520_25}")
		else
				ErTongJieDaiBi_Client1_Text:SetText("#{DBZH_250520_24}")
		end
		
		-- 活跃领奖文字
		if KaJi:LuaFnGetKaJiType(g_KJ_ERTONGJIEDAIBI) == 1 then--卡级服
				ErTongJieDaiBi_text_info2:SetText("#{DBZH_220419_18}")
		else
				ErTongJieDaiBi_text_info2:SetText("#{DBZH_220419_17}")
		end		
		-- 活跃领奖按钮小红点
		ErTongJieDaiBi_UpdateHuoYueBtn()
				
		-- 低级代币消耗领奖
		for nIndex = 1, table.getn(g_CostDaiBi1) do
				-- 领奖按钮tips
				if Player:GetData("IsOriginalJD") == 1 then--删减服
					g_CostCtrl1[nIndex].btn:SetToolTip(g_CostDaiBi1[nIndex].oritips)
				elseif KaJi:LuaFnGetKaJiType(g_KJ_ERTONGJIEDAIBI) == 1 then--卡级服
						g_CostCtrl1[nIndex].btn:SetToolTip(g_CostDaiBi1[nIndex].kajitips)
				else
						g_CostCtrl1[nIndex].btn:SetToolTip(g_CostDaiBi1[nIndex].tips)
				end
				-- 不可领奖
				if g_Cost1 < g_CostDaiBi1[nIndex].value then
						-- 小红点
						g_CostCtrl1[nIndex].tip:Hide()
						-- 领取标记
						g_CostCtrl1[nIndex].flag:Hide()
						-- 文字
						g_CostCtrl1[nIndex].text:SetText( ScriptGlobal_Format("#{DBZH_220419_67}",g_Cost1,g_CostDaiBi1[nIndex].value) )
				-- 可领奖
				else
						-- 是否领奖
						if g_Prize1[nIndex] == 1 then-- 已领奖
								-- 小红点
								g_CostCtrl1[nIndex].tip:Hide()
								-- 领取标记
								g_CostCtrl1[nIndex].flag:Show()
						else-- 未领奖
								-- 小红点
								g_CostCtrl1[nIndex].tip:Show()
								-- 领取标记
								g_CostCtrl1[nIndex].flag:Hide()
						end
						-- 文字
						g_CostCtrl1[nIndex].text:SetText( ScriptGlobal_Format("#{DBZH_220419_68}",g_Cost1,g_CostDaiBi1[nIndex].value) )
				end
		end
		
		-- 更新低级代币数量
		ErTongJieDaiBi_UpdateCommonData()

		-- 显示页签小红点
		ErTongJieDaiBi_ShowPageTips()
		
end	

--=========
-- 页签2-活跃值领奖按钮
--=========
function ErTongJieDaiBi_HuoYueClicked()
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("HuoYuePrize")
				Set_XSCRIPT_ScriptID(998025)
				Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
end

--=========
-- 页签1-打开批量兑换界面
--=========
function ErTongJieDaiBi_DuiHuanClicked()
end

--=========
-- 页签1-时装预览
--=========
function ErTongJieDaiBi_Text2_Preview_Clicked(nIndex)
end

--=========
-- 页签1-高级代币累计兑换奖励
--=========
function ErTongJieDaiBi_DuiHuanPrizeClicked(nIndex)
end

--=========
-- 获取途径按钮
--=========
function ErTongJieDaiBi_HelpClicked()
		PushEvent("CCSHOP_HELP", 161)	
end

--=========
-- 页签2-消耗低级代币领奖按钮
--=========
function ErTongJieDaiBi_CostPrize1Clicked(nIndex)
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("CostDaiBiPrize1")
				Set_XSCRIPT_ScriptID(998025)
				Set_XSCRIPT_Parameter( 0, nIndex )
				Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
end

--=========
-- 页签2-前往按钮
--=========
function ErTongJieDaiBi_GoToClicked()
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("AutoNpc")
				Set_XSCRIPT_ScriptID(998025)
				Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
end
