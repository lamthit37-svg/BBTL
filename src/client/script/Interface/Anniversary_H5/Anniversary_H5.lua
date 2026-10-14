-- Anniversary_H5 周年庆h5前端
-- !!!reloadscript =Anniversary_2023ZNQ_h5



local g_Anniversary_H5_Frame_UnifiedPosition
local g_nUICommandID		= 99843601

--=========================================================
-- PreLoad
--=========================================================
function Anniversary_H5_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end


--=========================================================
-- OnLoad
--=========================================================
function Anniversary_H5_OnLoad()
	g_Anniversary_H5_Frame_UnifiedPosition =  Anniversary_H5_Frame:GetProperty("UnifiedPosition")


end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_H5_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 99843601) then	
		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		--切换场景关闭界面
		Anniversary_H5_Close()	
	end
end



--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_H5_Close()	
	
	-- 重置
	this:Hide()

end

--=========================================================
-- 界面隐藏
--=========================================================
function Anniversary_H5_OnHide()
	-- 重置
	this:Hide()

end
--=========================================================
-- 界面隐藏
--=========================================================
function Anniversary_H5_OnHiden()
	-- 重置
	this:Hide()

end


