local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_Str1 = {
	[0] = "#{BZTX_220705_180}", --未占领
	[1] = "#{BZTX_220705_219}", --占领
}

local g_Str2 = {
	[1] = "#{BZTX_220705_216}", --潮京
	[2] = "#{BZTX_220705_215}", --钧天
	[3] = "#{BZTX_220705_217}", --罗浮
}

local g_Str3 = {
	[1] = "#{BZTX_220705_318}", --罗浮：%s0
	[2] = "#{BZTX_220705_320}", --潮京：%s0
	[3] = "#{BZTX_220705_322}", --钧天：%s0
}

local g_Str4 = {
	[1] = "#{BZTX_220705_319}", --罗浮：无归属
	[2] = "#{BZTX_220705_321}", --潮京：无归属
	[3] = "#{BZTX_220705_323}", --钧天：无归属
}

local g_JieBeiName = {
	[51143] = "#{BZTX_220705_253}",
	[51144] = "#{BZTX_220705_254}",
	[51145] = "#{BZTX_220705_251}",
	[51146] = "#{BZTX_220705_252}",
	[51147] = "#{BZTX_220705_249}",
	[51148] = "#{BZTX_220705_250}",
	[51191] = "#{BZTX_220705_393}",
	[51192] = "#{BZTX_220705_392}",
	[51193] = "#{BZTX_220705_391}",
}

local g_nJieBeiType = -1

local g_nLastPoints = 0

local g_bIsMyCity1 = 0
local g_bIsMyCity2 = 0
local g_bIsMyCity3 = 0
local g_nJieBeiNum = 0
local g_nKillPoint = 0
local g_ShowMini = 0
local g_IsOpenCityInfo = 1
local g_nCurTime = 0 

local g_bIsBalanceMode = 0
local g_bIsDiBao = 0
local g_bIs89KaJi = 0
local g_bIsTangPing = 0

local g_nNeedTime = 1800 
local g_nStartTime = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
}

local g_szName = {
	[1] = "",
	[2] = "",
	[3] = "",
}

local g_szJieBeiName = {
	[1] = "",
	[2] = "",
	[3] = "",
	[4] = "",
	[5] = "",
	[6] = "",
}

local g_CityName = {}
local g_CityWatch = {}
local g_CityStatu = {}

local g_KillPoint = {
	[1] = {num = 10, points = 225},
	[2] = {num = 25, points = 450},
	[3] = {num = 50, points = 675},
}


-- 超过limit后 没十人加的积分
local g_KillLimit = { 
	[1] = 10, 
	[2] = 30, 
	[3] = 50, 
	[4] = 100, 
	[5] = 150, 
}

local g_KillLimitPoints = { 
	[1] = 30, 
	[2] = 20,
	[3] = 10, 
	[4] = 8,
	[5] = 4,
}

local g_KillLimit1PointsMax = 300
local g_KillLimit2PointsMax = 400
local g_KillLimit3PointsMax = 200
local g_KillLimit4PointsMax = 400
local g_KillLimit5PointsMax = 200

local g_JieBeiPoints = 1500 --
local g_NoCityPointsMax = 1500 --
local g_CommonCityPoints = 1950 --
local g_SuperCityPoints = 2200 --

local g_KillLimitPoints_Sec = { 
	[1] = 24, 
	[2] = 15,
	[3] = 8, 
	[4] = 4,
	[5] = 2,
}

local g_KillLimit1PointsMax_Sec = 240
local g_KillLimit2PointsMax_Sec = 300
local g_KillLimit3PointsMax_Sec = 160
local g_KillLimit4PointsMax_Sec = 200
local g_KillLimit5PointsMax_Sec = 100

local g_JieBeiPoints_Sec = 1000 --
local g_NoCityPointsMax_Sec = 1000 --
local g_CommonCityPoints_Sec = 1500 --
local g_SuperCityPoints_Sec = 1950 --

local g_IsCityWarOver = 0
local g_misData = 0


--GLOBAL_INDEX_CJ = 0 --潮京
--GLOBAL_INDEX_JT = 1 --钧天
--GLOBAL_INDEX_LF = 2 --罗浮

function BaZheTianXia_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	 this:RegisterEvent("SHOWCITYWAR_NORMAL",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD")
end
function BaZheTianXia_OnLoad()
	g_Frame_UnifiedXPosition	= BaZheTianXia_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BaZheTianXia_Frame:GetProperty("UnifiedYPosition");
	
	g_bIsMyCity1 = 0
	g_bIsMyCity2 = 0
	g_bIsMyCity3 = 0
	g_nJieBeiNum = 0
	g_nKillPoint = 0
	g_bIsBalanceMode = 0
	g_bIsDiBao = 0
	g_bIs89KaJi = 0
	g_bIsTangPing = 0
	
	-- g_CityName[1] = BaZheTianXia_Client2_Text1
	-- g_CityName[2] = BaZheTianXia_Client2_Text2
	-- g_CityName[3] = BaZheTianXia_Client2_Text3
	
	-- g_CityWatch[1] = BaZheTianXia_Client2_djs1
	-- g_CityWatch[2] = BaZheTianXia_Client2_djs2
	-- g_CityWatch[3] = BaZheTianXia_Client2_djs3
	
	-- g_CityStatu[1] = BaZheTianXia_Client2_Text4
	-- g_CityStatu[2] = BaZheTianXia_Client2_Text5
	-- g_CityStatu[3] = BaZheTianXia_Client2_Text6
end

function BaZheTianXia_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 99816301 then
		
		local nCityWarMode = Get_XParam_INT(14)
		g_misData = tonumber(Get_XParam_STR(13))
		if (g_misData == 2 and g_misData ~= nCityWarMode) or (g_misData ~= 2 and nCityWarMode == 2 ) then
			return 0
		end
		g_bIsMyCity1 = Get_XParam_INT(0)
		g_bIsMyCity2 = Get_XParam_INT(1)
		g_bIsMyCity3 = Get_XParam_INT(2)
		g_nJieBeiNum = Get_XParam_INT(3)
		g_nKillPoint = Get_XParam_INT(4)
		--天外三城序号
		-- GLOBAL_INDEX_CJ = 0 --潮京
		-- GLOBAL_INDEX_JT = 1 --钧天
		-- GLOBAL_INDEX_LF = 2 --罗浮
		g_nStartTime[2] = Get_XParam_INT(5)--潮京
		g_nStartTime[3] = Get_XParam_INT(6)--钧天
		g_nStartTime[1] = Get_XParam_INT(7)--罗浮
		g_nCurTime = Get_XParam_INT(8)
		g_nJieBeiType = Get_XParam_INT(9)
		local bIsOpenUI = Get_XParam_INT(10)
		g_bIsBalanceMode = Get_XParam_INT(11)
		g_bIsDiBao = Get_XParam_INT(12)
		g_bIs89KaJi = Get_XParam_INT(13)
		g_bIsTangPing = Get_XParam_INT(15)
		
		g_szName[2] = Get_XParam_STR(0)
		g_szName[3] = Get_XParam_STR(1)
		g_szName[1] = Get_XParam_STR(2)
		BaZheTianXia_AnimateUp:Play(false)
		BaZheTianXia_AnimateDown:Play(false)
		
		if g_ShowMini == 0 then
			BaZheTianXia_Updata(g_bIsMyCity1, g_bIsMyCity2, g_bIsMyCity3, g_nJieBeiNum, g_nKillPoint, g_bIsBalanceMode, g_bIsDiBao)
			--BaZheTianXia_UpdataCityInfo()
		else
			BaZheTianXia_Pop_Updata(g_bIsMyCity1, g_bIsMyCity2, g_bIsMyCity3, g_nJieBeiNum, g_nKillPoint, g_bIsBalanceMode, g_bIsDiBao)
		end
		if bIsOpenUI == 0 then
			BaZheTianXia_Close:Hide()
			BaZheTianXia_Image:Show()
			this:Show()
		end
		BaZheTianXia_ShengCheng_Btn:Hide()
		g_IsCityWarOver = 0
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99816302 then
		local nCityWarMode = Get_XParam_INT(0)
		local misData = DataPool:GetPlayerMission_DataRound(3216)
		if (misData == 2 and misData ~= nCityWarMode) or (misData ~= 2 and nCityWarMode == 2 ) then
			return 0
		end
		g_IsCityWarOver = 1
		BaZheTianXia_Close:Show()
		BaZheTianXia_Image:Hide()
		BaZheTianXia_ShengCheng_Btn:Show()
		 --BaZheTianXia_UpdataCityInfoForEnd()
	elseif event == "SHOWCITYWAR_NORMAL" then
		-- g_bIsMyCity1 = tonumber( arg0 )
		-- g_bIsMyCity2 = tonumber( arg1 )
		-- g_bIsMyCity3 = tonumber( arg2 )
		-- g_nJieBeiNum = tonumber( arg3 )
		-- g_nKillPoint = tonumber( arg4 )
		-- BaZheTianXia_Updata(g_bIsMyCity1, g_bIsMyCity2, g_bIsMyCity3, g_nJieBeiNum, g_nKillPoint)
		-- g_ShowMini = 0	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		local curSceneID = GetSceneID(); --
		if IsInTServer() ~= 1 or g_IsCityWarOver == 1 then
			this:Hide()
			g_IsOpenCityInfo = 1
			--BaZheTianXia_Client2:Show()
		end
	elseif( event == "ADJEST_UI_POS" ) then
		BaZheTianXia_ResetPos()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BaZheTianXia_ResetPos()	
	elseif (event == "PLAYER_LEAVE_WORLD") then
		g_nLastPoints = 0
	end
end

function BaZheTianXia_Updata(bIsMyCity1, bIsMyCity2, bIsMyCity3, nJieBeiNum, nKillPoint, bIsBalanceMode, bIsDiBao)
	BaZheTianXia_Info:SetText(ScriptGlobal_Format("#{BZTX_220705_212}",nKillPoint))
	if nJieBeiNum > 0 then
		BaZheTianXia_Client1_Info2:SetText(ScriptGlobal_Format("#{BZTX_220705_172}",g_JieBeiName[g_nJieBeiType]))
	else
		if bIsBalanceMode == 1 and bIsDiBao == 1 then
			BaZheTianXia_Client1_Info2:SetText("#{GCQH_240429_155}")
		else
			BaZheTianXia_Client1_Info2:SetText(ScriptGlobal_Format("#{BZTX_220705_172}","#{BZTX_220705_326}"))
		end
	end
	

	if g_bIs89KaJi == 0 then
		if bIsBalanceMode == 1 and bIsDiBao == 1 then
			BaZheTianXia_Client1_Info2:SetToolTip("#{GCQH_240429_156}")
		else
			if g_bIsTangPing == 0 then
				if g_misData ~= 2 then
					BaZheTianXia_Client1_Info2:SetToolTip("#{BZTX_220705_173}")
				else
					BaZheTianXia_Client1_Info2:SetToolTip("#{BZTX_250507_33}")
				end
			else
				BaZheTianXia_Client1_Info2:SetToolTip("#{BZTX_250506_3}")
			end
		end
	else
		BaZheTianXia_Client1_Info2:SetToolTip("#{TYCZ_240513_54}")
	end
	
	
	local nPoints1 = 0
	if nJieBeiNum > 0 then
		if g_misData ~= 2 then
			nPoints1 = nPoints1 + nJieBeiNum*g_JieBeiPoints
		else
			nPoints1 = nPoints1 + nJieBeiNum*g_JieBeiPoints_Sec
		end
	end
	
	if nKillPoint > 0 then
		
		if g_misData ~= 2 then
			if nKillPoint <= g_KillLimit[1] then
				nPoints1 = nPoints1 + nKillPoint*g_KillLimitPoints[1]
			elseif nKillPoint > g_KillLimit[1] and nKillPoint <= g_KillLimit[2] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[1])*g_KillLimitPoints[2] + g_KillLimit1PointsMax
			elseif nKillPoint > g_KillLimit[2] and nKillPoint <= g_KillLimit[3] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[2])*g_KillLimitPoints[3] + g_KillLimit1PointsMax + g_KillLimit2PointsMax
			elseif nKillPoint > g_KillLimit[3] and nKillPoint <= g_KillLimit[4] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[3])*g_KillLimitPoints[4] + g_KillLimit1PointsMax + g_KillLimit2PointsMax + g_KillLimit3PointsMax
			elseif nKillPoint > g_KillLimit[4] and nKillPoint <= g_KillLimit[5] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[4])*g_KillLimitPoints[5] + g_KillLimit1PointsMax + g_KillLimit2PointsMax + g_KillLimit3PointsMax + g_KillLimit4PointsMax
			elseif nKillPoint > g_KillLimit[5] then
				nPoints1 =  g_KillLimit1PointsMax + g_KillLimit2PointsMax + g_KillLimit3PointsMax + g_KillLimit4PointsMax + g_KillLimit5PointsMax
			end
		else
			if nKillPoint <= g_KillLimit[1] then
				nPoints1 = nPoints1 + nKillPoint*g_KillLimitPoints_Sec[1]
			elseif nKillPoint > g_KillLimit[1] and nKillPoint <= g_KillLimit[2] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[1])*g_KillLimitPoints_Sec[2] + g_KillLimit1PointsMax_Sec
			elseif nKillPoint > g_KillLimit[2] and nKillPoint <= g_KillLimit[3] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[2])*g_KillLimitPoints_Sec[3] + g_KillLimit1PointsMax_Sec + g_KillLimit2PointsMax_Sec
			elseif nKillPoint > g_KillLimit[3] and nKillPoint <= g_KillLimit[4] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[3])*g_KillLimitPoints_Sec[4] + g_KillLimit1PointsMax_Sec + g_KillLimit2PointsMax_Sec + g_KillLimit3PointsMax_Sec
			elseif nKillPoint > g_KillLimit[4] and nKillPoint <= g_KillLimit[5] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[4])*g_KillLimitPoints_Sec[5] + g_KillLimit1PointsMax_Sec + g_KillLimit2PointsMax_Sec + g_KillLimit3PointsMax_Sec + g_KillLimit4PointsMax_Sec
			elseif nKillPoint > g_KillLimit[5] then
				nPoints1 =  g_KillLimit1PointsMax_Sec + g_KillLimit2PointsMax_Sec + g_KillLimit3PointsMax_Sec + g_KillLimit4PointsMax_Sec + g_KillLimit5PointsMax_Sec
			end
		end
		
	end
	
	--平衡模式低保一个界碑
	if bIsMyCity1 == 0 and bIsMyCity2 == 0 and bIsMyCity3 == 0 and nJieBeiNum == 0 and bIsBalanceMode == 1 and bIsDiBao == 1 then
		if g_misData ~= 2 then
			nPoints1 = nPoints1 + nJieBeiNum*g_JieBeiPoints
		else
			nPoints1 = nPoints1 + nJieBeiNum*g_JieBeiPoints_Sec
		end
	end
	
	if g_misData ~= 2 then
		if nPoints1 > g_NoCityPointsMax then
			nPoints1 = g_NoCityPointsMax
		end
	else
		if nPoints1 > g_NoCityPointsMax_Sec then
			nPoints1 = g_NoCityPointsMax_Sec
		end
	end
	
	if bIsMyCity1 == 0 and bIsMyCity2 == 0 and bIsMyCity3 == 0 then
		BaZheTianXia_Client1_Info3:SetText("#{BZTX_220705_218}")
	else
		local nMark = 0
		local nList = {}
		local szStr = ""
		if bIsMyCity1 == 1 then
			nMark = nMark + 1
			nList[nMark] = 1
		end
		if bIsMyCity2 == 1 then
			nMark = nMark + 1
			nList[nMark] = 2
		end
		if bIsMyCity3 == 1 then
			nMark = nMark + 1
			nList[nMark] = 3
		end
		for i = 1, nMark do
			if i == nMark then
				szStr = szStr..g_Str2[nList[nMark]]
			else
				szStr = szStr..g_Str2[nList[nMark]].."#{BZTX_220705_211}"
			end
		end
		BaZheTianXia_Client1_Info3:SetText(ScriptGlobal_Format("#{BZTX_220705_214}",szStr))
	end
	
	if g_bIs89KaJi == 0 then
		if g_bIsTangPing == 0 then
			
			if g_misData ~= 2 then
				BaZheTianXia_Client1_Info3:SetToolTip("#{BZTX_220705_179}")
			else
				BaZheTianXia_Client1_Info3:SetToolTip("#{BZTX_250507_13}")
			end
		else
			BaZheTianXia_Client1_Info3:SetToolTip("#{BZTX_250506_4}")
		end
	else
		BaZheTianXia_Client1_Info3:SetToolTip("#{TYCZ_240513_55}")
	end
	local nPoints = 0
	if bIsMyCity1 == 1 then
		if g_misData ~= 2 then
			nPoints = g_CommonCityPoints 
		else
			nPoints = g_CommonCityPoints_Sec 
		end
	end
	if bIsMyCity2 == 1 then
		if g_misData ~= 2 then
			nPoints = g_CommonCityPoints 
		else
			nPoints = g_CommonCityPoints_Sec 
		end
	end
	if bIsMyCity3 == 1 then
		if g_misData ~= 2 then
			nPoints = g_SuperCityPoints 
		else
			nPoints = g_SuperCityPoints_Sec 
		end
	end
	BaZheTianXia_BangHui_Btn:Hide()
	--BaZheTianXia_ZhanTuan_Btn:Hide()
	if g_bIsTangPing == 0 and g_misData == 1 then
		BaZheTianXia_BangHui_Btn:Show()
		--BaZheTianXia_ZhanTuan_Btn:Show()
	end
	
	local nAddPoints = 0
	if nPoints > nPoints1 then
		
		
		if g_bIs89KaJi == 0 then
			BaZheTianXia_Client1_Over_Text:SetText(ScriptGlobal_Format("#{BZTX_220705_185}",nPoints))
			if g_bIsTangPing == 0 then
				
				if g_misData ~= 2 then
					BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_220705_187}")
				else
					BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_250507_15}")
				end
			else
				BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_250506_7}")
			end
		else
			BaZheTianXia_Client1_Over_Text:SetText(ScriptGlobal_Format("#{TYCZ_240513_13}",nPoints))
			BaZheTianXia_Client1_Over_Text:SetToolTip("#{TYCZ_240513_14}")
		end
		nAddPoints = nPoints
	elseif nJieBeiNum > 0 then
	
		if g_bIs89KaJi == 0 then
			BaZheTianXia_Client1_Over_Text:SetText(ScriptGlobal_Format("#{BZTX_220705_302}",nPoints1))
			if g_bIsTangPing == 0 then
				
				if g_misData ~= 2 then
					BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_220705_303}")
				else
					BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_250507_32}")
				end
			else
				BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_250506_6}")
			end
		else
			BaZheTianXia_Client1_Over_Text:SetText(ScriptGlobal_Format("#{TYCZ_240513_11}",nPoints1))
			BaZheTianXia_Client1_Over_Text:SetToolTip("#{TYCZ_240513_12}")	
		end
		nAddPoints = nPoints1
	else
		if nPoints == 0 and nJieBeiNum == 0 and bIsBalanceMode == 1 and bIsDiBao == 1 then
			
			if g_bIs89KaJi == 0 then
				BaZheTianXia_Client1_Over_Text:SetText(ScriptGlobal_Format("#{BZTX_220705_174}",nPoints1))
				BaZheTianXia_Client1_Over_Text:SetToolTip("#{GCQH_240429_118}")
			else
				BaZheTianXia_Client1_Over_Text:SetText(ScriptGlobal_Format("#{TYCZ_240513_7}",nPoints1))
				BaZheTianXia_Client1_Over_Text:SetToolTip("#{TYCZ_240513_10}")
			end
			nAddPoints = nPoints1
		else
			
			if g_bIs89KaJi == 0 then
				BaZheTianXia_Client1_Over_Text:SetText(ScriptGlobal_Format("#{BZTX_220705_174}",nPoints1))
				if g_bIsTangPing == 0 then
					
					if g_misData ~= 2 then
						BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_220705_176}")
					else
						BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_250507_14}")
					end
				else
					BaZheTianXia_Client1_Over_Text:SetToolTip("#{BZTX_250506_5}")
				end
			else
				BaZheTianXia_Client1_Over_Text:SetText(ScriptGlobal_Format("#{TYCZ_240513_7}",nPoints1))
				BaZheTianXia_Client1_Over_Text:SetToolTip("#{TYCZ_240513_9}")
			end
			nAddPoints = nPoints1
		end
	end
	if g_nLastPoints > nAddPoints then
		BaZheTianXia_AnimateDown:Play(true)
		g_nLastPoints = nAddPoints
	elseif g_nLastPoints < nAddPoints then
		BaZheTianXia_AnimateUp:Play(true)
		g_nLastPoints = nAddPoints
	end

	if g_IsCityWarOver == 0 then
		BaZheTianXia_Close:Hide()
	else
		BaZheTianXia_Image:Show()
	end
	BaZheTianXia_Client:Show()
	BaZheTianXia_Pop_Frame:Hide()
end

function BaZheTianXia_Pop_Updata(bIsMyCity1, bIsMyCity2, bIsMyCity3, nJieBeiNum, nKillPoint, bIsBalanceMode, bIsDiBao)
	
	
	local nPoints1 = 0
	if nJieBeiNum > 0 then
		if g_misData ~= 2 then
			nPoints1 = nPoints1 + nJieBeiNum*g_JieBeiPoints
		else
			nPoints1 = nPoints1 + nJieBeiNum*g_JieBeiPoints_Sec
		end
	end
	
	if nKillPoint > 0 then

		if g_misData ~= 2 then
			if nKillPoint <= g_KillLimit[1] then
				nPoints1 = nPoints1 + nKillPoint*g_KillLimitPoints[1]
			elseif nKillPoint > g_KillLimit[1] and nKillPoint <= g_KillLimit[2] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[1])*g_KillLimitPoints[2] + g_KillLimit1PointsMax
			elseif nKillPoint > g_KillLimit[2] and nKillPoint <= g_KillLimit[3] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[2])*g_KillLimitPoints[3] + g_KillLimit1PointsMax + g_KillLimit2PointsMax
			elseif nKillPoint > g_KillLimit[3] and nKillPoint <= g_KillLimit[4] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[3])*g_KillLimitPoints[4] + g_KillLimit1PointsMax + g_KillLimit2PointsMax + g_KillLimit3PointsMax
			elseif nKillPoint > g_KillLimit[4] and nKillPoint <= g_KillLimit[5] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[4])*g_KillLimitPoints[5] + g_KillLimit1PointsMax + g_KillLimit2PointsMax + g_KillLimit3PointsMax + g_KillLimit4PointsMax
			elseif nKillPoint > g_KillLimit[5] then
				nPoints1 =  g_KillLimit1PointsMax + g_KillLimit2PointsMax + g_KillLimit3PointsMax + g_KillLimit4PointsMax + g_KillLimit5PointsMax
			end
		else
			if nKillPoint <= g_KillLimit[1] then
				nPoints1 = nPoints1 + nKillPoint*g_KillLimitPoints_Sec[1]
			elseif nKillPoint > g_KillLimit[1] and nKillPoint <= g_KillLimit[2] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[1])*g_KillLimitPoints_Sec[2] + g_KillLimit1PointsMax_Sec
			elseif nKillPoint > g_KillLimit[2] and nKillPoint <= g_KillLimit[3] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[2])*g_KillLimitPoints_Sec[3] + g_KillLimit1PointsMax_Sec + g_KillLimit2PointsMax_Sec
			elseif nKillPoint > g_KillLimit[3] and nKillPoint <= g_KillLimit[4] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[3])*g_KillLimitPoints_Sec[4] + g_KillLimit1PointsMax_Sec + g_KillLimit2PointsMax_Sec + g_KillLimit3PointsMax_Sec
			elseif nKillPoint > g_KillLimit[4] and nKillPoint <= g_KillLimit[5] then
				nPoints1 = nPoints1 + (nKillPoint- g_KillLimit[4])*g_KillLimitPoints_Sec[5] + g_KillLimit1PointsMax_Sec + g_KillLimit2PointsMax_Sec + g_KillLimit3PointsMax_Sec + g_KillLimit4PointsMax_Sec
			elseif nKillPoint > g_KillLimit[5] then
				nPoints1 =  g_KillLimit1PointsMax_Sec + g_KillLimit2PointsMax_Sec + g_KillLimit3PointsMax_Sec + g_KillLimit4PointsMax_Sec + g_KillLimit5PointsMax_Sec
			end
		end
		
	end
	
	--平衡模式低保一个界碑
	if bIsMyCity1 == 0 and bIsMyCity2 == 0 and bIsMyCity3 == 0 and nJieBeiNum == 0 and bIsBalanceMode == 1 and bIsDiBao == 1 then
		if g_misData ~= 2 then
			nPoints1 = nPoints1 + nJieBeiNum*g_JieBeiPoints
		else
			nPoints1 = nPoints1 + nJieBeiNum*g_JieBeiPoints_Sec
		end
	end
	
	
	if g_misData ~= 2 then
		if nPoints1 > g_NoCityPointsMax then
			nPoints1 = g_NoCityPointsMax
		end
	else
		if nPoints1 > g_NoCityPointsMax_Sec then
			nPoints1 = g_NoCityPointsMax_Sec
		end
	end
	
	
	local nPoints = 0
	if bIsMyCity1 == 1 then
		if g_misData ~= 2 then
			nPoints = g_CommonCityPoints 
		else
			nPoints = g_CommonCityPoints_Sec 
		end
	end
	if bIsMyCity2 == 1 then
		if g_misData ~= 2 then
			nPoints = g_CommonCityPoints 
		else
			nPoints = g_CommonCityPoints_Sec 
		end
	end
	if bIsMyCity3 == 1 then
		if g_misData ~= 2 then
			nPoints = g_SuperCityPoints 
		else
			nPoints = g_SuperCityPoints_Sec 
		end
	end
	
	
	local nAddPoints = 0
	if nPoints > nPoints1 then

		
		if g_bIs89KaJi == 0 then
			BaZheTianXia_Pop_Client1_Info3:SetText(ScriptGlobal_Format("#{BZTX_220705_185}",nPoints))
			if g_bIsTangPing == 0 then
				
				if g_misData ~= 2 then
					BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_220705_187}")
				else
					BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_250507_15}")
				end
			else
				BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_250506_7}")
			end
		else
			BaZheTianXia_Pop_Client1_Info3:SetText(ScriptGlobal_Format("#{TYCZ_240513_13}",nPoints))
			BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{TYCZ_240513_14}")
		end
		nAddPoints = nPoints
	elseif nJieBeiNum > 0 then
		if g_bIs89KaJi == 0 then
			BaZheTianXia_Pop_Client1_Info3:SetText(ScriptGlobal_Format("#{BZTX_220705_302}",nPoints1))
			if g_bIsTangPing == 0 then
				
				if g_misData ~= 2 then
					BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_220705_303}")
				else
					BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_250507_32}")
				end
			else
				BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_250506_6}")
			end
		else
			BaZheTianXia_Pop_Client1_Info3:SetText(ScriptGlobal_Format("#{TYCZ_240513_11}",nPoints1))
			BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{TYCZ_240513_12}")
		end
		nAddPoints = nPoints1
	else
		if nPoints == 0 and nJieBeiNum == 0 and bIsBalanceMode == 1 and bIsDiBao == 1 then
			
			
			if g_bIs89KaJi == 0 then
				BaZheTianXia_Pop_Client1_Info3:SetText(ScriptGlobal_Format("#{BZTX_220705_174}",nPoints1))
				BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{GCQH_240429_118}")
			else
				BaZheTianXia_Pop_Client1_Info3:SetText(ScriptGlobal_Format("#{TYCZ_240513_7}",nPoints1))
				BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{TYCZ_240513_10}")
			end
			nAddPoints = nPoints1
		else
			
			
			if g_bIs89KaJi == 0 then
				BaZheTianXia_Pop_Client1_Info3:SetText(ScriptGlobal_Format("#{BZTX_220705_174}",nPoints1))
				if g_bIsTangPing == 0 then
					
					if g_misData ~= 2 then
						BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_220705_176}")
					else
						BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_250507_14}")
					end
				else
					BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{BZTX_250506_5}")
				end
			else
				BaZheTianXia_Pop_Client1_Info3:SetText(ScriptGlobal_Format("#{TYCZ_240513_7}",nPoints1))
				BaZheTianXia_Pop_Client1_Info3:SetToolTip("#{TYCZ_240513_9}")
			end
			
			nAddPoints = nPoints1
		end
	end
	if g_nLastPoints > nAddPoints then
		BaZheTianXia_AnimateDown:Play(true)
		g_nLastPoints = nAddPoints
	elseif g_nLastPoints < nAddPoints then
		BaZheTianXia_AnimateUp:Play(true)
		g_nLastPoints = nAddPoints
	end
	
	BaZheTianXia_Client:Hide()
	BaZheTianXia_Pop_Frame:Show()
end



--================================================
-- 恢复界面的默认相对位置
--================================================
function BaZheTianXia_ResetPos()
	BaZheTianXia_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BaZheTianXia_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BaZheTianXia_CloseWindow()
	this:Hide()
end

function BaZheTianXia_Small()
	BaZheTianXia_Pop_Updata(g_bIsMyCity1, g_bIsMyCity2, g_bIsMyCity3, g_nJieBeiNum, g_nKillPoint, g_bIsBalanceMode, g_bIsDiBao)
	g_ShowMini = 1
end

function BaZheTianXia_Pop_Big()
	BaZheTianXia_Updata(g_bIsMyCity1, g_bIsMyCity2, g_bIsMyCity3, g_nJieBeiNum, g_nKillPoint, g_bIsBalanceMode, g_bIsDiBao)
	g_ShowMini = 0
end

function BaZheTianXia_HelpClick()
	PushEvent("CCSHOP_HELP", 169)
end

function BaZheTianXia_HelpClick2()
	PushEvent("CCSHOP_HELP", 174)
end

--================================================
--生成战报按钮
--================================================
function BaZheTianXia_ShareZhanBao()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenZhanBaoUI")
	Set_XSCRIPT_ScriptID(998163)
	Set_XSCRIPT_ParamCount(0)
  Send_XSCRIPT()
end

--================================================
--打开城市占领小界面
--================================================
function BaZheTianXia_OpenCityInfo()
	-- if g_IsOpenCityInfo == 0 then
		-- BaZheTianXia_Client2:Show()
		-- g_IsOpenCityInfo = 1
	-- else
		-- BaZheTianXia_Client2:Hide()
		-- g_IsOpenCityInfo = 0
	-- end
end

function BaZheTianXia_OpenGuildRankList()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenGuildRankList")
	Set_XSCRIPT_ScriptID(998165)
	Set_XSCRIPT_ParamCount(0)
  Send_XSCRIPT()
end