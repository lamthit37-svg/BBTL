local g_Frame_UnifiedPosition
local g_itemid = 38004862
local g_itemid_ks = 38003040
--=========
-- PreLoad()
--=========
function JinFengji_HolidayGift_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function JinFengji_HolidayGift_OnLoad()
	
	g_Frame_UnifiedPosition = JinFengji_HolidayGift_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function JinFengji_HolidayGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88812901) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			JinFengji_HolidayGift_Open()
			this:Show()
		elseif bShow == 2 then
		
			this:Hide()
			JinFengji_HolidayGift_GiftItem_Animate:Play(false)
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		JinFengji_HolidayGift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		JinFengji_HolidayGift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		JinFengji_HolidayGift_On_ResetPos()

	end
end


function JinFengji_HolidayGift_Close()
	JinFengji_HolidayGift_GiftItem:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function JinFengji_HolidayGift_On_ResetPos()

	JinFengji_HolidayGift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function JinFengji_HolidayGift_Open()

	JinFengji_HolidayGift_GiftItem:SetActionItem(-1)
	local MyName = Player:GetName()
	JinFengji_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{JFZH_200721_11}",MyName))
	local kjtype   = KaJi:LuaFnGetKaJiType(96)
	if kjtype == 1 then
		local theAction = DataPool:CreateActionItemForShow(g_itemid_ks, 1)
		if theAction:GetID() ~= 0 then
			JinFengji_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			JinFengji_HolidayGift_GiftItem:Show();
		end
	else
		local theAction = DataPool:CreateActionItemForShow(g_itemid, 1)
		if theAction:GetID() ~= 0 then
			JinFengji_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			JinFengji_HolidayGift_GiftItem:Show();
		end
	end
	
end	

--=========
-- 点击领奖
--=========
function JinFengji_HolidayGift_GetClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888129 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end
	
