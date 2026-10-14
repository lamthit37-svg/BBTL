
local g_XiGua_Preview_UnifiedPosition

local g_XiGua_Preview_List = {}

function XiGua_Preview_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

function XiGua_Preview_OnLoad()
	
	g_XiGua_Preview_UnifiedPosition = XiGua_Preview:GetProperty("UnifiedPosition")
	
	g_XiGua_Preview_List = {
		[1] = {XiGua_Preview_ShowPic1, XiGua_Preview_ShowPic2, XiGua_Preview_Style},
		[2] = {XiGua_Preview_ShowPic3, XiGua_Preview_ShowPic4, XiGua_Preview_Style2},
		[3] = {XiGua_Preview_ShowPic5, XiGua_Preview_ShowPic6, XiGua_Preview_Style3},
		[4] = {XiGua_Preview_ShowPic7, XiGua_Preview_ShowPic8, XiGua_Preview_Style4},
	}

end

--=========
-- Event
--=========
function XiGua_Preview_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 2020062901) then
		
		if this:IsVisible() then
			XiGua_Preview_Close()
			return
		end	
		
		XiGua_Preview_StyleChoose( 1 )
		
		this:Show()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		XiGua_Preview_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		XiGua_Preview_Close()

	elseif event == "ADJEST_UI_POS" then

		XiGua_Preview_On_ResetPos()
		
	end

end

--=========
-- 重置
--=========
function XiGua_Preview_On_ResetPos()

	XiGua_Preview:SetProperty("UnifiedPosition", g_XiGua_Preview_UnifiedPosition)

end

--=========
-- 关闭
--=========
function XiGua_Preview_Close()
	
	this:Hide()
	
end

function XiGua_Preview_StyleChoose( nIdx )
	if nIdx < 1 or nIdx > 4 then
		return
	end
	
	if g_XiGua_Preview_List[nIdx] == nil then
		return
	end
	
	for i = 1, 4 do
		if i == nIdx then
			g_XiGua_Preview_List[i][1]:Show()
			g_XiGua_Preview_List[i][2]:Show()
			g_XiGua_Preview_List[i][3]:SetCheck(1)
		else
			g_XiGua_Preview_List[i][1]:Hide()
			g_XiGua_Preview_List[i][2]:Hide()
			g_XiGua_Preview_List[i][3]:SetCheck(0)
		end
	end
	
end

