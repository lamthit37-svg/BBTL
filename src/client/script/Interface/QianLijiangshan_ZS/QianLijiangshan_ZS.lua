--【2020Q4】春节-兑换千里江山时装活动--兑换千里江山时装礼盒

local g_Frame_UnifiedPosition

--图标数量
local g_MaxCount = 5

--图标数据
local g_MDData = -1
--领奖标记
local g_MFValue = -1

--图标按钮
local g_PicImages = {}
--图标动画
local g_Animates = {}
--图标小红点
local g_RedPoints = {}

--=========
-- PreLoad()
--=========
function QianLijiangshan_ZS_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function QianLijiangshan_ZS_OnLoad()
	
	g_Frame_UnifiedPosition = QianLijiangshan_ZS_Frame:GetProperty("UnifiedPosition")
		
	g_PicImages[1] = QianLijiangshan_ZS_PicBK1
	g_PicImages[2] = QianLijiangshan_ZS_PicBK2
	g_PicImages[3] = QianLijiangshan_ZS_PicBK3
	g_PicImages[4] = QianLijiangshan_ZS_PicBK4
	g_PicImages[5] = QianLijiangshan_ZS_PicBK5
	
	g_Animates[1] = QianLijiangshan_ZS_BK1Animate
	g_Animates[2] = QianLijiangshan_ZS_BK2Animate
	g_Animates[3] = QianLijiangshan_ZS_BK3Animate
	g_Animates[4] = QianLijiangshan_ZS_BK4Animate
	g_Animates[5] = QianLijiangshan_ZS_BK5Animate
	
	g_RedPoints[1] = QianLijiangshan_ZS_BK1Tips
	g_RedPoints[2] = QianLijiangshan_ZS_BK2Tips
	g_RedPoints[3] = QianLijiangshan_ZS_BK3Tips
	g_RedPoints[4] = QianLijiangshan_ZS_BK4Tips
	g_RedPoints[5] = QianLijiangshan_ZS_BK5Tips

end

--=========
-- Event
--=========
function QianLijiangshan_ZS_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88833101) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then--打开界面
			g_MDData = Get_XParam_INT(1)
			g_MFValue = Get_XParam_INT(2)
			QianLijiangshan_ZS_Open()
			this:Show()
		elseif bShow == 2 then--关闭界面
			QianLijiangshan_ZS_Close()
		elseif bShow == 3 then--刷新界面
			if this:IsVisible() then
				g_MDData = Get_XParam_INT(1)
				g_MFValue = Get_XParam_INT(2)
				QianLijiangshan_ZS_Open()
			end
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		QianLijiangshan_ZS_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		QianLijiangshan_ZS_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		QianLijiangshan_ZS_On_ResetPos()

	end
	
end

--=========
-- Close
--=========
function QianLijiangshan_ZS_Close()

	this:Hide()

end

--=========
-- 重置
--=========
function QianLijiangshan_ZS_On_ResetPos()

	QianLijiangshan_ZS_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function QianLijiangshan_ZS_Open()

	local activeCount = 0
	
	-- 图标+动画
	for nIndex=1, g_MaxCount do
		-- 图标
		if QianLijiangshan_ZS_GetActiveFlag(nIndex) == 1 then
			activeCount = activeCount + 1
			-- 已激活
			g_PicImages[nIndex]:Show()
			-- 需要小红点
			g_RedPoints[nIndex]:Show()
			--动画
			if QianLijiangshan_ZS_GetAnimateFlag(nIndex) == 1 then
				-- 不需要播放
				g_Animates[nIndex]:Play(false)
			else
				-- 需要播放
				g_Animates[nIndex]:Play(true)
				-- 已播放
				QianLijiangshan_ZS_OnAnimate( nIndex )
			end
		else
			-- 未激活
			g_PicImages[nIndex]:Hide()
			-- 不需要小红点
			g_RedPoints[nIndex]:Hide()
			-- 不需要播放动画
			g_Animates[nIndex]:Play(false)
		end

	end
	
	-- 按钮+小红点
	if Pneuma:GetMF(3020) ~= 1 then
		--按钮
		QianLijiangshan_ZS_Btn:Show()
		QianLijiangshan_ZS_Btn1:Hide()
		--小红点
		if activeCount == g_MaxCount then
			QianLijiangshan_ZS_Tips:Show()
		else
			QianLijiangshan_ZS_Tips:Hide()
		end
	else
		--按钮
		QianLijiangshan_ZS_Btn:Hide()
		QianLijiangshan_ZS_Btn1:Show()
		--小红点
		QianLijiangshan_ZS_Tips:Hide()
	end

end	

--=========
-- 已播放动画
--=========
function QianLijiangshan_ZS_OnAnimate( nIndex )

	if nIndex == nil or nIndex <= 0 or nIndex > g_MaxCount then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAnimate" )
		Set_XSCRIPT_ScriptID( 888331 )
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end

--=========
-- 点击领奖
--=========
function QianLijiangshan_ZS_BtnClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888331 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end

--=========
-- 问号帮助
--=========
function QianLijiangshan_ZS_HelpClick()
	PushEvent("CCSHOP_HELP", 128)
end
	
--=========
-- 某个图标是否已激活
--=========
function QianLijiangshan_ZS_GetActiveFlag(nIndex)

	if nIndex == nil then
		return 0
	end
	
	if nIndex <= 0 or nIndex > g_MaxCount then
		return 0
	end
	
	local bRet, bActive = GetBitValueInUINT(g_MDData, (nIndex-1)*2, 1)
	if bRet ~= 1 or bActive < 0 or bActive > 1 then
		return 0
	end
	
	return bActive
	
end
	
--=========
-- 某个图标是否已播放动画
--=========
function QianLijiangshan_ZS_GetAnimateFlag(nIndex)

	if nIndex == nil then
		return 0
	end
	
	if nIndex <= 0 or nIndex > g_MaxCount then
		return 0
	end
	
	local bRet, bAnimate = GetBitValueInUINT(g_MDData, (nIndex-1)*2+1, 1)
	if bRet ~= 1 or bAnimate < 0 or bAnimate > 1 then
		return 0
	end
	
	return bAnimate
	
end
