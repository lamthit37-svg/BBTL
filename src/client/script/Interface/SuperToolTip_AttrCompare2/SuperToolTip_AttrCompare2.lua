local y_offset = 25
local g_WidthOfCompare2 = 300

--=========
--PreLoad==
--=========
function SuperToolTip_AttrCompare2_PreLoad()
	this:RegisterEvent("SHOW_SP_CMP2")
	this:RegisterEvent("CLOSE_SP_CMP2")
end
--=========
--OnLoad
--=========
function SuperToolTip_AttrCompare2_OnLoad()

end
--=========
--OnEvent
--=========
function SuperToolTip_AttrCompare2_OnEvent(event)

	if ( event == "SHOW_SP_CMP2" ) then
		if 	tonumber(arg5) == 0 then
			return
		end
		
		SuperToolTip_AttrCompare2_Update();
		
		SuperToolTip_AttrCompare2_Frame:PositionSelf(0, 0, 1, 1);
		SuperToolTip_AttrCompare2_Frame:SetProperty("AbsoluteXPosition",0)
		SuperToolTip_AttrCompare2_Frame:SetProperty("AbsoluteYPosition",0)
		
		local posX = SuperToolTip_AttrCompare2_Frame:SetXAttachPos(arg0 ,(arg2 + g_WidthOfCompare2) ,tonumber(arg3) )
		SuperToolTip_AttrCompare2_Frame:SetProperty("AbsoluteYPosition" , tostring(arg1 - y_offset))

		if tonumber(arg0) > tonumber(posX) then
			posX = SuperToolTip_AttrCompare2_Frame:GetProperty("AbsoluteXPosition");	
			SuperToolTip_AttrCompare2_Frame:SetProperty("AbsoluteXPosition" , tostring(posX - g_WidthOfCompare2));				
		end
		this:Show()
		return
	elseif event == "CLOSE_SP_CMP2" then
		this:Hide()
	end

end
--=========
--Update UI
--=========
function SuperToolTip_AttrCompare2_Update()
		-- 先清空以前显示的文字
		SuperToolTip_AttrCompare2_ClearText();
		local toDisplay = "SuperToolTip_AttrCompare2_Title;SuperToolTip_AttrCompare2_Property";
		
		SuperToolTip_AttrCompare2_Frame:SetProperty("PageElements", toDisplay);
		
		local AttrStr = AttrCompare1_2:GetAttrCmpStr();
		if AttrStr ~= nil then
			SuperToolTip_AttrCompare2_Property:SetText(AttrStr);
		else
			SuperToolTip_AttrCompare2_Property:SetText("#{ZBBJ_100816_02}");
		end

		
end

-------------------------------------------------------------------------------------------------------------------------------
--
-- 清空显示文本
--
function SuperToolTip_AttrCompare2_ClearText()
		SuperToolTip_AttrCompare2_Property:SetText("");
end

