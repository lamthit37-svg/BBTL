--*************************************
--2020Q3清凉一夏  九九消寒 夏季活动
--移骨丹折扣券
-- limengyue 2020-07-06
--*************************************

local g_JiuJiuXiaoHan_Summer_ItemBuy_Frame_UnifiedPosition;
local g_JiuJiuXiaoHan_Summer_ItemBuy_ShowID = 39922712;
local g_JiuJiuXiaoHan_Summer_ItemBuy_Num = 1;
--在使用物品蒙红
local g_nUsedItemBagIndex	= -1

--关心NPc
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1

--===============================================
-- OnLoad()
--===============================================
function JiuJiuXiaoHan_Summer_ItemBuy_PreLoad()
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
function JiuJiuXiaoHan_Summer_ItemBuy_OnLoad()   
	-- 保存界面的默认相对位置
	g_JiuJiuXiaoHan_Summer_ItemBuy_Frame_UnifiedPosition = JiuJiuXiaoHan_Summer_ItemBuy_Frame:GetProperty("UnifiedPosition");

end


--================================================
-- 恢复界面的默认相对位置
--================================================
function JiuJiuXiaoHan_Summer_ItemBuy_Frame_On_ResetPos()
	JiuJiuXiaoHan_Summer_ItemBuy_Frame : SetProperty("UnifiedPosition", g_JiuJiuXiaoHan_Summer_ItemBuy_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function JiuJiuXiaoHan_Summer_ItemBuy_OnEvent(event)

    if (event == "UI_COMMAND" and tonumber(arg0) == 89245801) then
		--打开界面
		if(IsWindowShow("JiuJiuXiaoHan_Summer_ItemBuy")) then
			CloseWindow("JiuJiuXiaoHan_Summer_ItemBuy", true)
		end
		--添加NPC关心
		if Get_XParam_INT(0) >= 0 then
			objCared = DataPool : GetNPCIDByServerID(Get_XParam_INT(0));
			JiuJiuXiaoHan_Summer_ItemBuy_BeginCareObject(objCared)
		end
		g_nUsedItemBagIndex = Get_XParam_INT(1)
		JiuJiuXiaoHan_Summer_ItemBuy_Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89245803) then
		JiuJiuXiaoHan_Summer_ItemBuy_Close()
	end
	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			JiuJiuXiaoHan_Summer_ItemBuy_Close()
		end
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		JiuJiuXiaoHan_Summer_ItemBuy_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JiuJiuXiaoHan_Summer_ItemBuy_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       JiuJiuXiaoHan_Summer_ItemBuy_Close()
    end
         
end

--===============================================
-- JiuJiuXiaoHan_Summer_ItemBuy_Close()
--===============================================
function JiuJiuXiaoHan_Summer_ItemBuy_Close()
	JiuJiuXiaoHan_Summer_ItemBuy_StopCareObject()
	-- 解除背包格子蒙红锁定
	if g_nUsedItemBagIndex >= 0 then
		LifeAbility : Lock_Packet_Item( g_nUsedItemBagIndex, 0 )
	end
	
	g_nUsedItemBagIndex = -1
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function JiuJiuXiaoHan_Summer_ItemBuy_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "JiuJiuXiaoHan_Summer_ItemBuy");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "JiuJiuXiaoHan_Summer_ItemBuy")
end


--=========================================================
--停止对某NPC的关心
--=========================================================
function JiuJiuXiaoHan_Summer_ItemBuy_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "JiuJiuXiaoHan_Summer_ItemBuy");
		g_Object = -1;
	end
end


--=========================================================
--显示界面
--=========================================================
function JiuJiuXiaoHan_Summer_ItemBuy_Show()
	local theAction = DataPool:CreateActionItemForShow(g_JiuJiuXiaoHan_Summer_ItemBuy_ShowID,g_JiuJiuXiaoHan_Summer_ItemBuy_Num)
	if theAction:GetID() ~= 0 then
		JiuJiuXiaoHan_Summer_ItemBuy_Page_Lace1Item:SetActionItem(theAction:GetID());
		JiuJiuXiaoHan_Summer_ItemBuy_Page_Lace1Item:Show();
	end
	this:Show()
	
	-- 背包格子蒙红锁定
	LifeAbility : Lock_Packet_Item( g_nUsedItemBagIndex, 1 )
	
end

--=========================================================
--购买按钮
--=========================================================
function JiuJiuXiaoHan_Summer_ItemBuy_GetClick()
	--PushDebugMessage("JiuJiuXiaoHan_Summer_ItemBuy_GetClick")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("BuyItemCheck")
		Set_XSCRIPT_ScriptID(892458) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end


