--2022熊猫外观
--时装获得方式

local g_Frame_UnifiedPosition

--图标数量
local g_MaxCount = 4

--4个小玩具激活标记
local g_Panda_Fashion_Active = {}

--4个小玩具首次标记
local g_Panda_Fashion_MD

--领奖标记
local g_Panda_Fashion_MF

--图标按钮
local g_PicImages = {}
--图标动画
local g_Animates = {}
--图标小红点
local g_RedPoints = {}

--=========
-- PreLoad()
--=========
function Panda_Fashion_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function Panda_Fashion_OnLoad()
	
	g_Frame_UnifiedPosition = Panda_Fashion_Frame:GetProperty("UnifiedPosition")
		
	g_Panda_Fashion_Active[1] = 0
	g_Panda_Fashion_Active[2] = 0
	g_Panda_Fashion_Active[3] = 0
	g_Panda_Fashion_Active[4] = 0
		
	g_Panda_Fashion_MD = 0
	g_Panda_Fashion_MF = 0
		
	g_PicImages[1] = Panda_Fashion_PicBK1
	g_PicImages[2] = Panda_Fashion_PicBK2
	g_PicImages[3] = Panda_Fashion_PicBK3
	g_PicImages[4] = Panda_Fashion_PicBK4
	
	g_Animates[1] = Panda_Fashion_BK1Animate
	g_Animates[2] = Panda_Fashion_BK2Animate
	g_Animates[3] = Panda_Fashion_BK3Animate
	g_Animates[4] = Panda_Fashion_BK4Animate
	
	g_RedPoints[1] = Panda_Fashion_BK1Tips
	g_RedPoints[2] = Panda_Fashion_BK2Tips
	g_RedPoints[3] = Panda_Fashion_BK3Tips
	g_RedPoints[4] = Panda_Fashion_BK4Tips

end

--=========
-- Event
--=========
function Panda_Fashion_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88896701) then
	
		local bShow = Get_XParam_INT(0)
		--打开界面
		if bShow == 1 then
			g_Panda_Fashion_Active[1] = Get_XParam_INT(1)
			g_Panda_Fashion_Active[2] = Get_XParam_INT(2)
			g_Panda_Fashion_Active[3] = Get_XParam_INT(3)
			g_Panda_Fashion_Active[4] = Get_XParam_INT(4)
			g_Panda_Fashion_MD = Get_XParam_INT(5)
			g_Panda_Fashion_MF = Get_XParam_INT(6)
			Panda_Fashion_Open()
			this:Show()
		--关闭界面
		elseif bShow == 2 then
			Panda_Fashion_Close()
		--刷新界面
		elseif bShow == 3 then
			if this:IsVisible() then
				g_Panda_Fashion_Active[1] = Get_XParam_INT(1)
				g_Panda_Fashion_Active[2] = Get_XParam_INT(2)
				g_Panda_Fashion_Active[3] = Get_XParam_INT(3)
				g_Panda_Fashion_Active[4] = Get_XParam_INT(4)
				g_Panda_Fashion_MD = Get_XParam_INT(5)
				g_Panda_Fashion_MF = Get_XParam_INT(6)
				Panda_Fashion_Open()
			end
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Panda_Fashion_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Panda_Fashion_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		Panda_Fashion_On_ResetPos()

	end
	
end

--=========
-- Close
--=========
function Panda_Fashion_Close()

	this:Hide()

end

--=========
-- 重置
--=========
function Panda_Fashion_On_ResetPos()

	Panda_Fashion_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function Panda_Fashion_Open()

	local activeCount = 0
	
	-- 图标+动画
	for nIndex=1, g_MaxCount do
		-- 图标
		if g_Panda_Fashion_Active[nIndex] == 1 then
			activeCount = activeCount + 1
			-- 已激活
			g_PicImages[nIndex]:Show()
			-- 需要小红点
			g_RedPoints[nIndex]:Show()
			--动画
			if Panda_Fashion_GetAnimateFlag(nIndex) == 1 then
				-- 不需要播放
				g_Animates[nIndex]:Play(false)
			else
				-- 需要播放
				g_Animates[nIndex]:Play(true)
				-- 已播放
				Panda_Fashion_OnAnimate( nIndex )
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
	if Pneuma:GetMF(3569) ~= 1 then
		--按钮
		Panda_Fashion_Btn:Show()
		Panda_Fashion_Btn1:Hide()
		--小红点
		if activeCount == g_MaxCount then
			Panda_Fashion_Tips:Show()
		else
			Panda_Fashion_Tips:Hide()
		end
	else
		--按钮
		Panda_Fashion_Btn:Hide()
		Panda_Fashion_Btn1:Show()
		--小红点
		Panda_Fashion_Tips:Hide()
	end

end	

--=============
-- 已播放动画
--=============
function Panda_Fashion_OnAnimate( nIndex )

	if nIndex == nil or nIndex <= 0 or nIndex > g_MaxCount then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAnimate" )
		Set_XSCRIPT_ScriptID( 888967 )
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end

--=========
-- 点击领奖
--=========
function Panda_Fashion_BtnClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888967 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end

--=========
-- 问号帮助
--=========
function Panda_Fashion_HelpClick()
	PushEvent("CCSHOP_HELP", 159)
end
	
--========================
-- 某个图标是否已播放动画
--========================
function Panda_Fashion_GetAnimateFlag(nIndex)

	if nIndex == nil then
		return 0
	end
	
	if nIndex <= 0 or nIndex > g_MaxCount then
		return 0
	end
	
	local bAnimate = 0
	local MD = g_Panda_Fashion_MD--DataPool:GetPlayerMission_DataRound(g_Panda_Fashion_MD)
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
