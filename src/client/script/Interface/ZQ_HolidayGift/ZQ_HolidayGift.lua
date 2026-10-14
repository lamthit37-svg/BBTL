local g_Frame_UnifiedPosition
local g_itemid = 38002862
--=========
-- PreLoad()
--=========
function ZQ_HolidayGift_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("2020ZQ_CLOSE",false)

end

--=========
-- OnLoad()
--=========
function ZQ_HolidayGift_OnLoad()
	
	g_Frame_UnifiedPosition = ZQ_HolidayGift_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function ZQ_HolidayGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88813201) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			ZQ_HolidayGift_Open()
			ZQ_HolidayGift_GiftItem_Animate:Play(true)
			this:Show()
			
		elseif bShow == 2 then
		
			this:Hide()
			ZQ_HolidayGift_GiftItem_Animate:Play(false)
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ZQ_HolidayGift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ZQ_HolidayGift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		ZQ_HolidayGift_On_ResetPos()
	elseif event == "2020ZQ_CLOSE" then
		ZQ_HolidayGift_Close()

	end
end


function ZQ_HolidayGift_Close()
	ZQ_HolidayGift_GiftItem:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function ZQ_HolidayGift_On_ResetPos()

	ZQ_HolidayGift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function ZQ_HolidayGift_Open()

	ZQ_HolidayGift_GiftItem:SetActionItem(-1)
	local MyName = Player:GetName()
	ZQ_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{ZQZH_200715_06}",MyName))
	local kjtype   = KaJi:LuaFnGetKaJiType(104)
	if kjtype == 1 then
		local theAction = DataPool:CreateActionItemForShow(38003041, 1)
		if theAction:GetID() ~= 0 then
			ZQ_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			ZQ_HolidayGift_GiftItem:Show();
		end
	else
		local theAction = DataPool:CreateActionItemForShow(g_itemid, 1)
		if theAction:GetID() ~= 0 then
			ZQ_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			ZQ_HolidayGift_GiftItem:Show();
		end
	end
	
end	

--=========
-- 点击领奖
--=========
function ZQ_HolidayGift_GetClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888132 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end
	
