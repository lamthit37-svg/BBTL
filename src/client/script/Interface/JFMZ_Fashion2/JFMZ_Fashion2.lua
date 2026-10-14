
local g_JFMZ_Fashion2_UnifiedPosition;

local g_JFMZ_Fashion2_List = {};

local g_JFMZ_ItemList =  {
[1]  = {itemid = 10126200, showid = 39922744, }, --金风季
[2]  = {itemid = 38004904, showid = 38004904, }, --礼盒
}
local g_Action_Item ={}
function JFMZ_Fashion2_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function JFMZ_Fashion2_OnLoad()
	g_JFMZ_Fashion2_UnifiedPosition = JFMZ_Fashion2:GetProperty("UnifiedPosition")  
	g_Action_Item[1] = JFMZ_Fashion2_Yuanbao_Icon
	g_Action_Item[2] = JFMZ_Fashion2_Yuanbao2_Icon
end

function JFMZ_Fashion2_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88818701 ) then	 
		if Get_XParam_INT(0) == 0 then
			this:Hide()
			return
		end
		
		JFMZ_Fashion2_Init()
		
		this:Show()
		
	elseif (event == "ADJEST_UI_POS" ) then
		JFMZ_Fashion2_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JFMZ_Fashion2_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--初始化界面
--=========================================================
function JFMZ_Fashion2_Init()	
	  
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
function JFMZ_Fashion2_FashionBuy()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(888187)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

--=========================================================
--购买礼盒
--=========================================================
function JFMZ_Fashion2_FashionLiHeBuy()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(888187)
		Set_XSCRIPT_Parameter(0,2)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

--=========================================================
--关闭
--=========================================================
function JFMZ_Fashion2_Close()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function JFMZ_Fashion2_On_ResetPos()
	JFMZ_Fashion2:SetProperty("UnifiedPosition", g_JFMZ_Fashion2_UnifiedPosition);
end
