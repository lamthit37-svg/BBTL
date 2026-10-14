--******************************************************************************
-- 入口界面
--******************************************************************************
local g_ThreeCity_SaveTree_Frame_UnifiedXPosition;
local g_ThreeCity_SaveTree_Frame_UnifiedYPosition;

local g_ThreeCity_SaveTree_HuoyueNeed = {50,150,450}
local g_ThreeCity_SaveTree_HuoyueNeed_KJ = {50,150,450}

--NPC
local g_ThreeCity_SaveTree_NPCPosX = 286
local g_ThreeCity_SaveTree_NPCPosZ = 337
local g_ThreeCity_SaveTree_Name = "姜幻"

--UI
local g_ThreeCity_SaveTree_HuoyueBtn = {}
local g_ThreeCity_SaveTree_HuoyueBtnTips = {}
local g_ThreeCity_SaveTree_HuoyueBtnMark = {}
local g_ThreeCity_SaveTree_HuoyueBtnLock = {}
local g_ThreeCity_SaveTree_HuoyueBtnLight = {}
local g_ThreeCity_SaveTree_ActBtn = ""
local g_ThreeCity_SaveTree_CurDaibi = ""

--===============================================
-- OnLoad()
--===============================================
function ThreeCity_SaveTree_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function ThreeCity_SaveTree_OnLoad()

	-- 保存界面的默认相对位置
	g_ThreeCity_SaveTree_Frame_UnifiedXPosition = ThreeCity_SaveTree_Frame:GetProperty("UnifiedXPosition");
	g_ThreeCity_SaveTree_Frame_UnifiedYPosition = ThreeCity_SaveTree_Frame:GetProperty("UnifiedYPosition");
	g_ThreeCity_SaveTree_HuoyueBtn[1] = ThreeCity_SaveTree_Huoyue1
	g_ThreeCity_SaveTree_HuoyueBtn[2] = ThreeCity_SaveTree_Huoyue2
	g_ThreeCity_SaveTree_HuoyueBtn[3] = ThreeCity_SaveTree_Huoyue3
	g_ThreeCity_SaveTree_HuoyueBtnTips[1] = ThreeCity_SaveTree_Huoyue1_Tips
	g_ThreeCity_SaveTree_HuoyueBtnTips[2] = ThreeCity_SaveTree_Huoyue2_Tips
	g_ThreeCity_SaveTree_HuoyueBtnTips[3] = ThreeCity_SaveTree_Huoyue3_Tips
	g_ThreeCity_SaveTree_HuoyueBtnMark[1] = ThreeCity_SaveTree_Huoyue1_Mark
	g_ThreeCity_SaveTree_HuoyueBtnMark[2] = ThreeCity_SaveTree_Huoyue2_Mark
	g_ThreeCity_SaveTree_HuoyueBtnMark[3] = ThreeCity_SaveTree_Huoyue3_Mark
	g_ThreeCity_SaveTree_HuoyueBtnLock[1] = ThreeCity_SaveTree_Huoyue1_Locked
	g_ThreeCity_SaveTree_HuoyueBtnLock[2] = ThreeCity_SaveTree_Huoyue2_Locked
	g_ThreeCity_SaveTree_HuoyueBtnLock[3] = ThreeCity_SaveTree_Huoyue3_Locked	
	g_ThreeCity_SaveTree_HuoyueBtnLight[1] = ThreeCity_SaveTree_Huoyue1_Light
	g_ThreeCity_SaveTree_HuoyueBtnLight[2] = ThreeCity_SaveTree_Huoyue2_Light
	g_ThreeCity_SaveTree_HuoyueBtnLight[3] = ThreeCity_SaveTree_Huoyue3_Light		
	
	
	g_ThreeCity_SaveTree_ActBtn = ThreeCity_SaveTree_ActButton
	g_ThreeCity_SaveTree_CurDaibi = ThreeCity_SaveTree_Currency	
	
	for i = 1, 3 do
		g_ThreeCity_SaveTree_HuoyueBtnLock[i]:Show()
		g_ThreeCity_SaveTree_HuoyueBtnTips[i]:Hide()
		g_ThreeCity_SaveTree_HuoyueBtnLight[i]:Hide()
		g_ThreeCity_SaveTree_HuoyueBtnMark[i]:Hide()
	end

end


--===============================================
--!!!reloadscript =ThreeCity_SaveTree

-- OnEvent()
--===============================================

function ThreeCity_SaveTree_OnEvent(event)
	if(event == "UI_COMMAND") then
		
		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 99822501 then
			local param1 = Get_XParam_INT(0)  --操作类型
			if param1 == 1 then
				local param2 = Get_XParam_INT(1)  --活跃值
				local param31 = Get_XParam_INT(2)  --领奖状态
				local param32 = Get_XParam_INT(3)  --领奖状态
				local param33 = Get_XParam_INT(4)  --领奖状态
				local param4 = Get_XParam_INT(5)  --代币数量
				ThreeCity_SaveTree_UpdateData(param2, param31, param32, param33, param4)
				this:Show()
			elseif param1 == 2 then
				ThreeCity_SaveTree_FindNPC()
			elseif param1 == 3 then
				local param2 = Get_XParam_INT(1)  --活跃值
				local param31 = Get_XParam_INT(2)  --领奖状态
				local param32 = Get_XParam_INT(3)  --领奖状态
				local param33 = Get_XParam_INT(4)  --领奖状态
				local param4 = Get_XParam_INT(5)  --代币数量
				ThreeCity_SaveTree_UpdateData(param2, param31, param32, param33, param4)
			elseif param1 == 0 then
				ThreeCity_SaveTree_Close()
				return				
			end
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		ThreeCity_SaveTree_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		ThreeCity_SaveTree_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ThreeCity_SaveTree_Close()
	end
end

function ThreeCity_SaveTree_UpdateData(huoyueData, huoyue1, huoyue2, huoyue3, daibiNum)
	local huoyueFlag = {}
	huoyueFlag[1] = huoyue1
	huoyueFlag[2] = huoyue2
	huoyueFlag[3] = huoyue3
	
	for i = 1, 3 do
		if huoyueData >= g_ThreeCity_SaveTree_HuoyueNeed[i] then
			if huoyueFlag[i] ~= nil then
				if huoyueFlag[i] == 0 then
					--待领取态
					g_ThreeCity_SaveTree_HuoyueBtn[i]:Enable()
					g_ThreeCity_SaveTree_HuoyueBtnTips[i]:Show()
					g_ThreeCity_SaveTree_HuoyueBtnMark[i]:Hide()
					g_ThreeCity_SaveTree_HuoyueBtnLock[i]:Hide()
					g_ThreeCity_SaveTree_HuoyueBtnLight[i]:Show()
				else
					--已领取态
					g_ThreeCity_SaveTree_HuoyueBtn[i]:Disable()
					g_ThreeCity_SaveTree_HuoyueBtnTips[i]:Hide()
					g_ThreeCity_SaveTree_HuoyueBtnMark[i]:Show()
					g_ThreeCity_SaveTree_HuoyueBtnLock[i]:Hide()
					g_ThreeCity_SaveTree_HuoyueBtnLight[i]:Show()
				end
			end
		else
			--未激活态
			g_ThreeCity_SaveTree_HuoyueBtn[i]:Disable()
			g_ThreeCity_SaveTree_HuoyueBtnLock[i]:Show()
			g_ThreeCity_SaveTree_HuoyueBtnTips[i]:Hide()
			g_ThreeCity_SaveTree_HuoyueBtnLight[i]:Hide()
			g_ThreeCity_SaveTree_HuoyueBtnMark[i]:Hide()
		end
		
		
	end
	g_ThreeCity_SaveTree_CurDaibi:SetText(ScriptGlobal_Format("#{ZJSS_220803_16}", huoyueData))
end


function ThreeCity_SaveTree_FindNPC(id)
	AutoRuntoTargetExWithName(g_ThreeCity_SaveTree_NPCPosX, g_ThreeCity_SaveTree_NPCPosZ, 0, g_ThreeCity_SaveTree_Name)
	ThreeCity_SaveTree_Close()
end

function ThreeCity_SaveTree_ClickHuoyue(id)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGuideHuoyue")
		Set_XSCRIPT_ScriptID(998225)
		Set_XSCRIPT_Parameter(0,id); 
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


function ThreeCity_SaveTree_ClickActButton(id)	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGuideGoto")
		Set_XSCRIPT_ScriptID(998225)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ThreeCity_SaveTree_Close()
	ThreeCity_SaveTree_OnHiden()
end

function ThreeCity_SaveTree_ClickInfoHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenHelp")
		Set_XSCRIPT_ScriptID(998225)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--===============================================
-- OnHiden
--===============================================
function ThreeCity_SaveTree_OnHiden()

	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ThreeCity_SaveTree_Frame_On_ResetPos()
	ThreeCity_SaveTree_Frame : SetProperty("UnifiedXPosition", g_ThreeCity_SaveTree_Frame_UnifiedXPosition);
	ThreeCity_SaveTree_Frame : SetProperty("UnifiedYPosition", g_ThreeCity_SaveTree_Frame_UnifiedYPosition);
end
