----------------------
-- YuanXiao_Shop_ThreeChoices ---
----------------------
local g_YuanXiao_Shop_ThreeChoices_UnifiedPosition = nil
local g_YuanXiao_Shop_ThreeChoices_CurSelect = 0
local g_YuanXiao_Shop_ThreeChoices_CurIdx = 0

local g_YuanXiao_Shop_ThreeChoices_List = {}

function YuanXiao_Shop_ThreeChoices_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function YuanXiao_Shop_ThreeChoices_OnLoad()

	g_YuanXiao_Shop_ThreeChoices_UnifiedPosition = YuanXiao_Shop_ThreeChoices_Frame_BK:GetProperty("UnifiedPosition")

	g_YuanXiao_Shop_ThreeChoices_List = {
		[3] = {YuanXiao_Shop_ThreeChoices_Page_Lace1Item, YuanXiao_Shop_ThreeChoices_Page_Lace1Item_Mask, YuanXiao_Shop_ThreeChoices_Page_Lace1Item_Tip},
		[4] = {YuanXiao_Shop_ThreeChoices_Page_Lace2Item, YuanXiao_Shop_ThreeChoices_Page_Lace2Item_Mask, YuanXiao_Shop_ThreeChoices_Page_Lace2Item_Tip},
		[5] = {YuanXiao_Shop_ThreeChoices_Page_Lace3Item, YuanXiao_Shop_ThreeChoices_Page_Lace3Item_Mask, YuanXiao_Shop_ThreeChoices_Page_Lace3Item_Tip},
	}
	
end

--===============================================
-- OnEvent()
--===============================================
function YuanXiao_Shop_ThreeChoices_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89071315) then
		local iret = Get_XParam_INT(0)		
		if iret == 0 then
			YuanXiao_Shop_ThreeChoices_OnHiden()
			return
		end	
		
		g_YuanXiao_Shop_ThreeChoices_CurSelect = 0
		
		g_YuanXiao_Shop_ThreeChoices_CurIdx = Get_XParam_INT(1)
		
		--if g_YuanXiao_Shop_ThreeChoices_CurIdx >= 7 and g_YuanXiao_Shop_ThreeChoices_CurIdx <= 9 then
		--	YuanXiao_Shop_ThreeChoices_Page_Tip:Show()
		--else
		--	YuanXiao_Shop_ThreeChoices_Page_Tip:Hide()
		--end
		
		local itemcount = 0
		for i = 2, 4 do
			local itemid = Get_XParam_INT(i)
			local itemnum = Get_XParam_INT(i+3)
			
			if itemid > 0 and itemnum > 0 then
				local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
				if theAction:GetID() ~= 0 then
					g_YuanXiao_Shop_ThreeChoices_List[i+1][1]:SetActionItem(theAction:GetID());
					g_YuanXiao_Shop_ThreeChoices_List[i+1][1]:Show()
					
					local itemstr = "#L"..DataPool:Lua_GetItemNameByIndex( itemid )
					g_YuanXiao_Shop_ThreeChoices_List[i+1][3]:SetText( itemstr )
					g_YuanXiao_Shop_ThreeChoices_List[i+1][3]:Show()
					itemcount = itemcount + 1
				end
			else
				g_YuanXiao_Shop_ThreeChoices_List[i+1][1]:Hide()
				g_YuanXiao_Shop_ThreeChoices_List[i+1][3]:Hide()
			end	

			g_YuanXiao_Shop_ThreeChoices_List[i+1][2]:Hide()			
		end
		
		if itemcount == 3 then
			g_YuanXiao_Shop_ThreeChoices_List[3][1]:SetProperty("UnifiedPosition","{{0.200000,-32.000000},{0.000000,25.000000}}")
			g_YuanXiao_Shop_ThreeChoices_List[4][1]:SetProperty("UnifiedPosition","{{0.500000,-32.000000},{0.000000,25.000000}}")
			g_YuanXiao_Shop_ThreeChoices_List[5][1]:SetProperty("UnifiedPosition","{{0.800000,-32.000000},{0.000000,25.000000}}")
			
			g_YuanXiao_Shop_ThreeChoices_List[3][3]:SetProperty("UnifiedPosition","{{0.200000,-60.000000},{0.000000,100.000000}}")
			g_YuanXiao_Shop_ThreeChoices_List[4][3]:SetProperty("UnifiedPosition","{{0.500000,-60.000000},{0.000000,100.000000}}")
			g_YuanXiao_Shop_ThreeChoices_List[5][3]:SetProperty("UnifiedPosition","{{0.800000,-60.000000},{0.000000,100.000000}}")
		end
		
		if itemcount == 2 then
			g_YuanXiao_Shop_ThreeChoices_List[4][1]:SetProperty("UnifiedPosition","{{0.350000,-32.000000},{0.000000,25.000000}}")
			g_YuanXiao_Shop_ThreeChoices_List[5][1]:SetProperty("UnifiedPosition","{{0.650000,-32.000000},{0.000000,25.000000}}")
			
			g_YuanXiao_Shop_ThreeChoices_List[4][3]:SetProperty("UnifiedPosition","{{0.350000,-60.000000},{0.000000,100.000000}}")
			g_YuanXiao_Shop_ThreeChoices_List[5][3]:SetProperty("UnifiedPosition","{{0.650000,-60.000000},{0.000000,100.000000}}")
		end
		
		this:Show()
		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
	
		YuanXiao_Shop_ThreeChoices_ResetPos()
		
	elseif(event == "ADJEST_UI_POS") then
	
		YuanXiao_Shop_ThreeChoices_ResetPos()
		
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
	
		YuanXiao_Shop_ThreeChoices_OnHiden()
		
	end
end

function YuanXiao_Shop_ThreeChoices_ResetPos()

	YuanXiao_Shop_ThreeChoices_Frame_BK:SetProperty("UnifiedPosition", g_YuanXiao_Shop_ThreeChoices_UnifiedPosition)
	
end

function YuanXiao_Shop_ThreeChoices_OnHiden()

	g_YuanXiao_Shop_ThreeChoices_CurSelect = 0
	
	this:Hide()
	
end

function YuanXiao_Shop_ThreeChoices_Close()

	YuanXiao_Shop_ThreeChoices_OnHiden()
	
end

function YuanXiao_Shop_ThreeChoices_Choose( btn )
	
	if g_YuanXiao_Shop_ThreeChoices_List[btn] ~= nil then
	
		for i = 3, 5 do
			if i == btn then
				g_YuanXiao_Shop_ThreeChoices_List[i][2]:Show()
				g_YuanXiao_Shop_ThreeChoices_CurSelect = i
			else
				g_YuanXiao_Shop_ThreeChoices_List[i][2]:Hide()
			end
		end
	
	end
	
end

function YuanXiao_Shop_ThreeChoices_GetClick()
	
	if g_YuanXiao_Shop_ThreeChoices_CurSelect == 0 then
		PushDebugMessage("#{MHSD_191203_49}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FairGetFanLi" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0, g_YuanXiao_Shop_ThreeChoices_CurIdx)
		Set_XSCRIPT_Parameter(1, g_YuanXiao_Shop_ThreeChoices_CurSelect)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
	
end

