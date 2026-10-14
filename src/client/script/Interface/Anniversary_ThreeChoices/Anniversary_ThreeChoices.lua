----------------------
-- Anniversary_ThreeChoices ---
----------------------
local g_Anniversary_ThreeChoices_UnifiedPosition = nil
local g_Anniversary_ThreeChoices_CurSelect = 0
local g_Anniversary_ThreeChoices_CurIdx = 0

local g_Anniversary_ThreeChoices_List = {}

function Anniversary_ThreeChoices_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Anniversary_ThreeChoices_OnLoad()

	g_Anniversary_ThreeChoices_UnifiedPosition = Anniversary_ThreeChoices_Frame_BK:GetProperty("UnifiedPosition")

	g_Anniversary_ThreeChoices_List = {
		[3] = {Anniversary_ThreeChoices_Page_Lace1Item, Anniversary_ThreeChoices_Page_Lace1Item_Mask, Anniversary_ThreeChoices_Page_Lace1Item_Tip},
		[4] = {Anniversary_ThreeChoices_Page_Lace2Item, Anniversary_ThreeChoices_Page_Lace2Item_Mask, Anniversary_ThreeChoices_Page_Lace2Item_Tip},
	}
	
end

--===============================================
-- OnEvent()
--===============================================
function Anniversary_ThreeChoices_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89340111) then
		local iret = Get_XParam_INT(0)		
		if iret == 0 then
			Anniversary_ThreeChoices_OnHiden()
			return
		end	
		
		g_Anniversary_ThreeChoices_CurSelect = 0
		
		g_Anniversary_ThreeChoices_CurIdx = Get_XParam_INT(1)
		
		local itemcount = 0
		for i = 2, 3 do
			local itemid = Get_XParam_INT(i)
			local itemnum = Get_XParam_INT(i+2)
			
			if itemid > 0 and itemnum > 0 then
				local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
				if theAction:GetID() ~= 0 then
					g_Anniversary_ThreeChoices_List[i+1][1]:SetActionItem(theAction:GetID());
					g_Anniversary_ThreeChoices_List[i+1][1]:Show()
					
					local itemstr = "#L"..DataPool:Lua_GetItemNameByIndex( itemid )
					g_Anniversary_ThreeChoices_List[i+1][3]:SetText( "#L"..itemstr )
					g_Anniversary_ThreeChoices_List[i+1][3]:Show()
					itemcount = itemcount + 1
				end
			else
				g_Anniversary_ThreeChoices_List[i+1][1]:Hide()
				g_Anniversary_ThreeChoices_List[i+1][3]:Hide()
			end	

			g_Anniversary_ThreeChoices_List[i+1][2]:Hide()			
		end
		
		this:Show()
		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
	
		Anniversary_ThreeChoices_ResetPos()
		
	elseif(event == "ADJEST_UI_POS") then
	
		Anniversary_ThreeChoices_ResetPos()
		
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
	
		Anniversary_ThreeChoices_OnHiden()
		
	end
end

function Anniversary_ThreeChoices_ResetPos()

	Anniversary_ThreeChoices_Frame_BK:SetProperty("UnifiedPosition", g_Anniversary_ThreeChoices_UnifiedPosition)
	
end

function Anniversary_ThreeChoices_OnHiden()

	g_Anniversary_ThreeChoices_CurSelect = 0
	
	g_Anniversary_ThreeChoices_List[3][1]:SetActionItem(-1);
	g_Anniversary_ThreeChoices_List[4][1]:SetActionItem(-1);
	
	this:Hide()
	
end

function Anniversary_ThreeChoices_Close()

	Anniversary_ThreeChoices_OnHiden()
	
end

function Anniversary_ThreeChoices_Choose( btn )
	
	if g_Anniversary_ThreeChoices_List[btn] ~= nil then
	
		for i = 3, 4 do
			if i == btn then
				g_Anniversary_ThreeChoices_List[i][2]:Show()
				g_Anniversary_ThreeChoices_CurSelect = i + 1
			else
				g_Anniversary_ThreeChoices_List[i][2]:Hide()
			end
		end
	
	end
	
end

function Anniversary_ThreeChoices_GetClick()
	
	if g_Anniversary_ThreeChoices_CurSelect == 0 then
		PushDebugMessage("#{MHSD_191203_49}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AnniPreGetFanLi" )
		Set_XSCRIPT_ScriptID(893401)
		Set_XSCRIPT_Parameter(0, g_Anniversary_ThreeChoices_CurIdx)
		Set_XSCRIPT_Parameter(1, g_Anniversary_ThreeChoices_CurSelect)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
	
end

