-- 风云联动
-- 默认位置
local FengYun_PVE_Skill_UnifiedPosition = nil
local FengYun_PVE_Skill_Max = 4
local FengYun_PVE_UI_List = {}

function FengYun_PVE_Skill_PreLoad()
	this:RegisterEvent("FYPVE_BATTLESKILLOPEN", true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS", false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Skill_PreLoad()

function FengYun_PVE_Skill_OnEvent(event)
	if (event == "FYPVE_BATTLESKILLOPEN") then
		FengYun_PVE_Skill_Show()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Skill_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Skill_UnifiedPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		FengYun_PVE_Skill_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if FYPVE:IsInFYPVEScene() ~= 1 then
			FengYun_PVE_Skill_Hide()
		end
	end
end -- end func FengYun_PVE_Skill_OnEvent()

function FengYun_PVE_Skill_OnLoad()
	FengYun_PVE_UI_List = {
		{action=FengYun_PVE_Skill_Item1,mask=FengYun_PVE_Skill_Item1_Mask,},
		{action=FengYun_PVE_Skill_Item2,mask=FengYun_PVE_Skill_Item2_Mask,},
		{action=FengYun_PVE_Skill_Item3,mask=FengYun_PVE_Skill_Item3_Mask,},
		{action=FengYun_PVE_Skill_Item4,mask=FengYun_PVE_Skill_Item4_Mask,},
	}
	FengYun_PVE_Skill_UnifiedPosition = FengYun_PVE_Skill_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Skill_OnLoad()

-- 界面默认位置
function FengYun_PVE_Skill_UnifiedPos()
	if (FengYun_PVE_Skill_UnifiedPosition ~= nil) then
		FengYun_PVE_Skill_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Skill_UnifiedPosition)
	end
end -- end func FengYun_PVE_Skill_UnifiedPos()

function FengYun_PVE_Skill_Show()
	for i=1, FengYun_PVE_Skill_Max do
		local itemUI = FengYun_PVE_UI_List[i]
		if itemUI ~= nil then
			local theAction = FYPVE:CreateFYPVESkillAction(i-1)
			if theAction ~= nil and theAction:GetID() ~= 0 then
				itemUI.action:SetActionItem(theAction:GetID())

				local isLockId = FYPVE:GetBattleSkillData(i-1)
				if isLockId == nil or isLockId < 1 then
					itemUI.action:Gloom()
					itemUI.mask:Show()
				else
					itemUI.action:Bright()
					itemUI.mask:Hide()
				end
			else
				itemUI.action:SetActionItem(-1)
				itemUI.mask:Show()
			end
		end
	end
    this:Show()
end -- end func FengYun_PVE_Skill_Show()

function FengYun_PVE_Skill_Hide()
    this:Hide()
end -- end func FengYun_PVE_Skill_Hide()

function FengYun_PVE_Skill_Item_Click(index, click)
	if index < 1 or index > FengYun_PVE_Skill_Max then
		PushDebugMessage("#{FYPVE_260108_69}")
		return
	end

	local isLockId = FYPVE:GetBattleSkillData(index-1)
	if isLockId == nil or isLockId < 1 then
		PushDebugMessage("#{FYPVE_260108_69}")
		return
	end

	local itemUI = FengYun_PVE_UI_List[index]
	if itemUI ~= nil then
		itemUI.action:DoAction()
	end
end