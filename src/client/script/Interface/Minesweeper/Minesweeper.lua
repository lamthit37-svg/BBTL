--扫雷大界面
-- !!!reloadscript =Minesweeper
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local m_XianSuoDataWuBaoZang = 
{
	[1] ={desc="#{BHSL_210715_47}", desc1="#{BHSL_210715_57}"},
	[2] ={desc="#{BHSL_210715_59}", desc1="#{BHSL_210715_49}"},
}

local m_SceneMapBaoZangPosData = { }				-- 地图上随机的宝藏点 和地图一一对应
m_SceneMapBaoZangPosData[1] = 
{
	{52,62},{43,112},{35,181},{49,225},{54,271},{118,58},{75,94},{93,129},{76,175},{142,124},
	{125,192},{107,242},{160,264},{97,219},{245,116},{190,97},{234,42},{269,50},{240,75},{270,124},
	{274,168},{232,173},{137,241},{227,264},{267,266},
}
m_SceneMapBaoZangPosData[2] = 
{
	{52,62},{43,112},{35,181},{49,225},{54,271},{118,58},{75,94},{93,129},{76,175},{142,124},
	{125,192},{107,242},{160,264},{97,219},{245,116},{190,97},{234,42},{269,50},{240,75},{270,124},
	{274,168},{232,173},{137,241},{227,264},{267,266},
}
m_SceneMapBaoZangPosData[3] = 
{
	{52,62},{43,112},{35,181},{49,225},{54,271},{118,58},{75,94},{93,129},{76,175},{142,124},
	{125,192},{107,242},{160,264},{97,219},{245,116},{190,97},{234,42},{269,50},{240,75},{270,124},
	{274,168},{232,173},{137,241},{227,264},{267,266},
}
m_SceneMapBaoZangPosData[4] = 
{
	{52,62},{43,112},{35,181},{49,225},{54,271},{118,58},{75,94},{93,129},{76,175},{142,124},
	{125,192},{107,242},{160,264},{97,219},{245,116},{190,97},{234,42},{269,50},{240,75},{270,124},
	{274,168},{232,173},{137,241},{227,264},{267,266},
}
m_SceneMapBaoZangPosData[5] = 
{
	{52,62},{43,112},{35,181},{49,225},{54,271},{118,58},{75,94},{93,129},{76,175},{142,124},
	{125,192},{107,242},{160,264},{97,219},{245,116},{190,97},{234,42},{269,50},{240,75},{270,124},
	{274,168},{232,173},{137,241},{227,264},{267,266},
}
local m_WaJueHaveValidR = 9 
local m_BaoZangRoundDiKuaiR = 4900 

local m_BaoZangUIList = {}
local m_BaoZangXianSuoUIList = {}

local m_curSelectBaoZangIndex = 1


local m_ConfirmButtonState = 1

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Minesweeper_PreLoad()
	-- this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("GUILDSAOLEI_OP")
	this:RegisterEvent("UPDATE_MAP",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Minesweeper_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= Minesweeper_FrameNULL:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= Minesweeper_FrameNULL:GetProperty("UnifiedYPosition");

	m_BaoZangUIList = {}
	for i = 1, 25 do
		m_BaoZangUIList[i] = {}
		m_BaoZangUIList[i].Button = _G["Minesweeper_Button"..i]
		m_BaoZangUIList[i].BK = _G["Minesweeper_Button"..i.."_BK"]
		m_BaoZangUIList[i].ShowImage = _G["Minesweeper_Button"..i.."_Show"]
		m_BaoZangUIList[i].Animate = _G["Minesweeper_Button"..i.."_Animate"]
		m_BaoZangUIList[i].BaoXiang = _G["Minesweeper_Button"..i.."_Baoxiang"]
	end
	m_BaoZangXianSuoUIList[1] = Minesweeper_Clue1
	m_BaoZangXianSuoUIList[2] = Minesweeper_Clue2

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Minesweeper_ResetPos()
	Minesweeper_FrameNULL:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	Minesweeper_FrameNULL:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Minesweeper_OnEvent(event)

	-- if( event == "UI_COMMAND" and tonumber(arg0) == 89319402) then
	-- 	local opType = Get_XParam_INT(0)
	-- 	if opType == 1 then --

	-- 	end
	if (event == "GUILDSAOLEI_OP") then
		local opType = tonumber(arg0)
		if opType == 1 then--进入场景要显示界面
			if (this:IsVisible()) then
				return
			end
			m_curSelectBaoZangIndex = 1
			Minesweeper_Show()
			Minesweeper_Update()
		elseif opType == 1000 then -- 或者关闭小界面打开大界面
			if (this:IsVisible()) then
				return
			end
			Minesweeper_Show()
			Minesweeper_Update()
		elseif opType == 2 then 
			if (this:IsVisible()) then
				local nBaoZangIndex = tonumber(arg1)
				-- PushDebugMessage("Minesweeper_UpdateBaoZang "..nBaoZangIndex)
				Minesweeper_UpdateXianSuo(nBaoZangIndex)
				Minesweeper_UpdateBaoZang(nBaoZangIndex)
			end
		elseif opType == 3 then 
			if (this:IsVisible()) then
				local nBaoZangIndex = tonumber(arg1)
				-- PushDebugMessage("Minesweeper_UpdateXianSuo "..nBaoZangIndex)
				Minesweeper_UpdateXianSuo(nBaoZangIndex)
				Minesweeper_UpdateBaoZang(nBaoZangIndex)
			end
		end
	elseif ( event == "UPDATE_MAP") then 
		if (this:IsVisible()) then
			Minesweeper_UpdateConfirmButtonState()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		local sceneLogicID = GetSceneID()
		if sceneLogicID == 839 then
			return
		end
		Minesweeper_Hide()
	elseif event == "ADJEST_UI_POS" then
		Minesweeper_ResetPos()
	end
end

--显示UI
function Minesweeper_Show()
	Minesweeper_ClearData()
	this:Show()
	
end
--隐藏UI
function Minesweeper_Hide()
	Minesweeper_ClearData()

	this:Hide()
end

--清除数据
function Minesweeper_ClearData()
end
--更新
function Minesweeper_Update()
	local mapIndex = GuildActValueUI:LuaFnGetGuildSaoLeiMapIndex()
	if nil == m_SceneMapBaoZangPosData[mapIndex] then
		return
	end
	local baoZangPosData = m_SceneMapBaoZangPosData[mapIndex]
	for nBaoZangIndex = 1, table.getn(baoZangPosData) do
		Minesweeper_UpdateBaoZang(nBaoZangIndex)
	end
	Minesweeper_SetButtonState(m_curSelectBaoZangIndex)
end

function Minesweeper_UpdateBaoZang(nBaoZangIndex)
	if nil == m_BaoZangUIList[nBaoZangIndex] then
		return
	end
	local waJueNum = 0
	local isWaJueBaoZang = 0
	local isFindKeyXianSuo = 0
	local isHaveXianSuo = 0
	local xianSuoMaxNum = GuildActValueUI:LuaFnGetBaoZangPosXianSuoMaxNum()
	for xianSuoIndex = 1, xianSuoMaxNum do
		local xianSuoType, xianSuoParam, _waJueNum, _isWaJueBaoZang  = GuildActValueUI:LuaFnGetGuildSaoLeiXianSuoData(nBaoZangIndex, xianSuoIndex - 1)
		if nil ~= xianSuoType and xianSuoType > 0 and nil ~= m_XianSuoDataWuBaoZang[xianSuoType] then
			if xianSuoType == 1 then
				isFindKeyXianSuo = 1
				isWaJueBaoZang = _isWaJueBaoZang
				waJueNum = _waJueNum
			end
			isHaveXianSuo = 1
		end
	end
	m_BaoZangUIList[nBaoZangIndex].BaoXiang:Hide()
	if isFindKeyXianSuo == 1 and waJueNum > 0 then
		m_BaoZangUIList[nBaoZangIndex].BaoXiang:Show()
		if isWaJueBaoZang == 1 then
			m_BaoZangUIList[nBaoZangIndex].BaoXiang:SetProperty("Image", "set:Saolei image:saolei_baoxiang_open")
		else
			m_BaoZangUIList[nBaoZangIndex].BaoXiang:SetProperty("Image", "set:Saolei image:saolei_baoxiang_close")
		end
	end
	if isHaveXianSuo == 1 then
		m_BaoZangUIList[nBaoZangIndex].BK:SetProperty("Image", "set:Saolei image:saolei_dingwei2_normal")
	else
		m_BaoZangUIList[nBaoZangIndex].BK:SetProperty("Image", "set:Saolei image:saolei_dingwei1_normal")
	end
end

function Minesweeper_UpdateXianSuo(nBaoZangIndex)
	if m_curSelectBaoZangIndex ~= nBaoZangIndex then
		return
	end
	local diKuaiNum = Minesweeper_CalWaJuePosRoundDiKuai()
	local xianSuoUIIndex = 0
	local xianSuoMaxNum = GuildActValueUI:LuaFnGetBaoZangPosXianSuoMaxNum()
	for xianSuoIndex = 1, xianSuoMaxNum do
		local xianSuoType, xianSuoParam, waJueNum, isWaJueBaoZang = GuildActValueUI:LuaFnGetGuildSaoLeiXianSuoData(m_curSelectBaoZangIndex, xianSuoIndex - 1)
		if nil ~= xianSuoType and xianSuoType > 0 and nil ~= m_XianSuoDataWuBaoZang[xianSuoType] then
			xianSuoUIIndex = xianSuoUIIndex + 1
			if nil ~= m_BaoZangXianSuoUIList[xianSuoUIIndex] then
				local str = ""
				if xianSuoType == 1 then
					if waJueNum > 0 then
						if isWaJueBaoZang == 1 then
							str = "#{BHSL_210715_58}"
						else
							str = m_XianSuoDataWuBaoZang[xianSuoType].desc1
						end
					else
						str = m_XianSuoDataWuBaoZang[xianSuoType].desc
					end
				elseif xianSuoType == 2 then
					if xianSuoParam > 0 then
						str = ScriptGlobal_Format(m_XianSuoDataWuBaoZang[xianSuoType].desc1, diKuaiNum, xianSuoParam)
					else
						str = ScriptGlobal_Format(m_XianSuoDataWuBaoZang[xianSuoType].desc, diKuaiNum)
					end
				end
				m_BaoZangXianSuoUIList[xianSuoUIIndex]:SetText(str)
			end
		end
	end
	for nIndex = xianSuoUIIndex + 1, table.getn(m_BaoZangXianSuoUIList) do
		m_BaoZangXianSuoUIList[nIndex]:SetText("#{BHSL_210715_51}")
	end
	for index = 1, table.getn(m_BaoZangUIList) do
		if m_curSelectBaoZangIndex == index then
			if xianSuoUIIndex > 0 then
				m_BaoZangUIList[index].Animate:SetProperty("Animate", "Saolei_Animate2")
			else
				m_BaoZangUIList[index].Animate:SetProperty("Animate", "Saolei_Animate1")
			end
			m_BaoZangUIList[index].Animate:Play(true)
		else
			m_BaoZangUIList[index].Animate:Play(false)
		end
	end

end
function Minesweeper_SetButtonState(nSelectindex)
	m_curSelectBaoZangIndex = nSelectindex
	for index = 1, table.getn(m_BaoZangUIList) do
		m_BaoZangUIList[index].Button:SetCheck(0)
	end
	Minesweeper_UpdateXianSuo(m_curSelectBaoZangIndex)
	Minesweeper_UpdateConfirmButtonState()
	Minesweeper_RefreshWaJuePosRoundDiKuaiUI()
end


function Minesweeper_UpdateConfirmButtonState()
	local mapIndex = GuildActValueUI:LuaFnGetGuildSaoLeiMapIndex()
	if nil == m_SceneMapBaoZangPosData[mapIndex] then
		return
	end
	local baoZangPosData = m_SceneMapBaoZangPosData[mapIndex]
	if nil == baoZangPosData[m_curSelectBaoZangIndex] then
		return
	end
	local posX = baoZangPosData[m_curSelectBaoZangIndex][1]
	local posZ = baoZangPosData[m_curSelectBaoZangIndex][2]
	local myPosx, myPosz, _ = Target:GetMyPos()
	myPosx = math.floor(myPosx)
	myPosz = math.floor(myPosz)
	local curR = (posX - myPosx)*(posX - myPosx) + (posZ - myPosz)*(posZ - myPosz)
	if curR <= m_WaJueHaveValidR then
		m_ConfirmButtonState = 2 --挖掘
		Minesweeper_ConfirmButton:Hide()
		Minesweeper_XunshiButton:Show()
	else
		m_ConfirmButtonState = 1 --前往查看
		Minesweeper_ConfirmButton:Show()
		Minesweeper_XunshiButton:Hide()
	end
end
--**********************************
--检测当前地块位置周围有多少个地块
--**********************************
function Minesweeper_CalWaJuePosRoundDiKuai()
	local diKuaiNum = 0
	local mapIndex = GuildActValueUI:LuaFnGetGuildSaoLeiMapIndex()
	if nil == m_SceneMapBaoZangPosData[mapIndex] then
		return 0
	end
	local baoZangPosData = m_SceneMapBaoZangPosData[mapIndex]
	if nil == baoZangPosData[m_curSelectBaoZangIndex] then
		return 0
	end
	local waJuePosX = baoZangPosData[m_curSelectBaoZangIndex][1]
	local waJuePosY = baoZangPosData[m_curSelectBaoZangIndex][2]
	for index = 1, table.getn(baoZangPosData) do
		local posX = baoZangPosData[index][1]
		local posY = baoZangPosData[index][2]
		local curR = (posX - waJuePosX)*(posX - waJuePosX) + (posY - waJuePosY)*(posY - waJuePosY)
		if m_curSelectBaoZangIndex ~= index then
			if curR <= m_BaoZangRoundDiKuaiR then
				diKuaiNum = diKuaiNum + 1
			end
		end
	end
	return diKuaiNum
end
--**********************************
--刷新当前地块位置周围有多少个地块UI
--**********************************
function Minesweeper_RefreshWaJuePosRoundDiKuaiUI()
	local mapIndex = GuildActValueUI:LuaFnGetGuildSaoLeiMapIndex()
	if nil == m_SceneMapBaoZangPosData[mapIndex] then
		return 0
	end
	local baoZangPosData = m_SceneMapBaoZangPosData[mapIndex]
	if nil == baoZangPosData[m_curSelectBaoZangIndex] then
		return 0
	end
	for index = 1, table.getn(m_BaoZangUIList) do
		m_BaoZangUIList[index].ShowImage:Hide()
	end
	if nil ~= m_BaoZangUIList[m_curSelectBaoZangIndex] then
		m_BaoZangUIList[m_curSelectBaoZangIndex].ShowImage:Show()
	end
	local waJuePosX = baoZangPosData[m_curSelectBaoZangIndex][1]
	local waJuePosY = baoZangPosData[m_curSelectBaoZangIndex][2]
	for index = 1, table.getn(baoZangPosData) do
		local posX = baoZangPosData[index][1]
		local posY = baoZangPosData[index][2]
		local curR = (posX - waJuePosX)*(posX - waJuePosX) + (posY - waJuePosY)*(posY - waJuePosY)
		if m_curSelectBaoZangIndex ~= index then
			if curR <= m_BaoZangRoundDiKuaiR and nil ~= m_BaoZangUIList[index] then
				m_BaoZangUIList[index].ShowImage:Show()
			end
		end
	end
end
--##############点击事件##############
function Minesweeper_CloseWindow()
	PushEvent("GUILDSAOLEI_OP", 1001)
	Minesweeper_Hide()
end
function Minesweeper_ButtonOnClick(nIndex)
	-- PushDebugMessage(nIndex)
	if m_curSelectBaoZangIndex == nSelectindex then
		return
	end
	Minesweeper_SetButtonState(nIndex)
end
function Minesweeper_ConfirmButtonOnClick()
	if m_ConfirmButtonState == 1 then --前往查看
		local mapIndex = GuildActValueUI:LuaFnGetGuildSaoLeiMapIndex()
		if nil == m_SceneMapBaoZangPosData[mapIndex] then
			return
		end
		local baoZangPosData = m_SceneMapBaoZangPosData[mapIndex]
		if nil == baoZangPosData[m_curSelectBaoZangIndex] then
			return
		end
		local posX = baoZangPosData[m_curSelectBaoZangIndex][1]
		local posZ = baoZangPosData[m_curSelectBaoZangIndex][2]
		AutoRunToTarget(posX, posZ)
	elseif m_ConfirmButtonState == 2 then --挖掘
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("StartWaJueBaoZaong")
			Set_XSCRIPT_ScriptID( 888478 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end
--####################################