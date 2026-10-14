--!!!reloadscript =JulyDress_DoubleChoice
local g_UnifiedPosition;

local g_ItemList =  {
[1]  = {itemid = 10126715, showid = 39924362, }, --30天
[2]  = {itemid = 38005776, showid = 39923828, }, --永久 
}
local g_Action_Item ={}


function JulyDress_DoubleChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true); 
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function JulyDress_DoubleChoice_OnLoad()
	g_UnifiedPosition = JulyDress_DoubleChoice_Frame:GetProperty("UnifiedPosition")  
	g_Action_Item[1] = JulyDress_DoubleChoice_Yuanbao_Icon
	g_Action_Item[2] = JulyDress_DoubleChoice_Yuanbao2_Icon 
end

function JulyDress_DoubleChoice_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99860501 ) then	
		if Get_XParam_INT(0) == 0 then
			this:Hide()
			return
		end
		
		JulyDress_DoubleChoice_Init()		
		this:Show()
		
	elseif (event == "ADJEST_UI_POS" ) then
		JulyDress_DoubleChoice_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JulyDress_DoubleChoice_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--初始化界面
--=========================================================
function JulyDress_DoubleChoice_Init()	
	  
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
function JulyDress_DoubleChoice_GetFree()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(998605)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

--=========================================================
--购买
--=========================================================
function JulyDress_DoubleChoice_Buy()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(998605)
		Set_XSCRIPT_Parameter(0,2)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

--=========================================================
--关闭
--=========================================================
function JulyDress_DoubleChoice_OnClose()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function JulyDress_DoubleChoice_On_ResetPos()
	JulyDress_DoubleChoice_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition);
end
