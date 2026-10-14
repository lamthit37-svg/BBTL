--!!!reloadscript =DuanWu_BaoZongZi_DoubleChoice
local g_UnifiedPosition;

local g_ItemList =  {
[1]  = {itemid = 10127124, showid = 10127124, }, --30天
[2]  = {itemid = 30103109, showid = 30103109, }, --30天
[3]  = {itemid = 10127127, showid = 10127127, }, --永久
[4]  = {itemid = 30103110, showid = 30103110, }, --永久
}
local g_Action_Item ={}


function DuanWu_BaoZongZi_DoubleChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function DuanWu_BaoZongZi_DoubleChoice_OnLoad()
	g_UnifiedPosition = DuanWu_BaoZongZi_DoubleChoice_Frame:GetProperty("UnifiedPosition")  
	g_Action_Item[1] = DuanWu_BaoZongZi_DoubleChoice_Yuanbao_Icon
	g_Action_Item[2] = DuanWu_BaoZongZi_DoubleChoice_Yuanbao_Icon2
	g_Action_Item[3] = DuanWu_BaoZongZi_DoubleChoice_Yuanbao2_Icon
	g_Action_Item[4] = DuanWu_BaoZongZi_DoubleChoice_Yuanbao2_Icon2
end

function DuanWu_BaoZongZi_DoubleChoice_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99854801 ) then	
		if Get_XParam_INT(0) == 0 then
			this:Hide()
			return
		end
		
		DuanWu_BaoZongZi_DoubleChoice_Init()		
		this:Show()
		
	elseif (event == "ADJEST_UI_POS" ) then
		DuanWu_BaoZongZi_DoubleChoice_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DuanWu_BaoZongZi_DoubleChoice_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--初始化界面
--=========================================================
function DuanWu_BaoZongZi_DoubleChoice_Init()	
	  
	for i=1, table.getn(g_ItemList) do			
		local ItemID = g_ItemList[ i ].showid
		local theAction = DataPool:CreateActionItemForShow(ItemID, 1)
	  	if theAction:GetID() ~= 0 then
	  		g_Action_Item[i]:SetActionItem(theAction:GetID());
	  	end
	end
end
	
--=========================================================
--免费获取
--=========================================================
function DuanWu_BaoZongZi_DoubleChoice_GetFree()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(998548)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

--=========================================================
--购买
--=========================================================
function DuanWu_BaoZongZi_DoubleChoice_Buy()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(998548)
		Set_XSCRIPT_Parameter(0,2)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

--=========================================================
--关闭
--=========================================================
function DuanWu_BaoZongZi_DoubleChoice_OnClose()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function DuanWu_BaoZongZi_DoubleChoice_On_ResetPos()
	DuanWu_BaoZongZi_DoubleChoice_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition);
end
