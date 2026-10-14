--2021春节时装获得方式

local g_Frame_UnifiedPosition

--图标数量
local g_MaxCount = 4

--4个小玩具激活标记
local g_SpringFestival_Fashion2_Active = {}

--4个小玩具首次标记
local g_SpringFestival_Fashion2_MD

--领奖标记
local g_SpringFestival_Fashion2_MF

--图标按钮
local g_PicImages = {}
--图标动画
local g_Animates = {}
--图标小红点
local g_RedPoints = {}
--tips
--local g_Tips = {}
--=========
-- PreLoad()
--=========
function SpringFestival_Fashion2_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function SpringFestival_Fashion2_OnLoad()
	
	g_Frame_UnifiedPosition = SpringFestival_Fashion2_Frame:GetProperty("UnifiedPosition")
		
	g_SpringFestival_Fashion2_Active[1] = 0
	g_SpringFestival_Fashion2_Active[2] = 0
	g_SpringFestival_Fashion2_Active[3] = 0
	g_SpringFestival_Fashion2_Active[4] = 0
		
	g_SpringFestival_Fashion2_MD = 0
	g_SpringFestival_Fashion2_MF = 0
		
	g_PicImages[1] = SpringFestival_Fashion2_PicBK1
	g_PicImages[2] = SpringFestival_Fashion2_PicBK2
	g_PicImages[3] = SpringFestival_Fashion2_PicBK3
	g_PicImages[4] = SpringFestival_Fashion2_PicBK4
	
	g_Animates[1] = SpringFestival_Fashion2_BK1Animate
	g_Animates[2] = SpringFestival_Fashion2_BK2Animate
	g_Animates[3] = SpringFestival_Fashion2_BK3Animate
	g_Animates[4] = SpringFestival_Fashion2_BK4Animate
	
	g_RedPoints[1] = SpringFestival_Fashion2_BK1Tips
	g_RedPoints[2] = SpringFestival_Fashion2_BK2Tips
	g_RedPoints[3] = SpringFestival_Fashion2_BK3Tips
	g_RedPoints[4] = SpringFestival_Fashion2_BK4Tips

	--g_Tips[1] = "#{CJSZ_211124_12}"
	--g_Tips[2] = "#{CJSZ_211124_13}"
	--g_Tips[3] = "#{CJSZ_211124_14}"
	--g_Tips[4] = "#{CJSZ_211124_15}"
end

--=========
-- Event
--=========
function SpringFestival_Fashion2_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88883801) then
	
		local bShow = Get_XParam_INT(0)
		--打开界面
		if bShow == 1 then
			g_SpringFestival_Fashion2_Active[1] = Get_XParam_INT(1)
			g_SpringFestival_Fashion2_Active[2] = Get_XParam_INT(2)
			g_SpringFestival_Fashion2_Active[3] = Get_XParam_INT(3)
			g_SpringFestival_Fashion2_Active[4] = Get_XParam_INT(4)
			g_SpringFestival_Fashion2_MD = Get_XParam_INT(5)
			g_SpringFestival_Fashion2_MF = Get_XParam_INT(6)
			SpringFestival_Fashion2_Open()
			this:Show()
		--关闭界面
		elseif bShow == 2 then
			SpringFestival_Fashion2_Close()
		--刷新界面
		elseif bShow == 3 then
			if this:IsVisible() then
				g_SpringFestival_Fashion2_Active[1] = Get_XParam_INT(1)
				g_SpringFestival_Fashion2_Active[2] = Get_XParam_INT(2)
				g_SpringFestival_Fashion2_Active[3] = Get_XParam_INT(3)
				g_SpringFestival_Fashion2_Active[4] = Get_XParam_INT(4)
				g_SpringFestival_Fashion2_MD = Get_XParam_INT(5)
				g_SpringFestival_Fashion2_MF = Get_XParam_INT(6)
				SpringFestival_Fashion2_Open()
			end
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		SpringFestival_Fashion2_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_Fashion2_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		SpringFestival_Fashion2_On_ResetPos()

	end
	
end

--=========
-- Close
--=========
function SpringFestival_Fashion2_Close()

	this:Hide()

end

--=========
-- 重置
--=========
function SpringFestival_Fashion2_On_ResetPos()

	SpringFestival_Fashion2_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function SpringFestival_Fashion2_Open()

	local activeCount = 0
	
	-- 图标+动画
	for nIndex=1, g_MaxCount do
		-- 图标
		if g_SpringFestival_Fashion2_Active[nIndex] == 1 then
			activeCount = activeCount + 1
			-- 已激活
			g_PicImages[nIndex]:Show()
			--g_PicImages[nIndex]:SetToolTip("")
			-- 需要小红点
			g_RedPoints[nIndex]:Show()
			--动画
			if SpringFestival_Fashion2_GetAnimateFlag(nIndex) == 1 then
				-- 不需要播放
				g_Animates[nIndex]:Play(false)
			else
				-- 需要播放
				g_Animates[nIndex]:Play(true)
				-- 已播放
				SpringFestival_Fashion2_OnAnimate( nIndex )
			end
		else
			-- 未激活
			g_PicImages[nIndex]:Hide()
			--g_PicImages[nIndex]:SetToolTip(g_Tips[nIndex])
			-- 不需要小红点
			g_RedPoints[nIndex]:Hide()
			-- 不需要播放动画
			g_Animates[nIndex]:Play(false)
		end

	end
	
	-- 按钮+小红点
	if Pneuma:GetMF(3911) ~= 1 then
		--按钮
		SpringFestival_Fashion2_Btn:Show()
		SpringFestival_Fashion2_Btn1:Hide()
		--小红点
		if activeCount == g_MaxCount then
			SpringFestival_Fashion2_Tips:Show()
		else
			SpringFestival_Fashion2_Tips:Hide()
		end
	else
		--按钮
		SpringFestival_Fashion2_Btn:Hide()
		SpringFestival_Fashion2_Btn1:Show()
		--小红点
		SpringFestival_Fashion2_Tips:Hide()
	end

end	

--=============
-- 已播放动画
--=============
function SpringFestival_Fashion2_OnAnimate( nIndex )

	if nIndex == nil or nIndex <= 0 or nIndex > g_MaxCount then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAnimate" )
		Set_XSCRIPT_ScriptID( 888838 )
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end

--=========
-- 点击领奖
--=========
function SpringFestival_Fashion2_BtnClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888838 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end

--=========
-- 问号帮助
--=========
function SpringFestival_Fashion2_HelpClick()
	PushEvent("CCSHOP_HELP", 138)
end
	
--========================
-- 某个图标是否已播放动画
--========================
function SpringFestival_Fashion2_GetAnimateFlag(nIndex)

	if nIndex == nil then
		return 0
	end
	
	if nIndex <= 0 or nIndex > g_MaxCount then
		return 0
	end
	
	local bAnimate = 0
	local MD = g_SpringFestival_Fashion2_MD--DataPool:GetPlayerMission_DataRound(g_SpringFestival_Fashion2_MD)
	local temp = math.mod(MD, 10000)
	if nIndex == 1 then
		bAnimate = math.mod(temp, 10)
	elseif nIndex == 2 then
		bAnimate = math.mod(math.floor(temp/10), 10)
	elseif nIndex == 3 then
		bAnimate = math.mod(math.floor(temp/100), 10)
	elseif nIndex == 4 then
		bAnimate = math.mod(math.floor(temp/1000), 10)
	end
	
	return bAnimate
	
end
