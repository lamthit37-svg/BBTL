local g_left , g_top , g_right , g_bottom
local g_SkillIndex;
local g_CurSelInfantIndex;
function InfantTips_PreLoad()
	this:RegisterEvent("INFANT_SKILL_MOUSE_ENTER");
	this:RegisterEvent("INFANT_SKILL_MOUSE_LEAVE");
	this:RegisterEvent("INFANT_SKILL_MOUSE_ENTER_NEW");
	this:RegisterEvent("INFANT_SKILL_MOUSE_LEAVE_NEW");
	this:RegisterEvent("INFANT_SKILL_MOUSE_ENTER_OTHER");
	this:RegisterEvent("INFANT_SKILL_MOUSE_ENTER_TARGET");
	this:RegisterEvent("INFANT_SKILL_MOUSE_LEAVE_OTHER");
end

function InfantTips_OnLoad()
	g_left = 0;
	g_top  = 0;
	g_right = 0;
	g_bottom = 0;
	g_CurSelInfantIndex = 0;
	g_SkillIndex = 0;
end

function InfantTips_OnEvent(event)
	if( event == "INFANT_SKILL_MOUSE_ENTER" ) then
		g_left = arg0;
		g_top  = arg1;
		g_right = arg2;
		g_bottom = arg3;
		g_CurSelInfantIndex = arg4;
		g_SkillIndex = arg5;


		local toDisplay = "";
		toDisplay = toDisplay .."InfantTips_Title";
		toDisplay = toDisplay ..";InfantTips_StaticPart";
		toDisplay = toDisplay ..";InfantTips_StaticPart_Item1";
		InfantTips_Frame:SetProperty("PageElements", toDisplay);
		if g_CurSelInfantIndex ~= nil and g_SkillIndex ~= nil then
			local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(tonumber(g_CurSelInfantIndex), tonumber(g_SkillIndex))
			--Tips上显示的数值是从表里直接读的
			szTipsInfo = Infant:GetInfantSkillValue(tonumber(g_CurSelInfantIndex), tonumber(g_SkillIndex))

			InfantTips_Title:SetText(szSkillName); --title
			InfantTips_StaticPart_Icon:SetProperty("Image", szIcon) --图标
			InfantTips_StaticPart_Item:SetText("#{INTERFACE_XML_228}"..nSkillLevel);	--等级
			InfantTips_StaticPart_Item1:SetText(szTipsInfo);

			InfantTips_Frame:PositionSelf(g_left, g_top, g_right, g_bottom);
			InfantTips_AutoLocate(g_left, g_top, g_right, g_bottom);
			this:Show()
		end
	elseif ( event == "INFANT_SKILL_MOUSE_ENTER_NEW" ) then

		g_left = arg0;
		g_top  = arg1;
		g_right = arg2;
		g_bottom = arg3;
		g_CurSelInfantIndex = arg4;
		g_SkillIndex = arg5;


		local toDisplay = "";
		toDisplay = toDisplay .."InfantTips_Title";
		toDisplay = toDisplay ..";InfantTips_StaticPart";
		toDisplay = toDisplay ..";InfantTips_StaticPart_Item1";
		InfantTips_Frame:SetProperty("PageElements", toDisplay);
		if g_CurSelInfantIndex ~= nil and g_SkillIndex ~= nil then
			local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetRefreshInfantSkillInfo(tonumber(g_CurSelInfantIndex), tonumber(g_SkillIndex))
			--Tips上显示的数值是从表里直接读的
			if nSkillID >= 0 then
				szTipsInfo = Infant:GetInfantRefreshSkillValue(tonumber(g_CurSelInfantIndex), tonumber(g_SkillIndex))

				InfantTips_Title:SetText(szSkillName); --title
				InfantTips_StaticPart_Icon:SetProperty("Image", szIcon) --图标
				InfantTips_StaticPart_Item:SetText("#{INTERFACE_XML_228}"..nSkillLevel);	--等级
				InfantTips_StaticPart_Item1:SetText(szTipsInfo);

				InfantTips_Frame:PositionSelf(g_left, g_top, g_right, g_bottom);
				InfantTips_AutoLocate(g_left, g_top, g_right, g_bottom);
				this:Show()
			end
		end

	elseif ( event == "INFANT_SKILL_MOUSE_ENTER_OTHER" ) then
		g_left = arg0;
		g_top  = arg1;
		g_right = arg2;
		g_bottom = arg3;
		g_CurSelInfantIndex = arg4;
		g_SkillIndex = arg5;


		local toDisplay = "";
		toDisplay = toDisplay .."InfantTips_Title";
		toDisplay = toDisplay ..";InfantTips_StaticPart";
		toDisplay = toDisplay ..";InfantTips_StaticPart_Item1";
		InfantTips_Frame:SetProperty("PageElements", toDisplay);
		if g_CurSelInfantIndex ~= nil and g_SkillIndex ~= nil then
			local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:Other_GetSkillInfo(tonumber(g_CurSelInfantIndex), tonumber(g_SkillIndex))
			InfantTips_Title:SetText(szSkillName); --title
			InfantTips_StaticPart_Icon:SetProperty("Image", szIcon) --图标
			InfantTips_StaticPart_Item:SetText("#{INTERFACE_XML_228}"..nSkillLevel);	--等级
			InfantTips_StaticPart_Item1:SetText(szTipsInfo);
			InfantTips_Frame:PositionSelf(g_left, g_top, g_right, g_bottom);
			InfantTips_AutoLocate(g_left, g_top, g_right, g_bottom);
			this:Show()
		end
	elseif ( event == "INFANT_SKILL_MOUSE_ENTER_TARGET" ) then
		g_left = arg0;
		g_top  = arg1;
		g_right = arg2;
		g_bottom = arg3;
		g_SkillIndex = arg4;


		local toDisplay = "";
		toDisplay = toDisplay .."InfantTips_Title";
		toDisplay = toDisplay ..";InfantTips_StaticPart";
		toDisplay = toDisplay ..";InfantTips_StaticPart_Item1";
		InfantTips_Frame:SetProperty("PageElements", toDisplay);
		if g_SkillIndex ~= nil then
			local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:Target_GetSkillInfo(tonumber(g_SkillIndex))
			InfantTips_Title:SetText(szSkillName); --title
			InfantTips_StaticPart_Icon:SetProperty("Image", szIcon) --图标
			InfantTips_StaticPart_Item:SetText("#{INTERFACE_XML_228}"..nSkillLevel);	--等级
			InfantTips_StaticPart_Item1:SetText(szTipsInfo);
			InfantTips_Frame:PositionSelf(g_left, g_top, g_right, g_bottom);
			InfantTips_AutoLocate(g_left, g_top, g_right, g_bottom);
			this:Show()
		end
	elseif( event == "INFANT_SKILL_MOUSE_LEAVE" ) or ( event == "INFANT_SKILL_MOUSE_LEAVE_OTHER" ) or ( event == "INFANT_SKILL_MOUSE_LEAVE_NEW" ) then
		InfantTips_StaticPart_Icon:SetProperty("Image", "")
		InfantTips_StaticPart_Item:SetText("");
		InfantTips_StaticPart_Item1:SetText("");
		InfantTips_Title:SetText("");
		this:Hide()
	end
end
--自动设置Tips位置
function InfantTips_AutoLocate(SetX,SetY,SetWidth,SetHeight)
	local TipsWidth = InfantTips_Frame:GetProperty("AbsoluteWidth")
	local TipsHeight = InfantTips_Frame:GetProperty("AbsoluteHeight")
	local ScreenWidth ,ScreenHeight = GetCurClientSize()
	InfantTips_Frame:SetProperty("AbsoluteXPosition",SetX + SetWidth)
	InfantTips_Frame:SetProperty("AbsoluteYPosition",SetY + SetHeight)

	if(SetX + SetWidth + TipsWidth > ScreenWidth) then
		InfantTips_Frame:SetProperty("AbsoluteXPosition",SetX - TipsWidth)
	end
	if(SetY + SetHeight + TipsHeight > ScreenHeight) then
		InfantTips_Frame:SetProperty("AbsoluteYPosition",SetY - TipsHeight)
	end
end
