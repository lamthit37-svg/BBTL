--2026Q2武神坛打卡

local g_Frame_UnifiedPosition

--=========
-- PreLoad()
--=========
function WuShenTan_DaKa_GoTo_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)

end

--=========
-- OnLoad()
--=========
function WuShenTan_DaKa_GoTo_OnLoad()

	g_Frame_UnifiedPosition = WuShenTan_DaKa_GoTo_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function WuShenTan_DaKa_GoTo_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89362401 then
			
		local nType = Get_XParam_INT(0)
		if nType == 0 then --关闭界面
			WuShenTan_DaKa_GoTo_OnHide()
			return
		elseif nType == 1 then --打开界面
			this:Show()
		end	
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		WuShenTan_DaKa_GoTo_OnHide()

	elseif event == "VIEW_RESOLUTION_CHANGED" then

		WuShenTan_DaKa_GoTo_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		WuShenTan_DaKa_GoTo_ResetPos()
		
    elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible() ) then
		-- if(tonumber(arg0) ~= g_objCared) then
			-- return
		-- end
		-- -- 如果和NPC的距离大于一定距离或者被删除，自动关闭
        -- if(arg1 == "distance" and tonumber(arg2)>15 or arg1=="destroy") then
            -- WuShenTan_DaKa_GoTo_OnHide()
        -- end
		-- --取消关心
		-- this:CareObject(g_objCared, 0, "WuShenTan_DaKa_GoTo");		
	end

end

function WuShenTan_DaKa_GoTo_ShowHelp()
	PushEvent("CCSHOP_HELP", 247)--关于
end

function WuShenTan_DaKa_GoTo()
	AutoRuntoTargetExWithName(306, 270, 0, "白须道人")
end

function WuShenTan_DaKa_GoTo_ResetPos()

	WuShenTan_DaKa_GoTo_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

function WuShenTan_DaKa_GoTo_OnHide()
	this:Hide()
end


