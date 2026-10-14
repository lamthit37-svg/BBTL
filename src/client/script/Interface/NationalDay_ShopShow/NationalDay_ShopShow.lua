
local g_NationalDay_ShopShow_UnifiedPosition

local g_NationalDay_ShopShow_ItemAction ={}

local g_NationalDay_ShopShow_Str = {
[1] = "#{GQKJ_190722_219}",
[2] = "#{GQKJ_190722_220}",
[3] = "#{YHLJL_210826_4}"
}

function NationalDay_ShopShow_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

function NationalDay_ShopShow_OnLoad()
	
	g_NationalDay_ShopShow_UnifiedPosition = NationalDay_ShopShow_Frame:GetProperty("UnifiedPosition")
	
	g_NationalDay_ShopShow_ItemAction = {
		NationalDay_ShopShow_Client1,
		NationalDay_ShopShow_Client2,
		NationalDay_ShopShow_Client3
	}

end

--=========
-- Event
--=========
function NationalDay_ShopShow_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 89315806) then
		
		if this:IsVisible() then
			NationalDay_ShopShow_Close()
			return
		end	
		
		for i = 1, table.getn(g_NationalDay_ShopShow_ItemAction) do
			g_NationalDay_ShopShow_ItemAction[i]:Hide()
		end

		local nImageIdx = nil
		if Get_XParam_INT_Count() < 1 and arg1 ~= nil then
			nImageIdx = tonumber(arg1)
		elseif Get_XParam_INT_Count() >= 1 then
			nImageIdx = Get_XParam_INT(0)
		end

		if nImageIdx ~= nil and nImageIdx ~= 0 then

			if g_NationalDay_ShopShow_ItemAction[nImageIdx] ~= nil and g_NationalDay_ShopShow_Str[nImageIdx] ~= nil then
			
				g_NationalDay_ShopShow_ItemAction[nImageIdx]:Show()
				
				NationalDay_ShopShow_DragTitle:SetText(g_NationalDay_ShopShow_Str[nImageIdx])
				
				this:Show()
				
				return
			end
		end	
			
		NationalDay_ShopShow_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		NationalDay_ShopShow_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		NationalDay_ShopShow_Close()

	elseif event == "ADJEST_UI_POS" then

		NationalDay_ShopShow_On_ResetPos()
		
	end

end

--=========
-- 重置
--=========
function NationalDay_ShopShow_On_ResetPos()

	NationalDay_ShopShow_Frame:SetProperty("UnifiedPosition", g_NationalDay_ShopShow_UnifiedPosition)

end

--=========
-- 关闭
--=========
function NationalDay_ShopShow_Close()
	
	this:Hide()
	
end

