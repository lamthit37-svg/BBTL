--!!!reloadscript =Fashion_AuctionEnter

--===============================================
-- PreLoad()
--===============================================
function Fashion_AuctionEnter_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_TLBB_MAIN")
	this:RegisterEvent("HIDE_THIS_UI")
end

--===============================================
-- OnLoad()
--===============================================
function Fashion_AuctionEnter_OnLoad()

end

--===============================================
-- OnEvent()
--===============================================
function Fashion_AuctionEnter_OnEvent(event)
	if event  == "UI_COMMAND" and tonumber(arg0) == 77788803 then
		local bShow = Get_XParam_INT(0)
		Fashion_AuctionEnter_ShowIcon(bShow)
		return
	end
	
	if event  == "UI_COMMAND" and tonumber(arg0) == 77788804 then
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			Fashion_AuctionEnter_Animate:Show()
		else
			Fashion_AuctionEnter_Animate:Hide()
		end
		return
	end
	
	if event == "HIDE_TLBB_MAIN" then
		if this:IsVisible() then
			this:Hide()
		end
	end
	
	if event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		end
	end
end

--===============================================
-- OnShow()
--===============================================
function Fashion_AuctionEnter_ShowIcon(bShow)
	if bShow == nil then
		return
	end
	
	--关闭界面
	if bShow == 0 then
		if this:IsVisible() then
			this:Hide()
		end
	elseif bShow == 1 then	--显示界面
		if this:IsVisible() then
			--不处理
		else
			--界面显示
			this:Show()
				
			--闪烁时间判断
			if bShow == 1 then
				--图标闪烁
			--	Fashion_AuctionEnter_Icon:PlayWarning(0)
				Fashion_AuctionEnter_Icon:SetToolTip("#{WHTJ_240117_01}")
				--设置闪烁冷却时间
			--	g_InPlayWarning = 1
			--	SetTimer("Fashion_AuctionEnter", "Fashion_AuctionEnter_PlayWarning()", g_PlayWarning)
			end
		end
	end
end

--===============================================
-- OnClick()
--===============================================
function Fashion_AuctionEnter_OnClick()
		
	--等级判断
	local nLevel = Player:GetData("LEVEL")
	if nLevel < 30 then
		PushDebugMessage("#{WHTJ_240117_03}")	--您尚未达到15级，无法参加玫瑰传情活动。
		return
	end
	
	if IsWindowShow("Fashion_Auction") then
		return
	end
	
	--图标闪烁消失			
--	Fashion_AuctionEnter_Icon:PlayWarning(0)
	--浮动tips消失
--	CloseFreshManGuide()
--	Fashion_AuctionEnter_Icon:SetToolTip("#{SZPM_230913_86}")
	
	--判断冷却时间
--	if g_InCooldown == 0 then--冷却时间已到
		--请求服务器数据
		if IsInHell() == 1 then
			PushDebugMessage("#{WHTJ_240117_04}")	--当前场景无法进行此操作
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("TryOpenFashionAuction")
			Set_XSCRIPT_ScriptID(777888)
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_Parameter(2, 0) --是否收刷新cd限制
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
		--设置冷却时间
	--	g_InCooldown = 1
	--	SetTimer("Fashion_AuctionEnter", "Fashion_AuctionEnter_Cooldown()",g_Cooldown)
--	else	
		--冷却时间未到
	--	PushDebugMessage("#{QRZM_211119_163}")--您的操作过于频繁，请稍后再行尝试
--	end
end

--===============================================
-- 冷却计时结束()
--===============================================
function Fashion_AuctionEnter_Cooldown()
--	g_InCooldown = 0
--	KillTimer("Fashion_AuctionEnter_Cooldown()")
end

--===============================================
-- 闪烁计时结束()
--===============================================
function Fashion_AuctionEnter_PlayWarning()
	--图标闪烁消失			
--	Fashion_AuctionEnter_Icon:PlayWarning(0)
	--浮动tips消失
--	CloseFreshManGuide()
--	Fashion_AuctionEnter_Icon:SetToolTip("#{SZPM_230913_86}")
	--闪烁计时停止
--	g_InPlayWarning = 0
--	KillTimer("Fashion_AuctionEnter_PlayWarning()")
end
