--2021双旦集五福
-- 五福卡奖励界面

local g_Frame_UnifiedPosition = nil

local g_PrizeCtrl = {}
local g_MaxValue = 15
local g_Count = 5

local g_Cooldown = 6*1000		--6s按钮冷却
local g_InCooldown = 0			--是否在冷却
local g_AnimateTick = 0
local g_PlayAnimate = 0

--进度领奖
local g_Prize = 
{
	[1] = { value = 3, tip = "#{FHSX_211019_32}", kjtip = "#{FHSX_211019_112}", },
	[2] = { value = 6, tip = "#{FHSX_211019_33}", kjtip = "#{FHSX_211019_113}", },
	[3] = { value = 9, tip = "#{FHSX_211019_34}", kjtip = "#{FHSX_211019_34}", },
	[4] = { value = 12, tip = "#{FHSX_211019_35}", kjtip = "#{FHSX_211019_114}", },
	[5] = { value = 15, tip = "#{FHSX_211019_104}", kjtip = "#{FHSX_211019_115}", },
}

--=========
-- PreLoad()
--=========
function ShuangDan_FHSX_PreLoad()
		this:RegisterEvent("FHSX_OPENUI", true)--打开or刷新界面
		this:RegisterEvent("UI_COMMAND", false)--播放动画
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ShuangDan_FHSX_OnLoad()	
		g_Frame_UnifiedPosition = ShuangDan_FHSX_MainFrame:GetProperty("UnifiedPosition")
			
		g_PrizeCtrl = 
		{
			[1] = {btn = ShuangDan_FHSX_ProgressReward_Item1, tip = ShuangDan_FHSX_Item1_Tips, flag = ShuangDan_FHSX_Item1_Mark, },
			[2] = {btn = ShuangDan_FHSX_ProgressReward_Item2, tip = ShuangDan_FHSX_Item2_Tips, flag = ShuangDan_FHSX_Item2_Mark, },
			[3] = {btn = ShuangDan_FHSX_ProgressReward_Item3, tip = ShuangDan_FHSX_Item3_Tips, flag = ShuangDan_FHSX_Item3_Mark, },
			[4] = {btn = ShuangDan_FHSX_ProgressReward_Item4, tip = ShuangDan_FHSX_Item4_Tips, flag = ShuangDan_FHSX_Item4_Mark, },			
			[5] = {btn = ShuangDan_FHSX_ProgressReward_Item5, tip = ShuangDan_FHSX_Item5_Tips, flag = ShuangDan_FHSX_Item5_Mark, },			
		}
end

--=========
-- Event
--=========
function ShuangDan_FHSX_OnEvent(event)
		if event == "FHSX_OPENUI" then		
				local bOpen = tonumber(arg0)
				local nPage = tonumber(arg1)
				if nPage ~= 1 then
						return
				end
				if bOpen ~= nil and bOpen == 1 then--开界面
						this:Show()
						ShuangDan_FHSX_ClearCDTime()--清按钮CD
						ShuangDan_FHSX_ClearAnimate()--清动画
						ShuangDan_FHSX_Update()
				else
						if( this:IsVisible() ) then--仅刷新
								ShuangDan_FHSX_Update()
						end
				end			
		elseif event == "UI_COMMAND" and tonumber(arg0) == 88880101 then
				if( this:IsVisible() ) then
						ShuangDan_FHSX_PlayAnimate()--播放动画
				end
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				ShuangDan_FHSX_Close()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				ShuangDan_FHSX_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				ShuangDan_FHSX_On_ResetPos()	
		end		
end

--=========
-- 重置
--=========
function ShuangDan_FHSX_On_ResetPos()
		ShuangDan_FHSX_MainFrame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 清数据
--=========
function ShuangDan_FHSX_Clear()
		ShuangDan_FHSX_ClearCDTime()
		ShuangDan_FHSX_ClearAnimate()
end

--=========
-- 关闭界面
--=========
function ShuangDan_FHSX_Close()
		ShuangDan_FHSX_Clear()
		this:Hide()
end

--=========
-- 进度领奖小红点
--=========
function ShuangDan_FHSX_CanPrize()
		local nValue = DataPool:Lua_GetFHSXProgressValue()
		for nIndex=1, table.getn(g_Prize) do
				local bFlag = DataPool:Lua_GetFHSXProgressFlag(nIndex-1)	
				if nValue >= g_Prize[nIndex].value and bFlag ~= 1 then--可领奖且未领奖
						return 1
				end
		end
		return 0
end

--=========
-- 界面刷新
--=========
function ShuangDan_FHSX_Update()
			
		-- 五福卡
		local count = DataPool:Lua_GetFHSXCardCount()
		if count >= g_Count then-- 足够-绿色
				ShuangDan_FHSX_WuFuCard1_Num:SetText( ScriptGlobal_Format("#{FHSX_211019_23}",count,g_Count) )
				ShuangDan_FHSX_WuFuCard_RewardTips:Show()--红点
		else--不够-红色
				ShuangDan_FHSX_WuFuCard1_Num:SetText( ScriptGlobal_Format("#{FHSX_211019_24}",count,g_Count) )
				ShuangDan_FHSX_WuFuCard_RewardTips:Hide()--红点
		end
		
		-- 进度奖励
		local nValue = DataPool:Lua_GetFHSXProgressValue()
		ShuangDan_FHSX_CurrentProgress_Text:SetText( ScriptGlobal_Format("#{FHSX_211019_31}",nValue) )
		for i=1, table.getn(g_PrizeCtrl) do
				--tooltip
				local szTip = g_Prize[i].tip
				if KaJi:LuaFnGetKaJiType(33) == 1 then
						szTip = g_Prize[i].kjtip
				end
				g_PrizeCtrl[i].btn:SetToolTip(""..szTip)
				-- 已领取标记
				local flag = DataPool:Lua_GetFHSXProgressFlag(i-1)
				if flag == 1 then
						g_PrizeCtrl[i].flag:Show()
						--小红点
						g_PrizeCtrl[i].tip:Hide()
				else
						g_PrizeCtrl[i].flag:Hide()
						-- 小红点
						if nValue >= g_Prize[i].value then
								g_PrizeCtrl[i].tip:Show()
						else
								g_PrizeCtrl[i].tip:Hide()
						end
				end				
		end
		
end

--=========
-- 清按钮CD
--=========
function ShuangDan_FHSX_ClearCDTime()
		g_InCooldown = 0
		KillTimer("ShuangDan_FHSX_ButtonCDTimer()")
end

--=========
-- 清动画
--=========
function ShuangDan_FHSX_ClearAnimate()
		g_AnimateTick = 0
		ShuangDan_FHSX_Drawing_Frame:SetProperty("Alpha",0)
		KillTimer("ShuangDan_FHSX_AnimateTimer()")
		g_PlayAnimate = 0
		ShuangDan_FHSX_LuoHua:Play(false)
end

--=========
-- 播放动画
--=========
function ShuangDan_FHSX_PlayAnimate()
		ShuangDan_FHSX_ClearAnimate()--清动画
		SetTimer("ShuangDan_FHSX","ShuangDan_FHSX_AnimateTimer()", 200)--计时器
		if g_InCooldown == 0 then
			--设置冷却时间
			g_InCooldown = 1
			SetTimer("ShuangDan_FHSX", "ShuangDan_FHSX_ButtonCDTimer()",g_Cooldown)
		end
end

--=========
-- 计时器
--=========
function ShuangDan_FHSX_AnimateTimer()
		g_AnimateTick = g_AnimateTick+1	
		if g_AnimateTick > 0 and g_AnimateTick < 10 then
				ShuangDan_FHSX_Drawing_Frame:SetProperty("Alpha",g_AnimateTick*0.1)
		elseif g_AnimateTick >= 10 and g_AnimateTick <= 20 then
				ShuangDan_FHSX_Drawing_Frame:SetProperty("Alpha",1)
				if g_PlayAnimate ~= 1 then--播放落花动画
					g_PlayAnimate = 1
					ShuangDan_FHSX_LuoHua:Play(true)
				end
		elseif g_AnimateTick > 20 and g_AnimateTick < 30 then
				ShuangDan_FHSX_Drawing_Frame:SetProperty("Alpha",(30-g_AnimateTick)*0.1)
		elseif g_AnimateTick >= 30 then
				g_AnimateTick = 0
				ShuangDan_FHSX_Drawing_Frame:SetProperty("Alpha",0)
				KillTimer("ShuangDan_FHSX_AnimateTimer()")
		end
end


--=========
-- 按钮计时器
--=========
function ShuangDan_FHSX_ButtonCDTimer()
		g_InCooldown = 0
		KillTimer("ShuangDan_FHSX_ButtonCDTimer()")
end

--=========
-- 五福卡兑奖按钮
--=========
function ShuangDan_FHSX_RewardClicked()
		if g_InCooldown == 1 then--冷却时间
				PushDebugMessage("#{FHSX_211019_129}")
				return
		end
		--领取奖励
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnReward")
				Set_XSCRIPT_ScriptID(888801)
				Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
end

--=========
-- 进度领奖按钮
--=========
function ShuangDan_FHSX_PrizeClicked(nIndex)
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnPrize")
				Set_XSCRIPT_ScriptID(888801)
				Set_XSCRIPT_Parameter( 0, nIndex )
				Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
end

--=========
-- 小问号
--=========
function ShuangDan_FHSX_Help1()
		PushEvent("CCSHOP_HELP", 135)	
end
