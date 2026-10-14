--2022Q3新天外服务器进度活动
--进度界面

local g_Frame_UnifiedPosition = nil

--进度领奖
local g_MaxValue = 660000
local g_PrizeCtrl = {}
local g_Prize = 
{
	[1] = { value = 30000, mf = 3771, },
	[2] = { value = 60000, mf = 3772, },
	[3] = { value = 180000, mf = 3773, },
	[4] = { value = 300000, mf = 3774, },
	[5] = { value = 420000, mf = 3775, },
	[6] = { value = 540000, mf = 3822, },
	[7] = { value = 660000, mf = 3823, },
}

--=========
-- PreLoad()
--=========
function ThreeCity_fuwuqijindu_PreLoad()
		this:RegisterEvent("UI_COMMAND", true)
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ThreeCity_fuwuqijindu_OnLoad()	
		g_Frame_UnifiedPosition = ThreeCity_fuwuqijindu_FrameNULL:GetProperty("UnifiedPosition")			
		g_PrizeCtrl = 
		{
			[1] = {btn = ThreeCity_fuwuqijindu_Icon1, text = ThreeCity_fuwuqijindu_ScoreText1, tip = ThreeCity_fuwuqijindu_Icon1Tip, flag = ThreeCity_fuwuqijindu_Icon1Disabled, },
			[2] = {btn = ThreeCity_fuwuqijindu_Icon2, text = ThreeCity_fuwuqijindu_ScoreText2, tip = ThreeCity_fuwuqijindu_Icon2Tip, flag = ThreeCity_fuwuqijindu_Icon2Disabled, },
			[3] = {btn = ThreeCity_fuwuqijindu_Icon3, text = ThreeCity_fuwuqijindu_ScoreText3, tip = ThreeCity_fuwuqijindu_Icon3Tip, flag = ThreeCity_fuwuqijindu_Icon3Disabled, },
			[4] = {btn = ThreeCity_fuwuqijindu_Icon4, text = ThreeCity_fuwuqijindu_ScoreText4, tip = ThreeCity_fuwuqijindu_Icon4Tip, flag = ThreeCity_fuwuqijindu_Icon4Disabled, },			
			[5] = {btn = ThreeCity_fuwuqijindu_Icon5, text = ThreeCity_fuwuqijindu_ScoreText5, tip = ThreeCity_fuwuqijindu_Icon5Tip, flag = ThreeCity_fuwuqijindu_Icon5Disabled, },			
			[6] = {btn = ThreeCity_fuwuqijindu_Icon6, text = ThreeCity_fuwuqijindu_ScoreText6, tip = ThreeCity_fuwuqijindu_Icon6Tip, flag = ThreeCity_fuwuqijindu_Icon6Disabled, },			
			[7] = {btn = ThreeCity_fuwuqijindu_Icon7, text = ThreeCity_fuwuqijindu_ScoreText7, tip = ThreeCity_fuwuqijindu_Icon7Tip, flag = ThreeCity_fuwuqijindu_Icon7Disabled, },			
		}
end

--=========
-- Event
--=========
function ThreeCity_fuwuqijindu_OnEvent(event)
		if event == "UI_COMMAND" and tonumber(arg0) == 88879601 then
				local flag = tonumber(Get_XParam_INT(0))
				local value = tonumber(Get_XParam_INT(1))
				local state1 = tonumber(Get_XParam_INT(2))
				local state2 = tonumber(Get_XParam_INT(3))
				local state3 = tonumber(Get_XParam_INT(4))
				if flag == 1 then--开界面
						this:Show()
						ThreeCity_fuwuqijindu_Update(value,state1,state2,state3)
				elseif flag == 2 then-- 关界面
						if this:IsVisible() then
								ThreeCity_fuwuqijindu_Close()
						end
				else
						if this:IsVisible() then--仅刷新
								ThreeCity_fuwuqijindu_Update(value,state1,state2,state3)
						end
				end
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				ThreeCity_fuwuqijindu_Close()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				ThreeCity_fuwuqijindu_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				ThreeCity_fuwuqijindu_On_ResetPos()	
		end		
end

--=========
-- 重置
--=========
function ThreeCity_fuwuqijindu_On_ResetPos()
		ThreeCity_fuwuqijindu_FrameNULL:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 清数据
--=========
function ThreeCity_fuwuqijindu_Clear()
end

--=========
-- 关闭界面
--=========
function ThreeCity_fuwuqijindu_Close()
		ThreeCity_fuwuqijindu_Clear()
		this:Hide()
end

--=========
-- 界面刷新
--=========
function ThreeCity_fuwuqijindu_Update(value,state1,state2,state3)

		-- 文字
		if state1 > 0 or state2 > 0 or state3 > 0 then
			ThreeCity_fuwuqijindu_TextImage:Show()
			if state1 == 1 and state2 == 1 and state3 == 1 then
				ThreeCity_fuwuqijindu_Text:SetToolTip("#{TWFW_220802_44}")
			elseif state1 == 1 and state2 == 1 then
				ThreeCity_fuwuqijindu_Text:SetToolTip("#{TWFW_220802_43}")
			elseif state2 == 1 and state3 == 1 then
				ThreeCity_fuwuqijindu_Text:SetToolTip("#{TWFW_220802_45}")
			elseif state1 == 1 and state3 == 1 then
				ThreeCity_fuwuqijindu_Text:SetToolTip("#{TWFW_220802_44}")
			elseif state1 == 1 then
				ThreeCity_fuwuqijindu_Text:SetToolTip("#{TWFW_220802_40}")
			elseif state2 == 1 then
				ThreeCity_fuwuqijindu_Text:SetToolTip("#{TWFW_220802_41}")
			elseif state3 == 1 then
				ThreeCity_fuwuqijindu_Text:SetToolTip("#{TWFW_220802_42}")
			end
		else
			ThreeCity_fuwuqijindu_TextImage:Hide()
		end
		
		-- 进度
		ThreeCity_fuwuqijindu_ScoreText:SetText( ScriptGlobal_Format("#{TWFW_220802_11}",value) )
			
		-- 奖励
		for i=1, table.getn(g_PrizeCtrl) do
				-- 是否已领取
				local flag = Pneuma:GetMF(g_Prize[i].mf)
				if flag == 1 then
					--已领取
						--按钮
						g_PrizeCtrl[i].btn:Disable()
						--标记
						g_PrizeCtrl[i].flag:Show()
						--文字
						--g_PrizeCtrl[i].text:Hide()
						--小红点
						g_PrizeCtrl[i].tip:Hide()
				else
					--未领取
						--按钮
						g_PrizeCtrl[i].btn:Enable()
						--标记
						g_PrizeCtrl[i].flag:Hide()
						--文字
						--g_PrizeCtrl[i].text:Show()
						--小红点
						if value >= g_Prize[i].value then
								g_PrizeCtrl[i].tip:Show()
						else
								g_PrizeCtrl[i].tip:Hide()
						end
				end				
		end
		
end

--=========
-- 进度领奖按钮
--=========
function ThreeCity_fuwuqijindu_PointBouns_OK_Clicked(nIndex)
	if g_Prize[nIndex] == nil then
		return
	end
	Clear_XSCRIPT()
	    Set_XSCRIPT_Function_Name("OnPrize")
	    Set_XSCRIPT_ScriptID(888796)
	    Set_XSCRIPT_Parameter(0, nIndex)
			Set_XSCRIPT_Parameter(1, 0)
	    Set_XSCRIPT_ParamCount(2)
  Send_XSCRIPT()
end

--=========
-- 小问号
--=========
function ThreeCity_fuwuqijindu_Help()
		PushEvent("CCSHOP_HELP", 170)
end
