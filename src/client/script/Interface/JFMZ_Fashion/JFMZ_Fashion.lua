
local g_JFMZ_Fashion_UnifiedPosition;

local g_JFMZ_Fashion_List = {};

local g_JFMZ_ItemList =  {
[1]  = {itemid = 10125055, showid = 39921495, }, --锦衣醉画
[2]  = {itemid = 38002322, showid = 38002322, }, --礼盒
}
local g_Action_Item ={}
function JFMZ_Fashion_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function JFMZ_Fashion_OnLoad()
	g_JFMZ_Fashion_UnifiedPosition = JFMZ_Fashion:GetProperty("UnifiedPosition")  
	g_Action_Item[1] = JFMZ_Fashion_Yuanbao_Icon
	g_Action_Item[2] = JFMZ_Fashion_Yuanbao2_Icon
end

function JFMZ_Fashion_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89292601 ) then	
		if Get_XParam_INT(0) == 0 then
			this:Hide()
			return
		end
		
		JFMZ_Fashion_Init()
		
		this:Show()
		
	elseif (event == "ADJEST_UI_POS" ) then
		JFMZ_Fashion_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JFMZ_Fashion_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--初始化界面
--=========================================================
function JFMZ_Fashion_Init()	
	  
	for i=1, 2 do			
		local ItemID = g_JFMZ_ItemList[ i ].showid
		local theAction = DataPool:CreateActionItemForShow(ItemID, 1)
	  	if theAction:GetID() ~= 0 then
	  		g_Action_Item[i]:SetActionItem(theAction:GetID());
	  		g_Action_Item[i]:Show();
	  	end
	end
end
	
--=========================================================
--购买时装
--=========================================================
function JFMZ_Fashion_FashionBuy()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(892926)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

--=========================================================
--购买礼盒
--=========================================================
function JFMZ_Fashion_FashionLiHeBuy()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(892926)
		Set_XSCRIPT_Parameter(0,2)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

--=========================================================
--关闭
--=========================================================
function JFMZ_Fashion_Close()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function JFMZ_Fashion_On_ResetPos()
	JFMZ_Fashion:SetProperty("UnifiedPosition", g_JFMZ_Fashion_UnifiedPosition);
end
