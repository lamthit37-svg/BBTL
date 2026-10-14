local g_Frame_UnifiedPosition
local g_itemid = 38002002
local g_itemid_kj = 38003024 --卡级服展示道具

--=========
-- PreLoad
--=========
function DuanWu_HolidayGift_PreLoad()
	this:RegisterEvent("UI_COMMAND", true) --打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false) --进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("2019QIXI_CLOSE",false)
end

--=========
-- OnLoad
--=========
function DuanWu_HolidayGift_OnLoad()
	g_Frame_UnifiedPosition = DuanWu_HolidayGift_Frame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function DuanWu_HolidayGift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 50509702) then
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			DuanWu_HolidayGift_Open(Get_XParam_INT(1))
			this:Show()
		elseif bShow == 2 then
			this:Hide()
			DuanWu_HolidayGift_GiftItem_Animate:Play(false)
		end

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DuanWu_HolidayGift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
		DuanWu_HolidayGift_On_ResetPos()

	end
end

--=========
-- 关闭
--=========
function DuanWu_HolidayGift_Close()
	DuanWu_HolidayGift_GiftItem:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function DuanWu_HolidayGift_On_ResetPos()
	DuanWu_HolidayGift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 打开
--=========
function DuanWu_HolidayGift_Open(have_gotten)
	local MyName = Player:GetName()
	DuanWu_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{DWLB_210427_05}", MyName))

	local itemid = nil
	if Player:GetData("IsOriginalJD") == 1 then
		itemid = 38008564
	elseif KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(75) > 0 then  --卡级
		itemid = g_itemid_kj
	else
		itemid = g_itemid
	end

	if(itemid == nil)then
		DuanWu_HolidayGift_GiftItem:SetActionItem(-1)
		DuanWu_HolidayGift_GiftItem:Hide()
		return
	end

	local theAction = DataPool:CreateActionItemForShow(itemid, 1)
	local idActionItem = theAction:GetID()

	if idActionItem ~= 0 then
		DuanWu_HolidayGift_GiftItem:SetActionItem(idActionItem)
		DuanWu_HolidayGift_GiftItem:Show()
		if have_gotten ~= 1 then
			DuanWu_HolidayGift_GiftItem_Animate:Play(true)
		end
	else
		DuanWu_HolidayGift_GiftItem:SetActionItem(-1)
		DuanWu_HolidayGift_GiftItem:Hide()
	end
end

--=========
-- 点击领奖
--=========
function DuanWu_HolidayGift_GetClick(  )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 505097 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end