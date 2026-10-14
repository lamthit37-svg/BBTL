-- 
-- 保存UI默认位置
local ZM_Boss_Reward_UnifiedPosition = nil
function ZM_Boss_Reward_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function ZM_Boss_Reward_OnLoad()
	
	 ZM_Boss_Reward_UnifiedPosition = ZM_Boss_Reward_Frame:GetProperty("UnifiedPosition")	
end

function ZM_Boss_Reward_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 999029003 then
		local kjtype   = KaJi:LuaFnGetKaJiType(147)
		if kjtype == 1 then
			ZM_Boss_Reward_Icon:SetToolTip("#{ZMB_230124_161}")
		else
			ZM_Boss_Reward_Icon:SetToolTip("#{ZMB_230124_27}")
		end
		ZM_Boss_Reward_Icon_Animate:Play(true)
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 999029004 then
		this:Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        ZM_Boss_Reward_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        ZM_Boss_Reward_UnifiedPos()
	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

-- 界面默认位置
function ZM_Boss_Reward_UnifiedPos()
    if (this:IsVisible()) then
        if (ZM_Boss_Reward_UnifiedPosition ~= nil) then
            ZM_Boss_Reward_Frame:SetProperty("UnifiedPosition", ZM_Boss_Reward_UnifiedPosition)
        end
    end
end -- end func ZM_Boss_Reward_UnifiedPos()

function ZM_Boss_Reward_OnClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskGetReward")
		Set_XSCRIPT_ScriptID(999029)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end