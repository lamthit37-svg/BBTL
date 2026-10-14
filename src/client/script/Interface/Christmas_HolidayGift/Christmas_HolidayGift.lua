local g_Frame_UnifiedXPosition_Christmas_HolidayGift;
local g_Frame_UnifiedYPosition_Christmas_HolidayGift;

local g_LibaoId = 39923652  -- 礼包id
local g_nGetFlag = 0
function Christmas_HolidayGift_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")
	
end

function Christmas_HolidayGift_OnLoad()
	g_Frame_UnifiedXPosition_Christmas_HolidayGift	= Christmas_HolidayGift_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition_Christmas_HolidayGift	= Christmas_HolidayGift_Frame:GetProperty("UnifiedYPosition");	
end

function Christmas_HolidayGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber( arg0 ) == 88830701) then
		local nFlag = Get_XParam_INT( 0 );
		if nFlag == 1 then		
			g_nGetFlag = Get_XParam_INT( 1 )
			Christmas_HolidayGift_UpdateUI( )
		elseif nFlag == 0 then
			Christmas_HolidayGift_Close()
		end
	
	elseif (event == "ADJEST_UI_POS" ) then
		Christmas_HolidayGift_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Christmas_HolidayGift_ResetPos()			
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Christmas_HolidayGift_Close()
	end
	
end

function Christmas_HolidayGift_UpdateUI( )
	local MyName = Player:GetName()
	Christmas_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{QXZH_200708_12}",MyName))
	
	local LibaoID = g_LibaoId
	if KaJi:LuaFnGetKaJiType(30) > 0 then
		LibaoID = 39923653
	end
	local actionBonus = DataPool:CreateActionItemForShow(LibaoID,1)
	if actionBonus:GetID() ~= 0 then
		Christmas_HolidayGift_GiftItem:SetActionItem(actionBonus:GetID())	
	end
		
	this:Show()
end

function Christmas_HolidayGift_ResetPos()
	Christmas_HolidayGift_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition_Christmas_HolidayGift);
	Christmas_HolidayGift_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition_Christmas_HolidayGift);
end

function Christmas_HolidayGift_OnHiden()
	Christmas_HolidayGift_Close()
end

function Christmas_HolidayGift_Close()
	this:Hide()
end

 function Christmas_HolidayGift_GetClick()
 	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGetLiBao")
		Set_XSCRIPT_ScriptID(888307)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end