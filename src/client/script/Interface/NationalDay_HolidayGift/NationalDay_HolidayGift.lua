local g_Frame_UnifiedPosition
local g_itemid = 38002861
--=========
-- PreLoad()
--=========
function NationalDay_HolidayGift_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function NationalDay_HolidayGift_OnLoad()
	
	g_Frame_UnifiedPosition = NationalDay_HolidayGift_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function NationalDay_HolidayGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88811501) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			NationalDay_HolidayGift_Open()
			this:Show()
		elseif bShow == 2 then
		
			this:Hide()
			NationalDay_HolidayGift_GiftItem_Animate:Play(false)
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		NationalDay_HolidayGift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		NationalDay_HolidayGift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		NationalDay_HolidayGift_On_ResetPos()

	end
end


function NationalDay_HolidayGift_Close()
	NationalDay_HolidayGift_GiftItem:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function NationalDay_HolidayGift_On_ResetPos()

	NationalDay_HolidayGift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function NationalDay_HolidayGift_Open()

	NationalDay_HolidayGift_GiftItem:SetActionItem(-1)
	local MyName = Player:GetName()
	NationalDay_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{GQZH_200714_11}",MyName))
	local kjtype   = KaJi:LuaFnGetKaJiType(111)
	if kjtype == 1 then
		local theAction = DataPool:CreateActionItemForShow(38003043, 1)
		if theAction:GetID() ~= 0 then
			NationalDay_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			NationalDay_HolidayGift_GiftItem:Show();
		end
	else
		local theAction = DataPool:CreateActionItemForShow(g_itemid, 1)
		if theAction:GetID() ~= 0 then
			NationalDay_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			NationalDay_HolidayGift_GiftItem:Show();
		end
	end
	
end	

--=========
-- 点击领奖
--=========
function NationalDay_HolidayGift_GetClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888115 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end
	
