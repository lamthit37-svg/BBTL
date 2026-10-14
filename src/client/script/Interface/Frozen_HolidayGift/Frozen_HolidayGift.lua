
local g_Frame_UnifiedPosition
local g_itemid =  0
--=========
-- PreLoad()
--=========
function Frozen_HolidayGift_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function Frozen_HolidayGift_OnLoad()
	
	g_Frame_UnifiedPosition = Frozen_HolidayGift_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function Frozen_HolidayGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 50101001) then
	
		local bShow = Get_XParam_INT(0)
		g_itemid = Get_XParam_INT(1)
		if bShow == 1 then
			Frozen_HolidayGift_Open()
			this:Show()
		elseif bShow == 2 then		
			this:Hide()
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Frozen_HolidayGift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Frozen_HolidayGift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		Frozen_HolidayGift_On_ResetPos()

	end
end


function Frozen_HolidayGift_Close()
	Frozen_HolidayGift_GiftItem:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function Frozen_HolidayGift_On_ResetPos()

	Frozen_HolidayGift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function Frozen_HolidayGift_Open()
	local MyName = Player:GetName()
	Frozen_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{HZJZH_211221_21}",MyName))
	Frozen_HolidayGift_GiftItem:SetActionItem(-1) 
	local theAction = DataPool:CreateActionItemForShow(g_itemid, 1)
	if theAction:GetID() ~= 0 then
		Frozen_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
		Frozen_HolidayGift_GiftItem:Show();
	end
	
end	

--=========
-- 点击领奖
--=========
function Frozen_HolidayGift_GetClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 501010 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end
	
