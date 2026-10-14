
--变量
local g_DongJi_Boat_Three_Frame_UnifiedPosition = ""
local g_CurSelect = 0
--UI
local g_DongJi_Boat_Three_UI_ActionItem = {}
local g_DongJi_Boat_Three_UI_ActionChosenMask = {}
local g_DongJi_Boat_Three_UI_ActionCornerMask = {}
local g_DongJi_Boat_Three_UI_EyeSign = {}
local g_DongJi_Boat_Three_UI_ItemName = {}
local g_DongJi_Boat_Three_UI_DragTitle = ""
local g_DongJi_Boat_Three_UI_Info = ""
local g_DongJi_Boat_Three_UI_Remark = ""

--常量
local g_DongJi_Boat_Three_TotalNum = 3

local g_objCared = -1
local g_showItem = {
	[1] = {10104168,10105116,10101102},
	[2] = {38005872,38006376,38007737},
	[3] = {10146465,10146530,10146718},
}
local g_LiBaoName = {"#{DWKC_251201_17}","#{DWKC_251201_18}","#{DWKC_251201_19}"}
local g_Info = {"#{DWKC_251201_09}","#{DWKC_251201_10}","#{DWKC_251201_11}"}
local MAX_OBJ_DISTANCE = 3.0;
function DongJi_Boat_Three_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function DongJi_Boat_Three_OnLoad()

	g_DongJi_Boat_Three_Frame_UnifiedPosition = DongJi_Boat_Three_Frame_BK:GetProperty("UnifiedPosition")
	
	g_DongJi_Boat_Three_UI_DragTitle = DongJi_Boat_Three_DragTitle		
	g_DongJi_Boat_Three_UI_Info = DongJi_Boat_Three_Info
	g_DongJi_Boat_Three_UI_Remark = DongJi_Boat_Three_Remark
	
	g_DongJi_Boat_Three_UI_ActionItem[1] = DongJi_Boat_Three_Item1
	g_DongJi_Boat_Three_UI_ActionItem[2] = DongJi_Boat_Three_Item2
	g_DongJi_Boat_Three_UI_ActionItem[3] = DongJi_Boat_Three_Item3
	
	g_DongJi_Boat_Three_UI_ActionChosenMask[1] = DongJi_Boat_Three_Item1_Mask
	g_DongJi_Boat_Three_UI_ActionChosenMask[2] = DongJi_Boat_Three_Item2_Mask
	g_DongJi_Boat_Three_UI_ActionChosenMask[3] = DongJi_Boat_Three_Item3_Mask
	
	g_DongJi_Boat_Three_UI_ActionCornerMask[1] = DongJi_Boat_Three_Item1_Cornermark
	g_DongJi_Boat_Three_UI_ActionCornerMask[2] = DongJi_Boat_Three_Item2_Cornermark
	g_DongJi_Boat_Three_UI_ActionCornerMask[3] = DongJi_Boat_Three_Item3_Cornermark
	
	g_DongJi_Boat_Three_UI_ItemName[1] = DongJi_Boat_Three_Item1_Name
	g_DongJi_Boat_Three_UI_ItemName[2] = DongJi_Boat_Three_Item2_Name
	g_DongJi_Boat_Three_UI_ItemName[3] = DongJi_Boat_Three_Item3_Name
	
	g_DongJi_Boat_Three_UI_EyeSign[1] = DongJi_Boat_Three_Item1_EyeSign
	g_DongJi_Boat_Three_UI_EyeSign[2] = DongJi_Boat_Three_Item2_EyeSign
	g_DongJi_Boat_Three_UI_EyeSign[3] = DongJi_Boat_Three_Item3_EyeSign
end										

function DongJi_Boat_Three_OnEvent(event)
	
	if event == "UI_COMMAND" and (tonumber(arg0) == 99979101) then		

		DongJi_Boat_Three_CleanUp()
		local xx = Get_XParam_INT(0);
		g_objCared = DataPool : GetNPCIDByServerID(xx);

		if g_objCared == -1 then
			PushDebugMessage("server传过来的数据有问题。");
			return
		end

		g_idx = Get_XParam_INT(1)
		this:CareObject(g_objCared, 1, "DongJi_Boat_Three");
		this:Show()		
		DongJi_Boat_Three_Update()
		return
	end
	
	if event == "UI_COMMAND" and (tonumber(arg0) == 99979102) then	
		DongJi_Boat_Three_OnHidden()
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		DongJi_Boat_Three_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		DongJi_Boat_Three_OnHidden()
		return
	end
	
	if (event == "OBJECT_CARED_EVENT") then
		--AxTrace(0, 0, "arg0"..arg0.." arg1"..arg1.." arg2"..arg2);
		
		if(not this:IsVisible() ) then
			return;
		end

		if(tonumber(arg0) ~= g_objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			DongJi_Boat_Three_OnHidden()
		end

	end
end

function DongJi_Boat_Three_Update()

	g_DongJi_Boat_Three_UI_DragTitle:SetText(g_LiBaoName[g_idx])
	g_DongJi_Boat_Three_UI_Info:SetText(g_Info[g_idx])
	g_DongJi_Boat_Three_UI_Remark:SetText("")
	
	for i = 1, 3 do
		local itemAction = DataPool:CreateActionItemForShow(g_showItem[g_idx][i], 1)
		if itemAction:GetID() ~= 0 then
			g_DongJi_Boat_Three_UI_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = DataPool:Lua_GetItemNameByIndex(g_showItem[g_idx][i])
		g_DongJi_Boat_Three_UI_ItemName[i]:SetText("#L"..strName)

		if g_idx == 2 then
			g_DongJi_Boat_Three_UI_EyeSign[i]:Show()
		end
	end
	
	for i = 1, 3 do
		g_DongJi_Boat_Three_UI_ActionCornerMask[i]:Hide()
	end	

end

function DongJi_Boat_Three_OnItemClicked(index)

	if index ~= 1 and index ~= 2 and index ~= 3 then
		return
	end

	g_CurSelect = index

	g_DongJi_Boat_Three_UI_ActionChosenMask[g_CurSelect]:Show()
	
	for i = 1, 3 do
		if i ~= g_CurSelect then
			g_DongJi_Boat_Three_UI_ActionChosenMask[i]:Hide()
		end
	end
end

function DongJi_Boat_Three_CleanUp()	
	
	for i = 1, g_DongJi_Boat_Three_TotalNum do	
		g_DongJi_Boat_Three_UI_ActionItem[i]:SetActionItem(-1)
		g_DongJi_Boat_Three_UI_ItemName[i]:SetText("")
		g_DongJi_Boat_Three_UI_ActionChosenMask[i]:Hide()
		g_DongJi_Boat_Three_UI_EyeSign[i]:Hide()
	end 
	
	g_DongJi_Boat_Three_UI_DragTitle:SetText("")
	g_DongJi_Boat_Three_UI_Info:SetText("")
	g_DongJi_Boat_Three_UI_Remark:SetText("")

	g_CurSelect = 0
	g_idx = 0
	this:CareObject(g_objCared, 0, "DongJi_Boat_Three");
	g_objCared = -1
end

function DongJi_Boat_Three_OnHidden()
	DongJi_Boat_Three_CleanUp()
	this:Hide()
end

function DongJi_Boat_Three_OnGetClicked()
	
	if g_CurSelect ~= 1 and g_CurSelect ~= 2 and g_CurSelect ~= 3 then
		PushDebugMessage( "#{DWKC_251201_12}" )
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("BuyItemCheck")
		Set_XSCRIPT_ScriptID(999791)
		Set_XSCRIPT_Parameter(0, g_idx)
		Set_XSCRIPT_Parameter(1, g_CurSelect)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

function DongJi_Boat_Three_Frame_On_ResetPos()
	if g_DongJi_Boat_Three_Frame_UnifiedPosition ~= nil then
		DongJi_Boat_Three_Frame_BK:SetProperty("UnifiedPosition", g_DongJi_Boat_Three_Frame_UnifiedPosition)
	end
end

function DongJi_Boat_Three_ViewClicked(idx)
	if idx == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
			Set_XSCRIPT_Parameter(0, 10126737)
			Set_XSCRIPT_Parameter(1, 143)
			Set_XSCRIPT_Parameter(2, 110)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif idx == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
			Set_XSCRIPT_Parameter(0, 10127169)
			Set_XSCRIPT_Parameter(1, 180)
			Set_XSCRIPT_Parameter(2, 143)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
			Set_XSCRIPT_Parameter(0, 10128117)
			Set_XSCRIPT_Parameter(1, 248)
			Set_XSCRIPT_Parameter(2, 183)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
	
end