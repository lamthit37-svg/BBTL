local g_InfluenceCityFuctionView_Frame_UnifiedPosition
function InfluenceCityFuctionView_PreLoad()
	--2014Q1大世界功能调整,屏蔽客户端"世族"相关脚本
	--this:RegisterEvent("OPEN_DETAIL_CITYINFO")
	--this:RegisterEvent("OPEN_DETAIL_FUBENINFO")
	--this:RegisterEvent("CLOSE_ALL_KCITY_UI");
		-- 游戏窗口尺寸发生了变化
	--this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	--this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("MARTIAL_SHOW_HELP");
	this:RegisterEvent("SHOW_SHEJAO2018_HELP")
end

function InfluenceCityFuctionView_OnLoad()
		g_InfluenceCityFuctionView_Frame_UnifiedPosition=InfluenceCityFuctionView_Frame:GetProperty("UnifiedPosition");
end

function InfluenceCityFuctionView_OnEvent(event)
		if ( event == "UI_COMMAND" and tonumber(arg0) == 201406073) then
			
			InfluenceCityFuctionViewGreeting_Desc:ClearAllElement()
			InfluenceCityFuctionView_Frame_Debug:SetText("")
			InfluenceCityFuctionViewGreeting_Desc:AddTextElement("#{XLDL_140606_33}")
				
			this:Show();
		end
		if(event == "MARTIAL_SHOW_HELP") then
			local nIndex = tonumber(arg0)
			if(nIndex ~= nil) then
				local strDesc = ""
				if(nIndex == 1) then
					strDesc = "#{WYXT_20170907_313}"
				elseif(nIndex == 2) then
					strDesc = "#{WYXT_20170907_290}"
				elseif(nIndex == 3) then
					strDesc = "#{WYXT_20170907_331}"
				elseif(nIndex == 4) then
					strDesc = "#{WYXT_20170811_179}"
				elseif(nIndex == 5) then
					strDesc = "#{WYXT_20170907_314}"
				elseif(nIndex == 6) then
					strDesc = "#{WYXT_20170907_324}"
				elseif(nIndex == 7) then
					strDesc = "#{WYXT_20170907_374}"
				end
				
				
				InfluenceCityFuctionViewGreeting_Desc:ClearAllElement()
				InfluenceCityFuctionView_Frame_Debug:SetText("")
				
				InfluenceCityFuctionViewGreeting_Desc:AddTextElement(strDesc)
				this:Hide();
				this:Show();
			end
			return
		end
		if(event == "SHOW_SHEJAO2018_HELP") then
			local szDesc = tostring(arg0)
			InfluenceCityFuctionViewGreeting_Desc:ClearAllElement()
			InfluenceCityFuctionView_Frame_Debug:SetText("")
			InfluenceCityFuctionViewGreeting_Desc:AddTextElement(szDesc)
			this:Hide();
			this:Show();
			return
		end
	--[[
    if (event == "CLOSE_ALL_KCITY_UI" ) then
    	InfluenceCityFuctionView_Close()
    elseif (event == "OPEN_DETAIL_CITYINFO" ) then
    	InfluenceCityFuctionView_ShowCityDetail()
    elseif (event == "OPEN_DETAIL_FUBENINFO" ) then
    	InfluenceCityFuctionView_ShowFubenDetail()
    -- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		InfluenceCityFuctionView_Frame:SetProperty("UnifiedPosition", g_InfluenceCityFuctionView_Frame_UnifiedPosition);
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		InfluenceCityFuctionView_Frame:SetProperty("UnifiedPosition", g_InfluenceCityFuctionView_Frame_UnifiedPosition);
	end
	--]]
end


function InfluenceCityFuctionView_ShowFubenDetail()
	InfluenceCityFuctionViewGreeting_Desc:ClearAllElement()
	InfluenceCityFuctionView_Frame_Debug:SetText("副本详情")
	InfluenceCityFuctionViewGreeting_Desc:AddTextElement("待添加")
	this:Show()
end

function InfluenceCityFuctionView_Close()
	this:Hide()
end
