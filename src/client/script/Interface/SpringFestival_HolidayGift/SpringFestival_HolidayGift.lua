--【2020Q4】春节整合界面设计-节日礼包界面

local g_Frame_UnifiedPosition

--=========
-- PreLoad()
--=========
function SpringFestival_HolidayGift_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function SpringFestival_HolidayGift_OnLoad()
	
	g_Frame_UnifiedPosition = SpringFestival_HolidayGift_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function SpringFestival_HolidayGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88832801) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			SpringFestival_HolidayGift_Open()
			this:Show()
		elseif bShow == 2 then		
			this:Hide()
			SpringFestival_HolidayGift_GiftItem_Animate:Play(false)
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		SpringFestival_HolidayGift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_HolidayGift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		SpringFestival_HolidayGift_On_ResetPos()

	end
end


function SpringFestival_HolidayGift_Close()
	SpringFestival_HolidayGift_GiftItem:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function SpringFestival_HolidayGift_On_ResetPos()

	SpringFestival_HolidayGift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function SpringFestival_HolidayGift_Open()

	SpringFestival_HolidayGift_GiftItem:SetActionItem(-1)
	local MyName = Player:GetName()
	SpringFestival_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{RACL_201224_17}",MyName))
	local nItemId = 38005170
	if KaJi:LuaFnGetKaJiType(53) == 1 then
		nItemId = 38003016
	end
	local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
	if theAction:GetID() ~= 0 then
		SpringFestival_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
		SpringFestival_HolidayGift_GiftItem:Show();
	end
	
end	

--=========
-- 点击领奖
--=========
function SpringFestival_HolidayGift_GetClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888328 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end
	
