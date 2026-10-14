

local g_TongTianTa_Mini_SceneId;

function TongTianTa_Mini_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	
	this:RegisterEvent("NEWDIGONG_SWITCH")
end

function TongTianTa_Mini_OnLoad()	

end

function TongTianTa_Mini_OnEvent(event)
	if event == "NEWDIGONG_SWITCH" then
		if tonumber(arg0) == 0 then
			local floor = tonumber(arg1)
			if floor == 1 then
				TongTianTa_Mini_PageHeader:SetText("#{JDQL_230322_08}")
			elseif floor == 2 then
				TongTianTa_Mini_PageHeader:SetText("#{JDQL_230322_22}")
			elseif floor == 3 then
				TongTianTa_Mini_PageHeader:SetText("#{JDQL_230322_25}")
			elseif floor == 4 then
				TongTianTa_Mini_PageHeader:SetText("#{JDQL_230322_28}")
			elseif floor == 5 then
				TongTianTa_Mini_PageHeader:SetText("#{JDQL_230322_31}")
			end	
			g_TongTianTa_Mini_SceneId = floor		
			this:Show()
		else
			this:Hide()
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20000519 then
		local floor = tonumber(arg1)
		local flashtype = Get_XParam_INT(0)
		if flashtype == 1000 then
			this:Hide()
			return
		end	
		if floor >=1 and floor <=5 then

		else
			if this:IsVisible() then
				return
			end
			this:Hide()
		end
	end
end


function TongTianTa_Mini_Open()
	PushEvent("NEWDIGONG_SWITCH",g_TongTianTa_Mini_SceneId)

end