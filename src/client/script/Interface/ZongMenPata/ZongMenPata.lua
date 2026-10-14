--ZongMenPata.lua
--Prize用到的常量
local g_MAX_LEVEL = 100 --最da阶位
local g_MyLevel = -1 --
local g_MyZMLevel = -1 --

--Prize用的全局变量
local g_ZongMenPata_Frame_UnifiedPosition;

local g_IconButton ={}

local g_LevelPrizeinfo = {}

local g_TitleShowItemId = {
	[40] = 39924488,
	[50] = 39924502,
	[60] = 39924503,
	[70] = 39924504,
	[80] = 39924489,
	[90] = 39924490,
	[100] = 39924491,
}

local g_ShengMingShowItemId = {
	[80] = 39924492,
	[100] = 39924493,
}


--===============================================
-- PreLoad()
--===============================================
function ZongMenPata_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
end

--===============================================
-- OnEvent()
--===============================================
function ZongMenPata_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		ZongMenPata_OnClose()
	elseif event == "ADJEST_UI_POS" then
		ZongMenPata_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZongMenPata_OnResetPos()	
	
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633006) then	--服务端传数据
	
		local nMyLevel = Get_XParam_INT(0)	
		local nMyZMLevel = Get_XParam_INT(1)	
		ZongMenPata_Updata(nMyLevel,nMyZMLevel)
		g_MyZMLevel = nMyZMLevel
		g_MyLevel = nMyLevel + 1
		if g_MyLevel > g_MAX_LEVEL then
			g_MyLevel = g_MAX_LEVEL
		end

	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			ZongMenPata_Btn1_BtnTips:Show()
		else
			ZongMenPata_Btn1_BtnTips:Hide()
		end
		
	end
end



function ZongMenPata_OnLoad()
	g_ZongMenPata_Frame_UnifiedPosition = ZongMenPata_Frame:GetProperty("UnifiedPosition")
	g_IconButton[1] = ZongMenPata_Item1
	g_IconButton[2] = ZongMenPata_Item2
	g_IconButton[3] = ZongMenPata_Item3
	g_IconButton[4] = ZongMenPata_Item4
	g_IconButton[5] = ZongMenPata_Item5
	-- g_IconButton[6] = ZongMenPata_Item6
	-- g_IconButton[7] = ZongMenPata_Item7
end


function ZongMenPata_Updata(nMyLevel, nMyZMLevel)
	if nMyLevel < g_MAX_LEVEL then
		nMyLevel = nMyLevel + 1
	end
	local nReward = {-1,-1,-1,-1,-1}
	local nRewardNum = {-1,-1,-1,-1,-1}
	local szBossImage, szSceneImage, szChallengeInfo
	szBossImage, szSceneImage, szChallengeInfo, nReward[1], nReward[2], nReward[3], nReward[4], nReward[5], nRewardNum[1], nRewardNum[2], nRewardNum[3], nRewardNum[4], nRewardNum[5] =  Player:GetZMPTUiInfo(nMyLevel)
	local nZMPTTitleLevel, nZMPTTitleShowItemId =  Player:GetZMPTTitleInfo(nMyLevel)
	ZongMenPata_BossImg:SetProperty("Image", szBossImage)
	ZongMenPata_SceneImg:SetProperty("Image", szSceneImage)
	local bIsShowZMTitle = 0
	local bIsShowTitle = 0
	local bIsShowShengMingTitle = 0
	for i = 1, 5 do
		if i <= 5 and nReward[i] ~= nil and nReward[i] ~= -1 then
			local theAction = nil
			theAction = DataPool:CreateBindActionItemForShow(nReward[i],nRewardNum[i])
			if theAction:GetID() ~= 0  then
				g_IconButton[i]:SetActionItem(theAction:GetID())
				g_IconButton[i]:Show()
			else
				g_IconButton[i]:Hide()
			end
		elseif nZMPTTitleShowItemId ~= -1 and bIsShowZMTitle == 0 then
			local theAction = nil
			theAction = DataPool:CreateBindActionItemForShow(nZMPTTitleShowItemId,1)
			bIsShowZMTitle = 1
			if theAction:GetID() ~= 0  then
				g_IconButton[i]:SetActionItem(theAction:GetID())
				g_IconButton[i]:Show()
			else
				g_IconButton[i]:Hide()
			end
		elseif g_TitleShowItemId[nMyLevel] ~= nil and bIsShowTitle == 0 then
			local theAction = nil
			theAction = DataPool:CreateBindActionItemForShow(g_TitleShowItemId[nMyLevel],1)
			bIsShowTitle = 1
			if theAction:GetID() ~= 0  then
				g_IconButton[i]:SetActionItem(theAction:GetID())
				g_IconButton[i]:Show()
			else
				g_IconButton[i]:Hide()
			end
		elseif g_ShengMingShowItemId[nMyLevel] ~= nil and bIsShowShengMingTitle == 0 then
			local theAction = nil
			theAction = DataPool:CreateBindActionItemForShow(g_ShengMingShowItemId[nMyLevel],1)
			bIsShowShengMingTitle = 1
			if theAction:GetID() ~= 0  then
				g_IconButton[i]:SetActionItem(theAction:GetID())
				g_IconButton[i]:Show()
			else
				g_IconButton[i]:Hide()
			end
		else
			g_IconButton[i]:Hide()
		end
	end
	local szNPCName, nSceneId, PosX, PosZ, nLimitZMLevel = Player:GetZMPTUiGoToInfo(nMyLevel)
	ZongMenPata_Level:SetText(ScriptGlobal_Format("#{ZMPT_230629_138}", nMyLevel, szChallengeInfo))
	if nMyZMLevel < nLimitZMLevel then
		ZongMenPata_Btn2_Text:SetText(ScriptGlobal_Format("#{ZMPT_230629_141}", nLimitZMLevel))
		ZongMenPata_Btn2_Text:Show()
	else
		ZongMenPata_Btn2_Text:Hide()
	end
	this:Show()
end


function ZongMenPata_Help_Clicked()
	-- 借用一下别人的通道
	PushEvent("CCSHOP_HELP", 201)
end

--小红点
function ZongMenPata_UpdateRedPointUI()

end


function ZongMenPata_GoTo()
	if g_MyLevel == -1 then
		return 
	end
	
	local nLevel = Player:GetLevel();
    if nLevel < 60  then        
		PushDebugMessage("#{ZMPT_230629_10}")
		return
    end

	
	local szNPCName, nSceneId, PosX, PosZ, nLimitZMLevel = Player:GetZMPTUiGoToInfo(g_MyLevel)
	if g_MyZMLevel < nLimitZMLevel then
		PushDebugMessage("#{ZMPT_230629_12}")
		return 
	end
	AutoRuntoTargetExWithName(PosX, PosZ, nSceneId, szNPCName)
end

function ZongMenPata_OnHide()
	
end

function ZongMenPata_OpenAward()
	if IsWindowShow("ZongMenPata_Award") then
		CloseWindow("ZongMenPata_Award", true)
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenRewardUI" )
		Set_XSCRIPT_ScriptID( 998633 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


function ZongMenPata_OnClose()
	this:Hide()
	-- if IsWindowShow("ZongMenPata_Award") then
		-- CloseWindow("ZongMenPata_Award", true)
	-- end
end


function ZongMenPata_CloseClicked()
	ZongMenPata_OnClose()
	
end

function ZongMenPata_OnResetPos()
	ZongMenPata_Frame:SetProperty("UnifiedPosition", g_ZongMenPata_Frame_UnifiedPosition)
end

