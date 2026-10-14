------------------------
-- XiGua_Shop_Choose ---
------------------------
local g_XiGua_Shop_Choose_UnifiedPosition = nil
local g_XiGua_Shop_Choose_CurSelect = 0
local g_XiGua_Shop_Choose_CurIdx = 0

local g_XiGua_Shop_Choose_List = {}

function XiGua_Shop_Choose_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function XiGua_Shop_Choose_OnLoad()

	g_XiGua_Shop_Choose_UnifiedPosition = XiGua_Shop_Choose_Frame_BK:GetProperty("UnifiedPosition")

	g_XiGua_Shop_Choose_List = {
		[1] = {XiGua_Shop_Choose_Page_Lace1Item, XiGua_Shop_Choose_Page_Lace1Item_Mask, XiGua_Shop_Choose_Page_Lace1Item_Tip},
		[2] = {XiGua_Shop_Choose_Page_Lace2Item, XiGua_Shop_Choose_Page_Lace3Item_Mask, XiGua_Shop_Choose_Page_Lace2Item_Tip},
	}
	
end

--===============================================
-- OnEvent()
--===============================================
function XiGua_Shop_Choose_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89286610) then
		local iret = Get_XParam_INT(0)		
		if iret == 0 then
			XiGua_Shop_Choose_OnHiden()
			return
		end	
		
		g_XiGua_Shop_Choose_CurSelect = 0
		
		g_XiGua_Shop_Choose_CurIdx = Get_XParam_INT(1)
		
		local itemid = Get_XParam_INT(2)
		local itemnum = Get_XParam_INT(3)			
		if itemid > 0 and itemnum > 0 then
			local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
			if theAction:GetID() ~= 0 then
				g_XiGua_Shop_Choose_List[1][1]:SetActionItem(theAction:GetID());
				g_XiGua_Shop_Choose_List[1][1]:Show()
				
				local itemstr = "#L"..DataPool:Lua_GetItemNameByIndex( itemid )
				g_XiGua_Shop_Choose_List[1][3]:SetText( itemstr )
				g_XiGua_Shop_Choose_List[1][3]:Show()
			end
			g_XiGua_Shop_Choose_List[1][2]:Hide()
		end	
		
		local itemid2 = Get_XParam_INT(4)
		local itemnum2 = Get_XParam_INT(5)			
		if itemid2 > 0 and itemnum2 > 0 then
			local theAction = DataPool:CreateActionItemForShow(itemid2, itemnum2)
			if theAction:GetID() ~= 0 then
				g_XiGua_Shop_Choose_List[2][1]:SetActionItem(theAction:GetID());
				g_XiGua_Shop_Choose_List[2][1]:Show()
				
				local itemstr = "#L"..DataPool:Lua_GetItemNameByIndex( itemid2 )
				g_XiGua_Shop_Choose_List[2][3]:SetText( itemstr )
				g_XiGua_Shop_Choose_List[2][3]:Show()
			end
			g_XiGua_Shop_Choose_List[2][2]:Hide()
		end	
				
		this:Show()
		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
	
		XiGua_Shop_Choose_ResetPos()
		
	elseif(event == "ADJEST_UI_POS") then
	
		XiGua_Shop_Choose_ResetPos()
		
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
	
		XiGua_Shop_Choose_OnHiden()
		
	end
end

function XiGua_Shop_Choose_ResetPos()

	XiGua_Shop_Choose_Frame_BK:SetProperty("UnifiedPosition", g_XiGua_Shop_Choose_UnifiedPosition)
	
end

function XiGua_Shop_Choose_OnHiden()

	g_XiGua_Shop_Choose_CurSelect = 0
	
	this:Hide()
	
end

function XiGua_Shop_Choose_Close()

	XiGua_Shop_Choose_OnHiden()
	
end

function XiGua_Shop_Choose_Choose( btn )
	
	if g_XiGua_Shop_Choose_List[btn] ~= nil then
	
		for i = 1, 2 do
			if i == btn then
				g_XiGua_Shop_Choose_List[i][2]:Show()
				g_XiGua_Shop_Choose_CurSelect = i
			else
				g_XiGua_Shop_Choose_List[i][2]:Hide()
			end
		end
	
	end
	
end

function XiGua_Shop_Choose_GetClick()
	
	if g_XiGua_Shop_Choose_CurSelect == 0 then
		PushDebugMessage("#{XGSD_200609_41}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetXiGuaShopFanLi" )
		Set_XSCRIPT_ScriptID(892866)
		Set_XSCRIPT_Parameter(0, g_XiGua_Shop_Choose_CurIdx)
		Set_XSCRIPT_Parameter(1, g_XiGua_Shop_Choose_CurSelect)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
	
end

