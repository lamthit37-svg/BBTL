--!!!reloadscript =DaHua_Shop_DoubleChoice
local g_UnifiedPosition;

local g_Action_Item ={}
local g_Action_Item_BagPos = -1

local g_ItemList = {} -- [1] = 免费道具id, [2] = 元宝道具id
local g_LiXiaItemStr = ""
local g_ItemStrList = {}
local g_CostYBStr = ""



function DaHua_Shop_DoubleChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true); 
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function DaHua_Shop_DoubleChoice_OnLoad()
	g_UnifiedPosition = DaHua_Shop_DoubleChoice_Frame:GetProperty("UnifiedPosition")  
	g_Action_Item[1] = DaHua_Shop_DoubleChoice_Yuanbao_Icon
	g_Action_Item[2] = DaHua_Shop_DoubleChoice_Yuanbao2_Icon 
end

function DaHua_Shop_DoubleChoice_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99929901 ) then	
		if Get_XParam_INT(0) == 0 then
			this:Hide()
			return
		end
		DaHua_Shop_Clear()
		g_Action_Item_BagPos = Get_XParam_INT(1)
		if g_Action_Item_BagPos and g_Action_Item_BagPos >= 0 then
			LifeAbility:Lock_Packet_Item(g_Action_Item_BagPos, 1)
		end
		g_ItemList[1] = Get_XParam_INT(2)
		g_ItemList[2] = Get_XParam_INT(3)
		
		g_LiXiaItemStr = Get_XParam_STR(0)
		g_ItemStrList[1] = Get_XParam_STR(1)
		g_ItemStrList[2] = Get_XParam_STR(2)
		g_ItemStrList[3] = Get_XParam_STR(3)
		g_CostYBStr = Get_XParam_STR(4)

		DaHua_Shop_DoubleChoice_Init()		
		this:Show()
		
	elseif (event == "ADJEST_UI_POS" ) then
		DaHua_Shop_DoubleChoice_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DaHua_Shop_DoubleChoice_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--初始化界面
--=========================================================
function DaHua_Shop_DoubleChoice_Init()	
	DaHua_Shop_DoubleChoice_DragTitle:SetText(g_LiXiaItemStr)
	DaHua_Shop_DoubleChoice_Jinfen_text:SetText(g_ItemStrList[1])
	DaHua_Shop_DoubleChoice_Giftbox_text:SetText(g_ItemStrList[2])
	DaHua_Shop_DoubleChoice_ReFresh_Btn2:SetText(g_ItemStrList[3])
	DaHua_Shop_DoubleChoice_ReFresh_text:SetText(g_CostYBStr)
	for i=1, table.getn(g_ItemList) do
		local theAction = DataPool:CreateBindActionItemForShow(g_ItemList[i], 1)
	  	if theAction:GetID() ~= 0 then
	  		g_Action_Item[i]:SetActionItem(theAction:GetID())
	  	end
	end
end
	
--=========================================================
--免费获取
--=========================================================
function DaHua_Shop_DoubleChoice_GetFree()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ReceiveFreeLiHe" )
		Set_XSCRIPT_ScriptID(999299)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	

end

--=========================================================
--购买
--=========================================================
function DaHua_Shop_DoubleChoice_Buy()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyLiHe" )
		Set_XSCRIPT_ScriptID(999299)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

function DaHua_Shop_DoubleChoice_UnLock()
	if g_Action_Item_BagPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_Action_Item_BagPos, 0)
	end
	g_Action_Item_BagPos = -1
end

--=========================================================
--关闭
--=========================================================
function DaHua_Shop_DoubleChoice_OnClose()
	this:Hide()
end

function DaHua_Shop_DoubleChoice_OnHidden()
	DaHua_Shop_Clear()
end

function DaHua_Shop_Clear()
	DaHua_Shop_DoubleChoice_UnLock()
	PushEvent("CLOSE_DAHUAQIXI_SHOP_MSGBOX") -- 关闭二次确认界面
end

--=========================================================
--刷新位置
--=========================================================
function DaHua_Shop_DoubleChoice_On_ResetPos()
	DaHua_Shop_DoubleChoice_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition);
end
