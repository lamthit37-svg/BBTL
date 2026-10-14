--端午节 
local g_DuanWu_DuiHuan_Frame_UnifiedPosition 
local g_DuanWu_DuiHuan_Remain_Count =0;
local g_DuanWu_DuiHuan_Max_Count =0;
local g_DuanWu_DuiHuan_NeedItem_Count =350;
local g_DuanWu_DuiHuan_GiftID =39921717
local g_DuanWu_DuiHuan_NeedItemID =38004729
local g_DuanWu_DuiHuan_objCared =-1
local g_DuanWu_DuiHuan_MissionFlag = 0;
function DuanWu_DuiHuan_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false) 
	
end

function DuanWu_DuiHuan_OnLoad()
	DuanWu_DuiHuan_LoadControl()
	g_DuanWu_DuiHuan_Frame_UnifiedPosition = DuanWu_DuiHuan_Frame:GetProperty("UnifiedPosition") 
end
--=========
-- 装载控件
--=========
function DuanWu_DuiHuan_LoadControl() 

end
--=========
-- Event
--=========
function DuanWu_DuiHuan_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 89311801) then --   
		DuanWu_DuiHuan_Open(0)
		this:Show()
	
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89311802) then --   
		DuanWu_DuiHuan_Open(1)
		--this:Hide()	
	
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DuanWu_DuiHuan_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		DuanWu_DuiHuan_Close()

	elseif event == "ADJEST_UI_POS" then

		DuanWu_DuiHuan_On_ResetPos()
	
	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		
		if (arg0~= nil and -1 == tonumber(arg0)) then
			return
		end 
		DuanWu_DuiHuan_Refresh_Item()
		
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			--取消关心
			this:CareObject(objCared, 0, "DuanWu_DuiHuan");
		end
		
	end

end
 
--=========
-- 重置
--=========
function DuanWu_DuiHuan_On_ResetPos()

	DuanWu_DuiHuan_Frame:SetProperty("UnifiedPosition", g_DuanWu_DuiHuan_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function DuanWu_DuiHuan_Close() 
	this:Hide()
end

--=========
-- 打开
--=========
function DuanWu_DuiHuan_Open( nType )  
	g_DuanWu_DuiHuan_Remain_Count 	=  Get_XParam_INT(0) 
	g_DuanWu_DuiHuan_Max_Count 			=  Get_XParam_INT(1) 
	g_DuanWu_DuiHuan_NeedItem_Count	=  Get_XParam_INT(2) 	
	g_DuanWu_DuiHuan_MissionFlag			=  Get_XParam_INT(4) 	
	
	if nType == 0 then		
		g_DuanWu_DuiHuan_objCared				=  Get_XParam_INT(3) 			--关心NPC 	
		objCared = DataPool:GetNPCIDByServerID(g_DuanWu_DuiHuan_objCared)
		this:CareObject(objCared, 1, "DuanWu_DuiHuan");		
	end
	
	g_DuanWu_DuiHuan_Remain_Count = g_DuanWu_DuiHuan_Max_Count - g_DuanWu_DuiHuan_Remain_Count
	DuanWu_DuiHuan_OnInitial() 
end

function DuanWu_DuiHuan_OnInitial()     

	if g_DuanWu_DuiHuan_Remain_Count == 0 then
		DuanWu_DuiHuan_ItemNum:SetText(ScriptGlobal_Format("#{DWDH_190502_14}",g_DuanWu_DuiHuan_Remain_Count,g_DuanWu_DuiHuan_Max_Count))
	else
		DuanWu_DuiHuan_ItemNum:SetText(ScriptGlobal_Format("#{DWDH_190502_13}",g_DuanWu_DuiHuan_Remain_Count,g_DuanWu_DuiHuan_Max_Count))
	end

	local theAction= DataPool:CreateActionItemForShow(g_DuanWu_DuiHuan_GiftID, 1)
	if theAction:GetID() ~= 0 then
		DuanWu_DuiHuan_Item:SetActionItem(theAction:GetID());
		DuanWu_DuiHuan_Item:Show();
	end
	
	local HaveIDcount 			= PlayerPackage:CountAvailableItemByIDTable(g_DuanWu_DuiHuan_NeedItemID) 
	if HaveIDcount < g_DuanWu_DuiHuan_NeedItem_Count then	
		DuanWu_DuiHuan_NeedNum:SetText(ScriptGlobal_Format("#{DWDH_190502_16}",DataPool:Lua_GetItemNameByIndex(g_DuanWu_DuiHuan_NeedItemID), HaveIDcount, g_DuanWu_DuiHuan_NeedItem_Count))
	else
		DuanWu_DuiHuan_NeedNum:SetText(ScriptGlobal_Format("#{DWDH_190502_15}",DataPool:Lua_GetItemNameByIndex(g_DuanWu_DuiHuan_NeedItemID), HaveIDcount, g_DuanWu_DuiHuan_NeedItem_Count))
	end
	
	DuanWu_DuiHuan_Text2:SetText( ScriptGlobal_Format("#{DWDH_190502_12}", g_DuanWu_DuiHuan_MissionFlag) )
	DuanWu_DuiHuan_Text2:Hide()
end

function DuanWu_DuiHuan_Exchange_Clicked()      
   	Clear_XSCRIPT()
   		Set_XSCRIPT_Function_Name("OnExchangeItem") 
   		Set_XSCRIPT_ScriptID(893118) 
   		Set_XSCRIPT_Parameter(0,g_DuanWu_DuiHuan_objCared) 	
   		Set_XSCRIPT_ParamCount(1)
   	Send_XSCRIPT()	 
end

function DuanWu_DuiHuan_Help_Clicked() 
	PushEvent("DUANWU_DUIHUAN_HELP") 
end

function DuanWu_DuiHuan_Refresh_Item() 
	local HaveIDcount 			= PlayerPackage:CountAvailableItemByIDTable(g_DuanWu_DuiHuan_NeedItemID) 
	if HaveIDcount < g_DuanWu_DuiHuan_NeedItem_Count then	
		DuanWu_DuiHuan_NeedNum:SetText(ScriptGlobal_Format("#{DWDH_190502_16}",DataPool:Lua_GetItemNameByIndex(g_DuanWu_DuiHuan_NeedItemID), HaveIDcount, g_DuanWu_DuiHuan_NeedItem_Count))
	else
		DuanWu_DuiHuan_NeedNum:SetText(ScriptGlobal_Format("#{DWDH_190502_15}",DataPool:Lua_GetItemNameByIndex(g_DuanWu_DuiHuan_NeedItemID), HaveIDcount, g_DuanWu_DuiHuan_NeedItem_Count))
	end
end