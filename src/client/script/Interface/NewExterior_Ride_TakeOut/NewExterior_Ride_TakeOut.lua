-- 取出坐骑

local g_NewExterior_Ride_TakeOut_UnifiedPosition;

local g_NewExterior_Ride_TakeOut_ExteriorId = -1
local g_NewExterior_Ride_TakeOut_ColorIdx = -1
local g_NewExterior_Ride_TakeOut_ExpendItem = 0
local g_NewExterior_Ride_TakeOut_ExpendNum = 0
local g_NewExterior_Ride_TakeOut_AvailableItemCount = 0
local g_NewExterior_Ride_TakeOut_TuJian = 0

local g_NewExterior_Ride_TakeOut_ReverseItem = 0

local g_ExteriorType = 0

function NewExterior_Ride_TakeOut_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	
end

function NewExterior_Ride_TakeOut_OnLoad()

	g_NewExterior_Ride_TakeOut_UnifiedPosition = NewExterior_Ride_TakeOut_Frame:GetProperty("UnifiedPosition");

end

function NewExterior_Ride_TakeOut_OnHidden()

	NewExterior_Ride_TakeOut_Close_Clicked()
	
end

function NewExterior_Ride_TakeOut_Close_Clicked()

	NewExterior_Ride_TakeOut_Item:SetActionItem(-1)
	NewExterior_Ride_TakeOut_ItemName:SetText("")
	
	NewExterior_Ride_TakeOut_GradeNum_Text:SetText("")
	NewExterior_Ride_TakeOut_ItemConsumeNum:SetText("")
	NewExterior_Ride_TakeOut_ItemHoldingNum:SetText("")

	this:Hide()
	
end

function NewExterior_Ride_TakeOut_ResetPos()

	NewExterior_Ride_TakeOut_Frame:SetProperty("UnifiedPosition", g_NewExterior_Ride_TakeOut_UnifiedPosition);
  
end

function NewExterior_Ride_TakeOut_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99990001 ) then 
		
		if Get_XParam_INT(0) == 0 then
			NewExterior_Ride_TakeOut_Close_Clicked()
			return 
		end
		g_ExteriorType = 0
		g_NewExterior_Ride_TakeOut_ExteriorId = Get_XParam_INT(1) 
		g_NewExterior_Ride_TakeOut_ReverseItem = Get_XParam_INT(2) 
		g_NewExterior_Ride_TakeOut_ExpendItem = Get_XParam_INT(3) 
		g_NewExterior_Ride_TakeOut_ExpendNum = Get_XParam_INT(4) 
		g_NewExterior_Ride_TakeOut_AvailableItemCount = Get_XParam_INT(5) 
		g_NewExterior_Ride_TakeOut_TuJian = Get_XParam_INT(6) 
	
		NewExterior_Ride_TakeOut_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99990002 then 
		if Get_XParam_INT(0) == 0 then
			NewExterior_Ride_TakeOut_Close_Clicked()
			return 
		end
		
		g_ExteriorType = 2
		g_NewExterior_Ride_TakeOut_ExteriorId = Get_XParam_INT(1) 
		g_NewExterior_Ride_TakeOut_ReverseItem = Get_XParam_INT(2) 
		g_NewExterior_Ride_TakeOut_ExpendItem = Get_XParam_INT(3) 
		g_NewExterior_Ride_TakeOut_ExpendNum = Get_XParam_INT(4) 
		g_NewExterior_Ride_TakeOut_AvailableItemCount = Get_XParam_INT(5) 
		g_NewExterior_Ride_TakeOut_TuJian = Get_XParam_INT(6) 
		
		if g_NewExterior_Ride_TakeOut_ExteriorId == 16 then
			g_NewExterior_Ride_TakeOut_ColorIdx = Get_XParam_INT(7)
		end

		NewExterior_Ride_TakeOut_Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if this:IsVisible() then
			NewExterior_Ride_TakeOut_Close_Clicked()
			return
		end
	elseif(event == "PACKAGE_ITEM_CHANGED_EX") then	
	
		if g_NewExterior_Ride_TakeOut_ExpendItem > 0 then
			local itemstr = "#cffe1b8"..DataPool:Lua_GetItemNameByIndex( g_NewExterior_Ride_TakeOut_ExpendItem )	
			g_NewExterior_Ride_TakeOut_AvailableItemCount = PlayerPackage:CountAvailableItemByIDTable(g_NewExterior_Ride_TakeOut_ExpendItem)		
			local str = ScriptGlobal_Format("#{QCZJ_220425_9}", itemstr, g_NewExterior_Ride_TakeOut_AvailableItemCount)
			NewExterior_Ride_TakeOut_ItemHoldingNum:SetText(str)
		end
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		NewExterior_Ride_TakeOut_Close_Clicked()

	elseif (event == "ADJEST_UI_POS" ) then
		NewExterior_Ride_TakeOut_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewExterior_Ride_TakeOut_ResetPos()
	end
end

function NewExterior_Ride_TakeOut_Show()
	-- 坐骑
	NewExterior_Ride_TakeOut_Item:SetActionItem(-1)
	NewExterior_Ride_TakeOut_ItemName:SetText("")
	if g_ExteriorType == 2 and g_NewExterior_Ride_TakeOut_ExteriorId == 16 then
		DataPool:ClearActionItemForShow()
	end
	if g_NewExterior_Ride_TakeOut_ReverseItem > 0 then
		local theAction = DataPool:CreateActionItemForShow(g_NewExterior_Ride_TakeOut_ReverseItem, 1)
		if theAction:GetID() ~= 0 then
			NewExterior_Ride_TakeOut_Item:SetActionItem(theAction:GetID())
			NewExterior_Ride_TakeOut_ItemName:SetText("#cffe1b8"..theAction:GetName())
		end
	end

	if g_NewExterior_Ride_TakeOut_ExpendItem > 0 then
		local itemstr = "#cffe1b8"..DataPool:Lua_GetItemNameByIndex( g_NewExterior_Ride_TakeOut_ExpendItem )
		
		--所消耗道具
		local str = ScriptGlobal_Format("#{QCZJ_220425_7}", itemstr, g_NewExterior_Ride_TakeOut_ExpendNum)
		NewExterior_Ride_TakeOut_ItemConsumeNum:SetText(str)
		
		str = ScriptGlobal_Format("#{QCZJ_220425_9}", itemstr, g_NewExterior_Ride_TakeOut_AvailableItemCount)
		NewExterior_Ride_TakeOut_ItemHoldingNum:SetText(str)
	end
	
	-- 衣裳值
	str = ScriptGlobal_Format("#{QCZJ_220425_11}", g_NewExterior_Ride_TakeOut_TuJian)
	NewExterior_Ride_TakeOut_GradeNum_Text:SetText(str)
	
	if g_ExteriorType == 0 then
		NewExterior_Ride_TakeOut_DragTitleBK:SetImage("set:NewExterior5 image:QuHui_Title")
		NewExterior_Ride_TakeOut_ItemInfo_Text:SetText("#{QCZJ_220425_4}")
	elseif g_ExteriorType == 2 then
		NewExterior_Ride_TakeOut_DragTitleBK:SetImage("")
		NewExterior_Ride_TakeOut_ItemInfo_Text:SetText("#{JWFT_231115_8}")
	end
	this:Show()

end

function NewExterior_Ride_TakeOut_OK_Clicked()

	if g_ExteriorType == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ReverseExteriorRideToItem")
			Set_XSCRIPT_ScriptID(999900)
			Set_XSCRIPT_Parameter(0, g_NewExterior_Ride_TakeOut_ExteriorId)
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_ExteriorType == 2 then
		if g_NewExterior_Ride_TakeOut_ExteriorId == 16 then

			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ReverseExteriorFutiToItemSpecial")
				Set_XSCRIPT_ScriptID(999900)
				Set_XSCRIPT_Parameter(0, g_NewExterior_Ride_TakeOut_ExteriorId)
				Set_XSCRIPT_Parameter(1, 0)
				Set_XSCRIPT_Parameter(2, g_NewExterior_Ride_TakeOut_ColorIdx)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()	

		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ReverseExteriorFutiToItem")
				Set_XSCRIPT_ScriptID(999900)
				Set_XSCRIPT_Parameter(0, g_NewExterior_Ride_TakeOut_ExteriorId)
				Set_XSCRIPT_Parameter(1, 0)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
		end
		
	end
	
end

