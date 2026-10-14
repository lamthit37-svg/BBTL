----------------------
-- QingMei_ThreeChoices ---
----------------------
local g_QingMei_ThreeChoices_UnifiedPosition = nil
local g_QingMei_ThreeChoices_CurSelect = 0
local g_QingMei_ThreeChoices_CurIdx = 0

local g_QingMei_ThreeChoices_List = {}

function QingMei_ThreeChoices_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function QingMei_ThreeChoices_OnLoad()

	g_QingMei_ThreeChoices_UnifiedPosition = QingMei_ThreeChoices_Frame_BK:GetProperty("UnifiedPosition")

	g_QingMei_ThreeChoices_List = {
		[1] = {QingMei_ThreeChoices_Page_Lace1Item, QingMei_ThreeChoices_Page_Lace1Item_Mask, QingMei_ThreeChoices_Page_Lace1Item_Tip},
		[2] = {QingMei_ThreeChoices_Page_Lace2Item, QingMei_ThreeChoices_Page_Lace2Item_Mask, QingMei_ThreeChoices_Page_Lace2Item_Tip},
		[3] = {QingMei_ThreeChoices_Page_Lace3Item, QingMei_ThreeChoices_Page_Lace3Item_Mask, QingMei_ThreeChoices_Page_Lace3Item_Tip},
	}
	
end

--===============================================
-- OnEvent()
--===============================================
function QingMei_ThreeChoices_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89271905) then
		local iret = Get_XParam_INT(0)		
		if iret == 0 then
			QingMei_ThreeChoices_OnHiden()
			return
		end	
		
		g_QingMei_ThreeChoices_CurSelect = 0
		
		g_QingMei_ThreeChoices_CurIdx = Get_XParam_INT(1)
		
		local itemcount = 0
		for i = 2, 4 do
			local itemid = Get_XParam_INT(i)
			local itemnum = Get_XParam_INT(i+3)
			
			if itemid > 0 and itemnum > 0 then
				local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
				if theAction:GetID() ~= 0 then
					g_QingMei_ThreeChoices_List[i-1][1]:SetActionItem(theAction:GetID());
					g_QingMei_ThreeChoices_List[i-1][1]:Show()
					
					local itemstr = "#L"..DataPool:Lua_GetItemNameByIndex( itemid )
					g_QingMei_ThreeChoices_List[i-1][3]:SetText( itemstr )
					g_QingMei_ThreeChoices_List[i-1][3]:Show()
					itemcount = itemcount + 1
				end
			else
				g_QingMei_ThreeChoices_List[i-1][1]:Hide()
				g_QingMei_ThreeChoices_List[i-1][3]:Hide()
			end	

			g_QingMei_ThreeChoices_List[i-1][2]:Hide()			
		end
		
		if itemcount == 3 then
			g_QingMei_ThreeChoices_List[1][1]:SetProperty("UnifiedPosition","{{0.200000,-32.000000},{0.000000,25.000000}}")
			g_QingMei_ThreeChoices_List[2][1]:SetProperty("UnifiedPosition","{{0.500000,-32.000000},{0.000000,25.000000}}")
			g_QingMei_ThreeChoices_List[3][1]:SetProperty("UnifiedPosition","{{0.800000,-32.000000},{0.000000,25.000000}}")
			
			g_QingMei_ThreeChoices_List[1][3]:SetProperty("UnifiedPosition","{{0.200000,-60.000000},{0.000000,100.000000}}")
			g_QingMei_ThreeChoices_List[2][3]:SetProperty("UnifiedPosition","{{0.500000,-60.000000},{0.000000,100.000000}}")
			g_QingMei_ThreeChoices_List[3][3]:SetProperty("UnifiedPosition","{{0.800000,-60.000000},{0.000000,100.000000}}")
		end
		
		if itemcount == 2 then
			g_QingMei_ThreeChoices_List[1][1]:SetProperty("UnifiedPosition","{{0.350000,-32.000000},{0.000000,25.000000}}")
			g_QingMei_ThreeChoices_List[2][1]:SetProperty("UnifiedPosition","{{0.650000,-32.000000},{0.000000,25.000000}}")
			
			g_QingMei_ThreeChoices_List[1][3]:SetProperty("UnifiedPosition","{{0.350000,-60.000000},{0.000000,100.000000}}")
			g_QingMei_ThreeChoices_List[2][3]:SetProperty("UnifiedPosition","{{0.650000,-60.000000},{0.000000,100.000000}}")
		end
		
		this:Show()
		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
	
		QingMei_ThreeChoices_ResetPos()
		
	elseif(event == "ADJEST_UI_POS") then
	
		QingMei_ThreeChoices_ResetPos()
		
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
	
		QingMei_ThreeChoices_OnHiden()
		
	end
end

function QingMei_ThreeChoices_ResetPos()

	QingMei_ThreeChoices_Frame_BK:SetProperty("UnifiedPosition", g_QingMei_ThreeChoices_UnifiedPosition)
	
end

function QingMei_ThreeChoices_OnHiden()

	g_QingMei_ThreeChoices_CurSelect = 0
	
	this:Hide()
	
end

function QingMei_ThreeChoices_Close()

	QingMei_ThreeChoices_OnHiden()
	
end

function QingMei_ThreeChoices_Choose( btn )
	
	if g_QingMei_ThreeChoices_List[btn] ~= nil then
	
		for i = 1, table.getn(g_QingMei_ThreeChoices_List) do
			if i == btn then
				g_QingMei_ThreeChoices_List[i][2]:Show()
				g_QingMei_ThreeChoices_CurSelect = i
			else
				g_QingMei_ThreeChoices_List[i][2]:Hide()
			end
		end
	
	end
	
end

function QingMei_ThreeChoices_GetClick()
	
	if g_QingMei_ThreeChoices_CurSelect == 0 then
		PushDebugMessage("#{MHSD_191203_49}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetFanLi" )
		Set_XSCRIPT_ScriptID(892719)
		Set_XSCRIPT_Parameter(0, g_QingMei_ThreeChoices_CurIdx)
		Set_XSCRIPT_Parameter(1, g_QingMei_ThreeChoices_CurSelect) --需要选择的物品
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
	
end

