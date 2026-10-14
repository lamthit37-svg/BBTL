local y_offset = 25
local g_WidthOfCompare = 300
--=========
--PreLoad==
--=========
function SuperToolTip2_AttrCompare_PreLoad()
	this:RegisterEvent("SHOW_SP2_CMP1")
	this:RegisterEvent("MOVE_SP2_CMP1")
	this:RegisterEvent("CLOSE_SP2_CMP1")
end
--=========
--OnLoad
--=========
function SuperToolTip2_AttrCompare_OnLoad()


end
--=========
--OnEvent
--=========
function SuperToolTip2_AttrCompare_OnEvent(event)
	if ( event == "SHOW_SP2_CMP1" ) then
		if 	tonumber(arg4) == 0 then
			return
		end
		SuperToolTip2_AttrCompare_Update();
		_SuperToolTip2_AttrCompare:PositionSelf(0, 0, 1, 1);
		local rH = _SuperToolTip2_AttrCompare:GetProperty("AbsoluteHeight");
		_SuperToolTip2_AttrCompare:SetProperty("AbsoluteXPosition",0)
		_SuperToolTip2_AttrCompare:SetProperty("AbsoluteYPosition",0)
		
		SuperToolTip2_AttrCompare_Frame:SetProperty("AbsoluteHeight", tostring(rH+5.0));
		SuperToolTip2_AttrCompare_Frame:SetProperty("AbsoluteXPosition" , tostring(arg0 + arg2 + g_WidthOfCompare) )
		SuperToolTip2_AttrCompare_Frame:SetProperty("AbsoluteYPosition" , tostring(arg1 - y_offset))
		
		this:Show()
		return
	elseif event == "MOVE_SP2_CMP1" then
		if this:IsVisible() then
			local posX = tonumber(arg0)
			local posY = tonumber(arg1)
			local nWidth = tonumber(arg2)
			SuperToolTip2_AttrCompare_Frame:SetProperty("AbsoluteXPosition" , tostring(posX + nWidth + g_WidthOfCompare) )
			SuperToolTip2_AttrCompare_Frame:SetProperty("AbsoluteYPosition" , tostring(posY - y_offset))
		end
	elseif event == "CLOSE_SP2_CMP1" then
		this:Hide()
	end

end
--=========
--Update UI
--=========
function SuperToolTip2_AttrCompare_Update()
		-- 先清空以前显示的文字
		SuperToolTip2_AttrCompare_ClearText();
		local toDisplay = "SuperToolTip2_AttrCompare_Title;SuperToolTip2_AttrCompare_Property";
		
		_SuperToolTip2_AttrCompare:SetProperty("PageElements", toDisplay);
		
		local AttrStr = AttrCompare2_1:GetAttrCmpStr();
		if AttrStr ~= nil then
			SuperToolTip2_AttrCompare_Property:SetText(AttrStr);
		else
			SuperToolTip2_AttrCompare_Property:SetText("#{ZBBJ_100816_02}");
		end
end

-------------------------------------------------------------------------------------------------------------------------------
--
-- 清空显示文本
--
function SuperToolTip2_AttrCompare_ClearText()
		SuperToolTip2_AttrCompare_Property:SetText("");
end

