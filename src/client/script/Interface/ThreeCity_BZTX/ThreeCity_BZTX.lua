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

local g_Str5 = {
	[1] = "#{BZTX_220705_348}", --罗浮烽火石?振奋：%s0
	[2] = "#{BZTX_220705_350}", --潮京烽火石?振奋：%s0
	[3] = "#{BZTX_220705_352}", --钧天烽火石?振奋：%s0
	[4] = "#{BZTX_220705_354}", --罗浮烽火石?复苏：%s0
	[5] = "#{BZTX_220705_356}", --潮京烽火石?复苏：%s0
	[6] = "#{BZTX_220705_358}", --钧天烽火石?复苏：%s0
	[7] = "#{BZTX_220705_385}", --罗浮烽火石?坚韧：%s0
	[8] = "#{BZTX_220705_387}", --潮京烽火石?坚韧：%s0
	[9] = "#{BZTX_220705_389}", --钧天烽火石?坚韧：%s0
}

local g_Str6 = {
	[1] = "#{BZTX_220705_349}", --罗浮烽火石?振奋：无归属
	[2] = "#{BZTX_220705_351}", --潮京烽火石?振奋：无归属
	[3] = "#{BZTX_220705_353}", --钧天烽火石?振奋：无归属
	[4] = "#{BZTX_220705_355}", --罗浮烽火石?复苏：无归属
	[5] = "#{BZTX_220705_357}", --潮京烽火石?复苏：无归属
	[6] = "#{BZTX_220705_359}", --钧天烽火石?复苏：无归属
	[7] = "#{BZTX_220705_386}", --罗浮烽火石?坚韧：无归属
	[8] = "#{BZTX_220705_388}", --潮京烽火石?坚韧：无归属
	[9] = "#{BZTX_220705_390}", --钧天烽火石?坚韧：无归属
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
local g_nCurPage = 1

local g_bIsMyCity1 = 0
local g_bIsMyCity2 = 0
local g_bIsMyCity3 = 0
local g_nJieBeiNum = 0
local g_nKillPoint = 0
local g_ShowMini = 0
local g_IsOpenCityInfo = 1
local g_nCurTime = 0 
local g_IsCityWarOver = 0

local g_nNeedTime = 2700 
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
	[7] = "",
	[8] = "",
	[9] = "",
}
local g_szAssistGuildName = "" 
local g_CityJieBeiName = {}

local g_CityName = {}
local g_CityWatch = {}
local g_CityStatu = {}

local g_CityPage = {}

local g_KillPoint = {
	[1] = {num = 10, points = 225},
	[2] = {num = 25, points = 450},
	[3] = {num = 50, points = 675},
}


-- 超过limit后 没十人加的积分
local g_KillLimit = { 
	[1] = 50, 
	[2] = 100, 
	[3] = 200, 
}

local g_KillLimitPoints = { 
	[1] = 45, 
	[2] = 30,
	[3] = 15,
}

local g_KillLimit1PointsMax = 225
local g_KillLimit2PointsMax = 300
local g_JieBeiPoints = 1500 --
local g_NoCityPointsMax = 1500 --
local g_CommonCityPoints = 1950 --
local g_SuperCityPoints = 2400 --

local g_misData = 0


--GLOBAL_INDEX_CJ = 0 --潮京
--GLOBAL_INDEX_JT = 1 --钧天
--GLOBAL_INDEX_LF = 2 --罗浮

function ThreeCity_BZTX_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	 this:RegisterEvent("SHOWCITYWAR_NORMAL",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
function ThreeCity_BZTX_OnLoad()
	g_Frame_UnifiedXPosition	= ThreeCity_BZTX_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ThreeCity_BZTX_Frame:GetProperty("UnifiedYPosition");
	
	g_bIsMyCity1 = 0
	g_bIsMyCity2 = 0
	g_bIsMyCity3 = 0
	g_nJieBeiNum = 0
	g_nKillPoint = 0
	
	g_CityName[1] = ThreeCity_BZTX_Client2_Text1
	g_CityName[2] = ThreeCity_BZTX_Client2_Text2
	g_CityName[3] = ThreeCity_BZTX_Client2_Text3
	
	g_CityWatch[1] = ThreeCity_BZTX_Client2_djs1
	g_CityWatch[2] = ThreeCity_BZTX_Client2_djs2
	g_CityWatch[3] = ThreeCity_BZTX_Client2_djs3
	
	g_CityStatu[1] = ThreeCity_BZTX_Client2_Text4
	g_CityStatu[2] = ThreeCity_BZTX_Client2_Text5
	g_CityStatu[3] = ThreeCity_BZTX_Client2_Text6
	
	g_CityJieBeiName[1] = ThreeCity_BZTX_Page2_Text1
	g_CityJieBeiName[2] = ThreeCity_BZTX_Page2_Text2
	g_CityJieBeiName[3] = ThreeCity_BZTX_Page2_Text3
	g_CityJieBeiName[4] = ThreeCity_BZTX_Page3_Text1
	g_CityJieBeiName[5] = ThreeCity_BZTX_Page3_Text2
	g_CityJieBeiName[6] = ThreeCity_BZTX_Page3_Text3
	g_CityJieBeiName[7] = ThreeCity_BZTX_Page4_Text1
	g_CityJieBeiName[8] = ThreeCity_BZTX_Page4_Text2
	g_CityJieBeiName[9] = ThreeCity_BZTX_Page4_Text3
	
	g_CityPage[1] = ThreeCity_BZTX_Page1
	g_CityPage[2] = ThreeCity_BZTX_Page2
	g_CityPage[3] = ThreeCity_BZTX_Page3
	g_CityPage[4] = ThreeCity_BZTX_Page4
	
end

function ThreeCity_BZTX_OnEvent(event)

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
		g_szName[2] = Get_XParam_STR(0)
		g_szName[3] = Get_XParam_STR(1)
		g_szName[1] = Get_XParam_STR(2)
		g_szJieBeiName[1] = Get_XParam_STR(7)
		g_szJieBeiName[2] = Get_XParam_STR(3)
		g_szJieBeiName[3] = Get_XParam_STR(5)
		g_szJieBeiName[4] = Get_XParam_STR(8)
		g_szJieBeiName[5] = Get_XParam_STR(4)
		g_szJieBeiName[6] = Get_XParam_STR(6)
		g_szJieBeiName[7] = Get_XParam_STR(11)
		g_szJieBeiName[8] = Get_XParam_STR(9)
		g_szJieBeiName[9] = Get_XParam_STR(10)
		g_szAssistGuildName = Get_XParam_STR(12)
		ThreeCity_BZTX_UpdataCityInfo()
		ThreeCity_BZTX_UpdataPage(g_nCurPage)
		if g_IsOpenCityInfo == 1 then
			ThreeCity_BZTX_Client2:Show()
			ThreeCity_BZTX_xiao_Btn_BK:Hide()
		end
		g_IsCityWarOver = 0
		if bIsOpenUI == 0 then 
			this:Show()
			ThreeCity_BZTX_Image:Show()
			ThreeCity_BZTX_Close:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99816302 then	
		local nCityWarMode = Get_XParam_INT(0)
		local misData = DataPool:GetPlayerMission_DataRound(3216)
		if (misData == 2 and misData ~= nCityWarMode) or (misData ~= 2 and nCityWarMode == 2 ) then
			return 0
		end
		 ThreeCity_BZTX_UpdataCityInfoForEnd()
		 g_IsCityWarOver = 1
		 ThreeCity_BZTX_Image:Hide()
		 ThreeCity_BZTX_Close:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		local curSceneID = GetSceneID(); --
		if IsInTServer() ~= 1 or g_IsCityWarOver == 1 then
			this:Hide()
			g_IsOpenCityInfo = 1
			ThreeCity_BZTX_Client2:Show()
			ThreeCity_BZTX_xiao_Btn_BK:Hide()
			g_nCurPage = 1
		end
	elseif( event == "ADJEST_UI_POS" ) then
		ThreeCity_BZTX_ResetPos()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ThreeCity_BZTX_ResetPos()	
	end
end



function ThreeCity_BZTX_UpdataCityInfo()
	
	for i = 1, table.getn(g_CityName) do
		if g_szName[i] ~= nil and g_szName[i] ~= "" then
			if g_szAssistGuildName ~= "" and g_szAssistGuildName == g_szName[i] then
				g_szName[i] = g_szName[i].."#{GCQH_240429_245}"
				g_CityName[i]:SetToolTip("#{GCQH_240429_246}")
			else
				g_CityName[i]:SetToolTip("")
			end
			g_CityName[i]:SetText(ScriptGlobal_Format(g_Str3[i],g_szName[i])) --被那个帮占了
			if g_nCurTime - g_nStartTime[i] >= g_nNeedTime then
				g_CityStatu[i]:SetText("#{BZTX_220705_324}")
				g_CityStatu[i]:Show()
				g_CityWatch[i]:Hide()
			else
				g_CityWatch[i]:SetProperty("Timer", tostring(g_nNeedTime + g_nStartTime[i] - g_nCurTime))
				g_CityWatch[i]:Show()
				g_CityStatu[i]:Hide()
			end
		else
			g_CityName[i]:SetText(g_Str4[i]) --无归属
			g_CityWatch[i]:Hide()
			g_CityStatu[i]:Hide()	
		end
	end	
	
	for i = 1, table.getn(g_CityJieBeiName) do
		if g_szJieBeiName[i] ~= nil and g_szJieBeiName[i] ~= "" then
			if g_szAssistGuildName ~= "" and g_szAssistGuildName == g_szJieBeiName[i] then
				g_szJieBeiName[i] = g_szJieBeiName[i].."#{GCQH_240429_245}"
				g_CityJieBeiName[i]:SetToolTip("#{GCQH_240429_246}")
			else
				g_CityJieBeiName[i]:SetToolTip("")
			end
			g_CityJieBeiName[i]:SetText(ScriptGlobal_Format(g_Str5[i],g_szJieBeiName[i])) --被那个帮占了
		else
			g_CityJieBeiName[i]:SetText(g_Str6[i]) --无归属
		end
	end	
	
	if g_bIsMyCity1 == 0 and g_bIsMyCity2 == 0 and g_bIsMyCity3 == 0 then
		ThreeCity_BZTX_xiao_Btn:SetText("#{BZTX_220705_334}")
	else
		local nMark = 0
		local nList = {}
		local szStr = ""
		if g_bIsMyCity1 == 1 then
			nMark = nMark + 1
			nList[nMark] = 1
		end
		if g_bIsMyCity2 == 1 then
			nMark = nMark + 1
			nList[nMark] = 2
		end
		if g_bIsMyCity3 == 1 then
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
		ThreeCity_BZTX_xiao_Btn:SetText(ScriptGlobal_Format("#{BZTX_220705_335}",szStr))
	end
end

function ThreeCity_BZTX_UpdataCityInfoForEnd()
	
	for i = 1, table.getn(g_CityName) do
		if g_szName[i] ~= nil and g_szName[i] ~= "" then
			g_CityName[i]:SetText(ScriptGlobal_Format(g_Str3[i],g_szName[i])) --被那个帮占了
			g_CityStatu[i]:SetText("#{BZTX_220705_324}")
			g_CityStatu[i]:Show()
			g_CityWatch[i]:Hide()
		else
			g_CityName[i]:SetText(g_Str4[i]) --无归属
			g_CityWatch[i]:Hide()
			g_CityStatu[i]:Hide()	
		end
	end	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ThreeCity_BZTX_ResetPos()
	ThreeCity_BZTX_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ThreeCity_BZTX_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end



function ThreeCity_BZTX_HelpClick2()
	PushEvent("CCSHOP_HELP", 174)
end


--================================================
--打开城市占领小界面
--================================================
function ThreeCity_BZTX_OpenCityInfo()
	if g_IsOpenCityInfo == 0 then
		ThreeCity_BZTX_Client2:Show()
		ThreeCity_BZTX_xiao_Btn_BK:Hide()
		g_IsOpenCityInfo = 1
	else
		ThreeCity_BZTX_Client2:Hide()
		ThreeCity_BZTX_xiao_Btn_BK:Show()
		if g_bIsMyCity1 == 0 and g_bIsMyCity2 == 0 and g_bIsMyCity3 == 0 then
			ThreeCity_BZTX_xiao_Btn:SetText("#{BZTX_220705_334}")
		else
			local nMark = 0
			local nList = {}
			local szStr = ""
			if g_bIsMyCity1 == 1 then
				nMark = nMark + 1
				nList[nMark] = 1
			end
			if g_bIsMyCity2 == 1 then
				nMark = nMark + 1
				nList[nMark] = 2
			end
			if g_bIsMyCity3 == 1 then
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
			ThreeCity_BZTX_xiao_Btn:SetText(ScriptGlobal_Format("#{BZTX_220705_335}",szStr))
		end
		g_IsOpenCityInfo = 0
	end
end

function ThreeCity_BZTX_CloseWindow()
	g_nCurPage = 1
	this:Hide()
end

function ThreeCity_BZTX_UpdataPage(nPage)

	if nPage < 0 or nPage > 4 then
		return 
	end
	
	for i = 1, table.getn(g_CityPage) do
		if i == nPage then
			g_CityPage[i]:Show()
		else
			g_CityPage[i]:Hide()
		end
	end
	ThreeCity_BZTX_MadeAmount:SetText(ScriptGlobal_Format("#{BZTX_220705_347}",nPage))
	ThreeCity_BZTX_More:Enable()
	ThreeCity_BZTX_Decrease:Enable()
	if nPage == 4 then
		ThreeCity_BZTX_More:Disable()
	elseif nPage == 1 then
		ThreeCity_BZTX_Decrease:Disable()
	end
end

function ThreeCity_BZTX_Minus_Clicked()

	if g_nCurPage <= 1 or g_nCurPage > 4 then
		return
	end
	g_nCurPage = g_nCurPage - 1
	ThreeCity_BZTX_UpdataPage(g_nCurPage)
	
end

function ThreeCity_BZTX_Add_Clicked()

	if g_nCurPage < 1 or g_nCurPage >= 4 then
		return
	end
	g_nCurPage = g_nCurPage + 1
	ThreeCity_BZTX_UpdataPage(g_nCurPage)
	
end


