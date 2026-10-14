local g_ActivityWM_Pop_Frame_UnifiedPosition;
local g_ActivityWM_Pop_ShowID = 39924288;
local g_ActivityWM_Pop_Num = 1;
--在使用物品蒙红
local g_nUsedItemBagIndex	= -1

--关心NPc
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1

--===============================================
-- OnLoad()
--===============================================
function ActivityWM_Pop_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function ActivityWM_Pop_OnLoad()   
	-- 保存界面的默认相对位置
	g_ActivityWM_Pop_Frame_UnifiedPosition = ActivityWM_Pop_Frame:GetProperty("UnifiedPosition");

end


--================================================
-- 恢复界面的默认相对位置
--================================================
function ActivityWM_Pop_Frame_On_ResetPos()
	ActivityWM_Pop_Frame : SetProperty("UnifiedPosition", g_ActivityWM_Pop_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function ActivityWM_Pop_OnEvent(event)

    if (event == "UI_COMMAND" and tonumber(arg0) == 99847001) then
		--打开界面
		if(IsWindowShow("ActivityWM_Pop")) then
			CloseWindow("ActivityWM_Pop", true)
		end 
		g_nUsedItemBagIndex = Get_XParam_INT(1)
		ActivityWM_Pop_Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99847003) then
		ActivityWM_Pop_Close()
	end 
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		ActivityWM_Pop_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ActivityWM_Pop_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       ActivityWM_Pop_Close()
    end
         
end

--===============================================
-- ActivityWM_Pop_Close()
--===============================================
function ActivityWM_Pop_Close() 
	-- 解除背包格子蒙红锁定
	if g_nUsedItemBagIndex >= 0 then
		LifeAbility : Lock_Packet_Item( g_nUsedItemBagIndex, 0 )
	end
	
	g_nUsedItemBagIndex = -1
	this:Hide()
end
 


--=========================================================
--显示界面
--=========================================================
function ActivityWM_Pop_Show()
	local theAction = DataPool:CreateActionItemForShow(g_ActivityWM_Pop_ShowID,g_ActivityWM_Pop_Num)
	if theAction:GetID() ~= 0 then
		ActivityWM_Pop_Page_Lace1Item:SetActionItem(theAction:GetID());
		ActivityWM_Pop_Page_Lace1Item:Show();
	end
	this:Show()
	
	-- 背包格子蒙红锁定
	LifeAbility : Lock_Packet_Item( g_nUsedItemBagIndex, 1 )
	
end

--=========================================================
--购买按钮
--=========================================================
function ActivityWM_Pop_GetClick() 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("BuyItemCheck")
		Set_XSCRIPT_ScriptID(998470) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end
