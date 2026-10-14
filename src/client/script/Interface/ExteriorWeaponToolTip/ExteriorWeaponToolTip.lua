
-- local g_ExteriorWeaponToolTip_Frame_UnifiedPosition
local g_ExteriorWeaponId = -1
local g_ExteriorType = 1 --幻武
local g_LeftTime = 0 --剩余时间
--=========
--PreLoad==
--=========
function ExteriorWeaponToolTip_PreLoad()
	this:RegisterEvent("EXTERIOR_WEAPON_TOOLTIP",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
end

--=========
--OnLoad
--=========
function ExteriorWeaponToolTip_OnLoad()
	-- g_ExteriorWeaponToolTip_Frame_UnifiedPosition = ExteriorWeaponToolTip_Frame:GetProperty("UnifiedPosition")
end
--=========
--OnEvent
--=========
function ExteriorWeaponToolTip_OnEvent(event)
	if (event == "ADJEST_UI_POS" ) then
		ExteriorWeaponToolTip_Frame:CenterWindow();
		-- ExteriorWeaponToolTip_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ExteriorWeaponToolTip_Frame:CenterWindow();
		-- ExteriorWeaponToolTip_Frame_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ExteriorWeaponToolTip_CloseBtnClick()
	elseif (event == "EXTERIOR_WEAPON_TOOLTIP") then
		g_ExteriorWeaponId = tonumber(arg0)
		g_LeftTime = tonumber(arg1)
		-- PushDebugMessage("g_LeftTime:"..tostring(g_LeftTime))
		if g_ExteriorWeaponId>=0 then
			ExteriorWeaponToolTip_Show()
		end
	end
	

end

function ExteriorWeaponToolTip_Show()
	this:Show()

	--显示静态头
	local toDisplay = "ExteriorWeaponToolTip_PageHeader";
	--详细解释
	toDisplay = toDisplay .. ";ExteriorWeaponToolTip_ShortDesc";
	toDisplay = toDisplay .. ";ExteriorWeaponToolTip_StaticPart_Yuanbaojiaoyi";
	toDisplay = toDisplay .. ";ExteriorWeaponToolTip_deadline_Text";
	toDisplay = toDisplay .. ";ExteriorWeaponToolTip_Tujian_Tips";
	--显示组件内容
	_ExteriorWeaponToolTip_:SetProperty("PageElements", toDisplay);

	local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(g_ExteriorWeaponId, "Name")
	local strTemp = ScriptGlobal_Format("#{WGTJ_201222_137}", strName)
	ExteriorWeaponToolTip_Title:SetText(strTemp)
	local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(g_ExteriorWeaponId, "Icon")
	local strImage = GetIconFullName(strIcon)
	ExteriorWeaponToolTip_StaticPart_Icon:SetProperty("Image", strImage)

	local strContext2 = Exterior:LuaFnGetExteriorWeaponInfo(g_ExteriorWeaponId, "strContext2")
	local strTemp = ScriptGlobal_Format("#{WGTJ_201222_139}", strContext2)
	ExteriorWeaponToolTip_Tujian_Tips:SetText(strTemp)

	local nLeftTime = g_LeftTime--Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, g_ExteriorWeaponId)

	if nLeftTime<0 then
		ExteriorWeaponToolTip_deadline_Text:SetText("#{WGTJ_201222_140}")
	else
		if nLeftTime>= 86400 then
			local days = math.floor(nLeftTime / 86400)
			local strTemp = ScriptGlobal_Format("#{WGTJ_201222_141}", days)
			ExteriorWeaponToolTip_deadline_Text:SetText(strTemp)
		elseif nLeftTime < 3600 then
			ExteriorWeaponToolTip_deadline_Text:SetText("#{WGTJ_201222_143}")
		else
			local nHours = math.floor(nLeftTime / 3600)
			local strTemp = ScriptGlobal_Format("#{WGTJ_201222_142}", nHours)
			ExteriorWeaponToolTip_deadline_Text:SetText(strTemp)
		end
	end

	_ExteriorWeaponToolTip_:PositionSelf(0, 0, 1, 1);
	local rH = _ExteriorWeaponToolTip_:GetProperty("AbsoluteHeight");
	_ExteriorWeaponToolTip_:SetProperty("AbsoluteXPosition",0)
	_ExteriorWeaponToolTip_:SetProperty("AbsoluteYPosition",0)
	_ExteriorWeaponToolTip_:SetProperty("AbsoluteHeight", tostring(rH));
end

-- function ExteriorWeaponToolTip_Frame_On_ResetPos()
-- 	ExteriorWeaponToolTip_Frame:SetProperty("UnifiedPosition", g_ExteriorWeaponToolTip_Frame_UnifiedPosition);
-- end

function ExteriorWeaponToolTip_OnMoved()
end


function ExteriorWeaponToolTip_OnHide()
	g_ExteriorWeaponId = -1
	g_LeftTime = 0

end

function ExteriorWeaponToolTip_CloseBtnClick()
	this:Hide()
end