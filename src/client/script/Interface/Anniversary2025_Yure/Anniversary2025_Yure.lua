--2025周年庆预热活动

-- 界面的默认相对位置
local g_Anniversary2025_Yure_UnifiedXPosition
local g_Anniversary2025_Yure_UnifiedYPosition

local g_Anniversary2025_Yure_Param1
local g_Anniversary2025_Yure_Param2

function Anniversary2025_Yure_PreLoad()
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("UPDATE_MAP",false)
	this:RegisterEvent("SCENE_TRANSED",false)
end

function Anniversary2025_Yure_OnLoad()
	-- 保存界面的默认相对位置
	g_Anniversary2025_Yure_UnifiedXPosition	= Anniversary2025_Yure_Frame : GetProperty("UnifiedXPosition");
	g_Anniversary2025_Yure_UnifiedYPosition	= Anniversary2025_Yure_Frame : GetProperty("UnifiedYPosition");
	
	g_Anniversary2025_Yure_Param1 = 0
	g_Anniversary2025_Yure_Param2 = 0
	
end

function Anniversary2025_Yure_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99965501 ) then
		
		local nFuncType = Get_XParam_INT(0)
		if nFuncType == 0 then
			Anniversary2025_Yure_Close()
		elseif nFuncType == 1 then
			g_Anniversary2025_Yure_Param1 = Get_XParam_INT(1)
			g_Anniversary2025_Yure_Param2 = Get_XParam_INT(2)
			Anniversary2025_Yure_Update()
			this:Show()
		elseif nFuncType == 2 then
			if( this:IsVisible() ) then
				g_Anniversary2025_Yure_Param1 = Get_XParam_INT(1)
				g_Anniversary2025_Yure_Param2 = Get_XParam_INT(2)			
				Anniversary2025_Yure_Update()
			end
		end
	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99965502 ) then
	
		local nFuncType = Get_XParam_INT(0)
		if nFuncType == 1 then
			Anniversary2025_Yure_RetGotoNpc()
		end
	
	-- 游戏窗口尺寸发生了变化	
	elseif (event == "ADJEST_UI_POS" ) then
		Anniversary2025_Yure_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary2025_Yure_On_ResetPos()
	
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		
	elseif ( event == "SCENE_TRANSED") then 
		this:Hide()
	elseif ( event == "UPDATE_MAP") then 
		if( this:IsVisible() ) then
			Anniversary2025_Yure_Update()
		end
		
	end
end

function Anniversary2025_Yure_Update()

	--完成次数：x/4
	Anniversary2025_Yure_Text:SetText(ScriptGlobal_Format("#{XKYR_250310_08}", g_Anniversary2025_Yure_Param1))
	--根据奖励情况，显示与隐藏
	if g_Anniversary2025_Yure_Param2 == 1 then
		Anniversary2025_Yure_Reward_tips:Hide()
		Anniversary2025_Yure_RewardBtnOK:Show()
		Anniversary2025_Yure_RewardBtn:Disable()
	elseif g_Anniversary2025_Yure_Param1 >= 4 then
		Anniversary2025_Yure_Reward_tips:Show()
		Anniversary2025_Yure_RewardBtnOK:Hide()
		Anniversary2025_Yure_RewardBtn:Enable()		
	else
		Anniversary2025_Yure_Reward_tips:Hide()
		Anniversary2025_Yure_RewardBtnOK:Hide()
		Anniversary2025_Yure_RewardBtn:Enable()		
	end
end
	
function Anniversary2025_Yure_GotoNpc()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskGotoNpc" )
		Set_XSCRIPT_ScriptID( 999655 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Anniversary2025_Yure_RetGotoNpc()
	-- local temp = math.mod(g_Anniversary2025_Yure_Param1,10000)
	-- local nData_A = math.floor(temp/1000)
	-- local nData_B = math.floor((math.mod(temp,1000))/100)
	-- local nData_C = math.floor((math.mod(temp,100))/10)
	-- local nData_D = math.mod(temp,10)	
	
	--寻路
	local resId = 0
	local posx = 270
	local posz = 270
	local name = "魏询"
	AutoRuntoTargetExWithName(posx, posz, resId, name)

	PushDebugMessage("#{XKYR_250310_57}")
end

function Anniversary2025_Yure_ForHelp()
	PushEvent("CCSHOP_HELP", 234)
end

function Anniversary2025_Yure_GetReward()

	-- if nIndex~=1 and nIndex~=2 and nIndex~=3 then
		-- return
	-- end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 999655 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

--================================================
-- 关闭界面
--================================================
function Anniversary2025_Yure_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Anniversary2025_Yure_On_ResetPos()

	Anniversary2025_Yure_Frame : SetProperty("UnifiedXPosition", g_Anniversary2025_Yure_UnifiedXPosition);
	Anniversary2025_Yure_Frame : SetProperty("UnifiedYPosition", g_Anniversary2025_Yure_UnifiedYPosition);

end

