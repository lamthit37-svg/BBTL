
local g_ZongMenSkill_Edit_Frame_UnifiedPosition
local g_ZongMenSkill_Edit_Index = 0
function ZongMenSkill_Edit_PreLoad()
    this:RegisterEvent("OPEN_ZONGMEN_EDIT", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function ZongMenSkill_Edit_OnLoad()	
    g_ZongMenSkill_Edit_Frame_UnifiedPosition = ZongMenSkill_Edit_Frame:GetProperty("UnifiedPosition")

end										

function ZongMenSkill_Edit_OnEvent(event)
    if event == "OPEN_ZONGMEN_EDIT" then
        if this:IsVisible() then
			ZongMenSkill_Edit_CloseClicked()
			return
        end
        g_ZongMenSkill_Edit_Index = tonumber(arg0)
        ZongMenSkill_Edit_Open()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
        ZongMenSkill_Edit_On_ResetPos()
    elseif event == "ADJEST_UI_POS" then
		ZongMenSkill_Edit_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then  
        ZongMenSkill_Edit_CloseClicked()
    end
end

function ZongMenSkill_Edit_Open()
	this:Show()
    ZongMenSkill_Edit_Name:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	ZongMenSkill_Edit_Name:SetText("")	
end

function ZongMenSkill_Edit_TextChanged()
end

function ZongMenSkill_Edit_OKClicked()
    -- local newName = ZongMenSkill_Edit_Name:GetText()
    -- -- PushDebugMessage("newName:"..newName)
    -- if newName == nil then
    --     return
    -- end
    -- DataPool:ChangeSectName(g_ZongMenSkill_Edit_Index, newName)
    -- this:Hide()
end

function ZongMenSkill_Edit_On_ResetPos()
	ZongMenSkill_Edit_Frame:SetProperty("UnifiedPosition", g_ZongMenSkill_Edit_Frame_UnifiedPosition)

end

function ZongMenSkill_Edit_CloseClicked()
    this:Hide()
end

function ZongMenSkill_Edit_OnHidden()
    g_ZongMenSkill_Edit_Index = 0
end
