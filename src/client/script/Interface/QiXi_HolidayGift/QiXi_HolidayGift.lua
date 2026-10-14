local g_Frame_UnifiedPosition
local g_itemid = 38002830

local g_QiXi_ScriptId = -1
--=========
-- PreLoad()
--=========
function QiXi_HolidayGift_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("2019QIXI_CLOSE",false)

end

--=========
-- OnLoad()
--=========
function QiXi_HolidayGift_OnLoad()
	
	g_Frame_UnifiedPosition = QiXi_HolidayGift_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function QiXi_HolidayGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88811301) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			QiXi_HolidayGift_Open()
			this:Show()
		elseif bShow == 2 then
		
			this:Hide()
			QiXi_HolidayGift_GiftItem_Animate:Play(false)
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89377602) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			g_QiXi_ScriptId = Get_XParam_INT(1)
			local nItemId = Get_XParam_INT(2)
			if nItemId == nil or nItemId <= 0 then
				return
			end
			
			QiXi_HolidayGift_OpenLiBao(nItemId)
			this:Show()
			
		elseif bShow == 2 then
		
			this:Hide()
			QiXi_HolidayGift_GiftItem_Animate:Play(false)
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		QiXi_HolidayGift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		QiXi_HolidayGift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		QiXi_HolidayGift_On_ResetPos()
	elseif event == "2019QIXI_CLOSE" then
		QiXi_HolidayGift_Close()

	end
end


function QiXi_HolidayGift_Close()
	g_QiXi_ScriptId = -1
	QiXi_HolidayGift_GiftItem:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function QiXi_HolidayGift_On_ResetPos()

	QiXi_HolidayGift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开 
--=========
function QiXi_HolidayGift_OpenLiBao(nItemId)

	QiXi_HolidayGift_GiftItem:SetActionItem(-1)
	local MyName = Player:GetName()
	QiXi_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{QXZH_200708_12}",MyName))
	
	local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
	if theAction:GetID() ~= 0 then
		QiXi_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
		QiXi_HolidayGift_GiftItem:Show();
	end
	
end

--=========
-- 打开
--=========
function QiXi_HolidayGift_Open()

	QiXi_HolidayGift_GiftItem:SetActionItem(-1)
	local MyName = Player:GetName()
	QiXi_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{QXZH_200708_12}",MyName))
	local kjtype   = KaJi:LuaFnGetKaJiType(93)
	if kjtype == 1 then
		local theAction = DataPool:CreateActionItemForShow(38003033, 1)
		if theAction:GetID() ~= 0 then
			QiXi_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			QiXi_HolidayGift_GiftItem:Show();
		end
	else
		local theAction = DataPool:CreateActionItemForShow(g_itemid, 1)
		if theAction:GetID() ~= 0 then
			QiXi_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			QiXi_HolidayGift_GiftItem:Show();
		end
	end
	
end	

--=========
-- 点击领奖
--=========
function QiXi_HolidayGift_GetClick(  )

	if g_QiXi_ScriptId == 893776 then		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetQiXiGuideLiBao")
			Set_XSCRIPT_ScriptID(893776)
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888113 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end
	
