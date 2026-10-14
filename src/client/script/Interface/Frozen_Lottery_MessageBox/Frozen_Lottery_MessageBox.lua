--******************************************
--冰雪舞会抽奖二次确认
--create by  wangsaifei 
--2025-10-19
--******************************************

local g_Frozen_Lottery_MessageBox_Frame_UnifiedPosition;
local g_Frozen_Lottery_MessageBox_data  = -1
local g_Frozen_Lottery_MessageBox_targeId = -1

--===============================================
-- OnLoad()
--===============================================
function Frozen_Lottery_MessageBox_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--===============================================
-- OnLoad()
--===============================================
function Frozen_Lottery_MessageBox_OnLoad()   
	-- 保存界面的默认相对位置
	g_Frozen_Lottery_MessageBox_Frame_UnifiedPosition = Frozen_Lottery_MessageBox_Frame:GetProperty("UnifiedPosition");
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_Lottery_MessageBox_Frame_On_ResetPos()
	Frozen_Lottery_MessageBox_Frame:SetProperty("UnifiedPosition", g_Frozen_Lottery_MessageBox_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Frozen_Lottery_MessageBox_OnEvent(event)
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Frozen_Lottery_MessageBox_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_Lottery_MessageBox_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
		Frozen_Lottery_MessageBox_Cancel_Clicked()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99978003 then
		g_Frozen_Lottery_MessageBox_data = Get_XParam_INT(0)	
		g_Frozen_Lottery_MessageBox_targeId = Get_XParam_INT(1)

		Frozen_Lottery_MessageBox_CheckButton:SetCheck(0)
		local nData ={}
		nData[1] = math.floor( g_Frozen_Lottery_MessageBox_data/1000)
		nData[2] = math.floor( math.mod(g_Frozen_Lottery_MessageBox_data,1000)/100)
		nData[3] = math.floor( math.mod(g_Frozen_Lottery_MessageBox_data,100)/10)
		nData[4] = math.floor( math.mod(g_Frozen_Lottery_MessageBox_data,10))
		local strN = ScriptGlobal_Format("#{WHCJ_251018_75}", nData[1],nData[2],nData[3],nData[4])
		Frozen_Lottery_MessageBox_Text:SetText(strN)
		this:Show()
		Frozen_Lottery_MessageBox_Frame:SetForce()
    end
         
end

--===============================================
-- Frozen_Lottery_MessageBox_OnHide()
--===============================================
function Frozen_Lottery_MessageBox_Cancel_Clicked()
	this:Hide()
end


-- 确定
function Frozen_Lottery_MessageBox_Ok_Clicked()
	local nCheck =	Frozen_Lottery_MessageBox_CheckButton:GetCheck()

	local nConfig = 1
	if nCheck == 1 then
		nConfig = 2
	end
	
	-- 请求舞会抽奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("IcePrizeDrawIng")
		Set_XSCRIPT_ScriptID(999780)
		Set_XSCRIPT_Parameter(0, g_Frozen_Lottery_MessageBox_data)
		Set_XSCRIPT_Parameter(1, g_Frozen_Lottery_MessageBox_targeId)
		Set_XSCRIPT_Parameter(2, nConfig)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	this:Hide()
end

-- 选择
function Frozen_Lottery_MessageBox_CheckButton_Clicked()
end
