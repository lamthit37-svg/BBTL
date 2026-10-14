--【2021Q2】西瓜节整合界面设计-H5活动界面



--=========
-- PreLoad()
--=========
function XiGua_H5_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function XiGua_H5_OnLoad()


end

--=========
-- Event
--=========
function XiGua_H5_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88844001) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			XiGua_H5_Open()
			this:Show()
		elseif bShow == 2 then		
			this:Hide()
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		XiGua_H5_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		XiGua_H5_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		XiGua_H5_On_ResetPos()

	end
end


function XiGua_H5_Close()
	this:Hide()
end

--=========
-- 重置
--=========
function XiGua_H5_On_ResetPos()

	

end

--=========
-- 打开
--=========
function XiGua_H5_Open()

	
	
end	


	
