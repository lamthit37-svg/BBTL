local y_offset = 25
local g_WidthOfCompare2 = 300
--=========
--PreLoad==
--=========
function SuperToolTip2_AttrCompare2_PreLoad()
	this:RegisterEvent("SHOW_SP2_CMP2")
	this:RegisterEvent("MOVE_SP2_CMP2")
	this:RegisterEvent("CLOSE_SP2_CMP2")
end
--=========
--OnLoad
--=========
function SuperToolTip2_AttrCompare2_OnLoad()

end
--=========
--OnEvent
--=========
function SuperToolTip2_AttrCompare2_OnEvent(event)
	if ( event == "SHOW_SP2_CMP2" ) then
		if 	tonumber(arg3) == 0 then
			return
		end
		SuperToolTip2_AttrCompare2_Update();
		_SuperToolTip2_AttrCompare2:PositionSelf(0, 0, 1, 1);
		local rH = _SuperToolTip2_AttrCompare2:GetProperty("AbsoluteHeight");
		_SuperToolTip2_AttrCompare2:SetProperty("AbsoluteXPosition",0)
		_SuperToolTip2_AttrCompare2:SetProperty("AbsoluteYPosition",0)
		
		local nWidth = SuperToolTip2_AttrCompare2_Frame:GetProperty("AbsoluteWidth")
		SuperToolTip2_AttrCompare2_Frame:SetProperty("AbsoluteHeight", tostring(rH+5.0));
		SuperToolTip2_AttrCompare2_Frame:SetProperty("AbsoluteXPosition" , tostring(arg0 - nWidth - g_WidthOfCompare2) )
		SuperToolTip2_AttrCompare2_Frame:SetProperty("AbsoluteYPosition" , tostring(arg1 - y_offset))

		this:Show()
		return
	elseif ( event == "MOVE_SP2_CMP2" ) then
		if this:IsVisible() then
			local posX = tonumber(arg0)
			local posY = tonumber(arg1)
			local nWidth = SuperToolTip2_AttrCompare2_Frame:GetProperty("AbsoluteWidth")
			SuperToolTip2_AttrCompare2_Frame:SetProperty("AbsoluteXPosition" , tostring(posX - nWidth - g_WidthOfCompare2) )
			SuperToolTip2_AttrCompare2_Frame:SetProperty("AbsoluteYPosition" , tostring(posY - y_offset))
		end
	elseif event == "CLOSE_SP2_CMP2" then
		this:Hide()
	end
end
--=========
--Update UI
--=========
function SuperToolTip2_AttrCompare2_Update()
		-- 先清空以前显示的文字
		SuperToolTip2_AttrCompare2_ClearText();
		local toDisplay = "SuperToolTip2_AttrCompare2_Title;SuperToolTip2_AttrCompare2_Property";
		
		_SuperToolTip2_AttrCompare2:SetProperty("PageElements", toDisplay);
		
		local AttrStr = AttrCompare2_2:GetAttrCmpStr();
		if AttrStr ~= nil then
			SuperToolTip2_AttrCompare2_Property:SetText(AttrStr);
		else
			SuperToolTip2_AttrCompare2_Property:SetText("#{ZBBJ_100816_02}");
		end
		
end

-------------------------------------------------------------------------------------------------------------------------------
--
-- 清空显示文本
--
function SuperToolTip2_AttrCompare2_ClearText()
		SuperToolTip2_AttrCompare2_Property:SetText("");
end



