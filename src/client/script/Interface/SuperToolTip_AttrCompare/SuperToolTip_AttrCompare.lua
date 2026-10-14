local y_offset = 25

local g_WidthOfCompare = 300
--=========
--PreLoad==
--=========
function SuperToolTip_AttrCompare_PreLoad()

	this:RegisterEvent("SHOW_SP_CMP1")
	this:RegisterEvent("CLOSE_SP_CMP1")
end
--=========
--OnLoad
--=========
function SuperToolTip_AttrCompare_OnLoad()

end
--=========
--OnEvent
--=========
function SuperToolTip_AttrCompare_OnEvent(event)

	if ( event == "SHOW_SP_CMP1" ) then
		if 	tonumber(arg5) == 0 then
			return
		end

		if TLCJ:IsInTLCJScene() ==1 then
			return 
		end
		
		SuperToolTip_AttrCompare_Update();
		
		SuperToolTip_AttrCompare_Frame:PositionSelf(0, 0, 1, 1);
		
		local posX = SuperToolTip_AttrCompare_Frame:SetXAttachPos(arg0 ,(arg2 + g_WidthOfCompare) ,tonumber(arg4) )
		SuperToolTip_AttrCompare_Frame:SetProperty("AbsoluteYPosition" , tostring(arg1 - y_offset))

		if tonumber(arg0) > tonumber(posX) then
			posX = SuperToolTip_AttrCompare_Frame:GetProperty("AbsoluteXPosition");	
			SuperToolTip_AttrCompare_Frame:SetProperty("AbsoluteXPosition" , tostring(posX - g_WidthOfCompare))		
		end
		this:Show()
		return
	elseif event == "CLOSE_SP_CMP1" then
		this:Hide()
	end

end
--=========
--Update UI
--=========
function SuperToolTip_AttrCompare_Update()
		-- 先清空以前显示的文字
		SuperToolTip_AttrCompare_ClearText();
		local toDisplay = "SuperToolTip_AttrCompare_Title;SuperToolTip_AttrCompare_Property";
		
		SuperToolTip_AttrCompare_Frame:SetProperty("PageElements", toDisplay);
		
		local AttrStr = AttrCompare1_1:GetAttrCmpStr();
		if AttrStr ~= nil then
			SuperToolTip_AttrCompare_Property:SetText(AttrStr);
		else
			SuperToolTip_AttrCompare_Property:SetText("#{ZBBJ_100816_02}");
		end
end

-------------------------------------------------------------------------------------------------------------------------------
--
-- 清空显示文本
--
function SuperToolTip_AttrCompare_ClearText()
		SuperToolTip_AttrCompare_Property:SetText("");
end

