local m_HolidayGift_Frame_UnifiedXPosition
local m_HolidayGift_Frame_UnifiedYPosition
 
--预加载函数，可以而且只能在这里注册脚本关心的事件
function Ertongjie_HolidayGift_PreLoad() 
	this:RegisterEvent("UI_COMMAND",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Ertongjie_HolidayGift_OnLoad()
	-- 保存界面的默认相对位置
	m_HolidayGift_Frame_UnifiedXPosition	= Ertongjie_HolidayGift_Frame:GetProperty("UnifiedXPosition");
	m_HolidayGift_Frame_UnifiedYPosition	= Ertongjie_HolidayGift_Frame:GetProperty("UnifiedYPosition"); 
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Ertongjie_HolidayGift_ResetPos()
	Ertongjie_HolidayGift_Frame:SetProperty("UnifiedXPosition", m_HolidayGift_Frame_UnifiedXPosition);
	Ertongjie_HolidayGift_Frame:SetProperty("UnifiedYPosition", m_HolidayGift_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Ertongjie_HolidayGift_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 23200704 then
		if (this:IsVisible()) then
			Ertongjie_HolidayGift_Close()
			return
		end
		Ertongjie_HolidayGift_Show() 
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Ertongjie_HolidayGift_Close()
	elseif event == "ADJEST_UI_POS" then
		Ertongjie_HolidayGift_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Ertongjie_HolidayGift_ResetPos()
	end
end

--显示UI
function Ertongjie_HolidayGift_Show()  
	local itemid = Get_XParam_INT(0)
	Ertongjie_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{ETJZH_220414_8}", Player:GetName()))
	local theAction = DataPool:CreateActionItemForShow(itemid, 1) 
	if (theAction:GetID() ~= 0) then
		Ertongjie_HolidayGift_GiftItem:SetActionItem(theAction:GetID())  
	end 
	this:Show() 
end
--隐藏UI
function Ertongjie_HolidayGift_Close() 
	this:Hide()
end
 
function Ertongjie_HolidayGift_GetClick()  
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("Get_Gift")
	Set_XSCRIPT_ScriptID(232007) 
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
  
  