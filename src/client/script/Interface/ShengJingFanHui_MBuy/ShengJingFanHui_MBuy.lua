
local g_ShengJingFanHui_MBuy_Frame_UnifiedPosition
local g_ShengJingFanHui_MBuy_TableId = -1
local g_ShengJingFanHui_MBuy_Price = 1
local g_ShengJingFanHui_MBuy_PaintMD = 0
local g_ShengJingFanHui_MBuy_CurBuyTimes = 0

function ShengJingFanHui_MBuy_PreLoad()
	this:RegisterEvent("SJFH_OPEN_BUY",true)
	this:RegisterEvent("SJFH_CLOSE_POPUI",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

function ShengJingFanHui_MBuy_OnLoad()
	g_ShengJingFanHui_MBuy_Frame_UnifiedPosition = ShengJingFanHui_MBuy_Frame:GetProperty("UnifiedPosition")

end

function ShengJingFanHui_MBuy_OnEvent(event)
	if event == "SJFH_OPEN_BUY" then
		g_ShengJingFanHui_MBuy_TableId = tonumber(arg0)
		g_ShengJingFanHui_MBuy_PaintMD = tonumber(arg1)
		g_ShengJingFanHui_MBuy_CurBuyTimes = tonumber(arg2)
		if g_ShengJingFanHui_MBuy_TableId ~= nil and g_ShengJingFanHui_MBuy_PaintMD ~= nil and g_ShengJingFanHui_MBuy_CurBuyTimes ~= nil then
			this:Show()
			ShengJingFanHui_MBuy_Open()
		end
	elseif event == "SJFH_CLOSE_POPUI" then
		ShengJingFanHui_MBuy_Close_Clicked()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ShengJingFanHui_MBuy_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ShengJingFanHui_MBuy_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ShengJingFanHui_MBuy_Close_Clicked()
	end
	
end

function ShengJingFanHui_MBuy_Open()
	local kjtype   = KaJi:LuaFnGetKaJiType(135)
	local iteminfo = DataPool:TBSearch_Index_EQU("DBC_SJFH", g_ShengJingFanHui_MBuy_TableId)
	if kjtype == 1 then
		iteminfo = DataPool:TBSearch_Index_EQU("DBC_SJFH_KAJI_1", g_ShengJingFanHui_MBuy_TableId)
	end
	if iteminfo then
		local theAction = DataPool:CreateActionItemForShow(iteminfo.nShowItemID, 1)
		if theAction:GetID() ~= 0 then
			ShengJingFanHui_MBuy_But:SetActionItem(theAction:GetID())
		end
		ShengJingFanHui_MBuy_ItemInfo_Text:SetText("#cfff263"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))

		ShengJingFanHui_MBuy_ItemInfo_Shanshuihua:SetText(ScriptGlobal_Format("#{SJFH_230425_144}",iteminfo.nPrice))

		ShengJingFanHui_ItemNumber:SetText(iteminfo.nSaleCount)
		g_ShengJingFanHui_MBuy_Price = iteminfo.nPrice
		if iteminfo.nLimit > 0 then
			ShengJingFanHui_ItemLimitNumberBK:Show()
			ShengJingFanHui_ItemLimitNumber:SetText(tostring(iteminfo.nLimit-g_ShengJingFanHui_MBuy_CurBuyTimes))
		else
			ShengJingFanHui_ItemLimitNumberBK:Hide()
		end

	end

	ShengJingFanHui_MBuy_Price_Shanshuihua:SetText(ScriptGlobal_Format("#{SJFH_230425_148}", g_ShengJingFanHui_MBuy_PaintMD))

	ShengJingFanHui_MBuy_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	ShengJingFanHui_MBuy_InputNum:SetText("1")		


end

function ShengJingFanHui_MBuy_On_ResetPos()
	ShengJingFanHui_MBuy_Frame:SetProperty("UnifiedPosition", g_ShengJingFanHui_MBuy_Frame_UnifiedPosition)

end

function ShengJingFanHui_MBuy_GetMax()

	local kjtype   = KaJi:LuaFnGetKaJiType(135)
	local iteminfo = DataPool:TBSearch_Index_EQU("DBC_SJFH",g_ShengJingFanHui_MBuy_TableId)
	if kjtype == 1 then
		iteminfo = DataPool:TBSearch_Index_EQU("DBC_SJFH_KAJI_1",g_ShengJingFanHui_MBuy_TableId)
	end
	if g_ShengJingFanHui_MBuy_Price > 0 and iteminfo then
		local MaxCount =  math.floor(g_ShengJingFanHui_MBuy_PaintMD / g_ShengJingFanHui_MBuy_Price)
		if iteminfo.nLimit > 0 and MaxCount > iteminfo.nLimit - g_ShengJingFanHui_MBuy_CurBuyTimes then
			MaxCount = iteminfo.nLimit - g_ShengJingFanHui_MBuy_CurBuyTimes
		end
		return MaxCount
	end
	return 0
end

--最大按钮点击
function ShengJingFanHui_MBuy_CalMax()
	local MaxCount = ShengJingFanHui_MBuy_GetMax()
	ShengJingFanHui_MBuy_InputNum:SetText(tostring(MaxCount))
end

function ShengJingFanHui_MBuy_TextChanged()
	local num = tonumber(ShengJingFanHui_MBuy_InputNum:GetText())
	
	if g_ShengJingFanHui_MBuy_Price <= 0 then
		return 
	end
	local MaxCount = ShengJingFanHui_MBuy_GetMax()

	if num ~= nil then
		if num > MaxCount then
			num = MaxCount
			ShengJingFanHui_MBuy_InputNum:SetText(tostring(num))
		end
		ShengJingFanHui_MBuy_ItemInfo_Shanshuihua:SetText(ScriptGlobal_Format("#{SJFH_230425_144}",num*g_ShengJingFanHui_MBuy_Price))

	else
		ShengJingFanHui_MBuy_ItemInfo_Shanshuihua:SetText("#L0")
	end


end

--确认购买
function ShengJingFanHui_MBuy_OK_Clicked()
	local count = tonumber(ShengJingFanHui_MBuy_InputNum:GetText())
	if g_ShengJingFanHui_MBuy_Price <= 0 then
		return 
	end
	--PushDebugMessage("g_ShengJingFanHui_MBuy_TableId:"..tostring(g_ShengJingFanHui_MBuy_TableId))
	local MaxCount = ShengJingFanHui_MBuy_GetMax()
	if count == nil then
		PushDebugMessage("#{SJFH_230425_153}")
		return
	end
	if count <= 0 or count > MaxCount then
		PushDebugMessage("#{SJFH_230425_153}")
		return
	end 
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("BuyShopItem")
	Set_XSCRIPT_ScriptID(998544)
	Set_XSCRIPT_Parameter( 0, g_ShengJingFanHui_MBuy_TableId )
	Set_XSCRIPT_Parameter( 1, count )
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

function ShengJingFanHui_MBuy_OnHidden()
	
	g_ShengJingFanHui_MBuy_Price = 1
end

function ShengJingFanHui_MBuy_Close_Clicked()
	this:Hide()
end

