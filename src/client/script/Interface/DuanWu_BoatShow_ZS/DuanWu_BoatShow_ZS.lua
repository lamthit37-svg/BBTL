local g_DuanWu_BoatShow_ZS_Frame_UnifiedPosition;
local g_DuanWu_BoatShow_ZS_ShowID = 0;
local g_DuanWu_BoatShow_ZS_Num = 1;
--在使用物品蒙红
local g_nUsedItemBagIndex	= -1

--关心NPc
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1

--===============================================
-- OnLoad()
--===============================================
function DuanWu_BoatShow_ZS_PreLoad()
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
function DuanWu_BoatShow_ZS_OnLoad()   
	-- 保存界面的默认相对位置
	g_DuanWu_BoatShow_ZS_Frame_UnifiedPosition = DuanWu_BoatShow_ZS_Frame:GetProperty("UnifiedPosition");

end


--================================================
-- 恢复界面的默认相对位置
--================================================
function DuanWu_BoatShow_ZS_Frame_On_ResetPos()
	DuanWu_BoatShow_ZS_Frame : SetProperty("UnifiedPosition", g_DuanWu_BoatShow_ZS_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function DuanWu_BoatShow_ZS_OnEvent(event)

    if (event == "UI_COMMAND" and tonumber(arg0) == 99910101) then
		--打开界面
		if(IsWindowShow("DuanWu_BoatShow_ZS")) then
			CloseWindow("DuanWu_BoatShow_ZS", true)
		end 
		g_DuanWu_BoatShow_ZS_ShowID= Get_XParam_INT(0)
		g_nUsedItemBagIndex = Get_XParam_INT(1)
		DuanWu_BoatShow_ZS_Show()
		DuanWu_BoatShow_ZS_DragTitle:SetText("#{DWKC_240514_04}")
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99910103) then
		DuanWu_BoatShow_ZS_Close()
	end 

	if (event == "UI_COMMAND" and tonumber(arg0) == 99955301) then
		--打开界面
		if(IsWindowShow("DuanWu_BoatShow_ZS")) then
			CloseWindow("DuanWu_BoatShow_ZS", true)
		end 
		g_DuanWu_BoatShow_ZS_ShowID= Get_XParam_INT(0)
		g_nUsedItemBagIndex = Get_XParam_INT(1)
		DuanWu_BoatShow_ZS_Show()
		DuanWu_BoatShow_ZS_DragTitle:SetText("#{DWKC_241115_01}")
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99955303) then
		DuanWu_BoatShow_ZS_Close()
	end 

	if (event == "UI_COMMAND" and tonumber(arg0) == 99969701) then
		--打开界面
		if(IsWindowShow("DuanWu_BoatShow_ZS")) then
			CloseWindow("DuanWu_BoatShow_ZS", true)
		end 
		g_DuanWu_BoatShow_ZS_ShowID= Get_XParam_INT(0)
		g_nUsedItemBagIndex = Get_XParam_INT(1)
		DuanWu_BoatShow_ZS_Show()
		DuanWu_BoatShow_ZS_DragTitle:SetText("#{DWKC_250516_01}")
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99969703) then
		DuanWu_BoatShow_ZS_Close()
	end 

	if (event == "UI_COMMAND" and tonumber(arg0) == 99978101) then
		--打开界面
		if(IsWindowShow("DuanWu_BoatShow_ZS")) then
			CloseWindow("DuanWu_BoatShow_ZS", true)
		end 
		g_DuanWu_BoatShow_ZS_ShowID= Get_XParam_INT(0)
		g_nUsedItemBagIndex = Get_XParam_INT(1)
		DuanWu_BoatShow_ZS_Show()
		DuanWu_BoatShow_ZS_DragTitle:SetText("#{DWKC_251106_01}")
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99978103) then
		DuanWu_BoatShow_ZS_Close()
	end 

	if (event == "UI_COMMAND" and tonumber(arg0) == 88557601) then
		--打开界面
		if(IsWindowShow("DuanWu_BoatShow_ZS")) then
			CloseWindow("DuanWu_BoatShow_ZS", true)
		end 
		g_DuanWu_BoatShow_ZS_ShowID= Get_XParam_INT(0)
		g_nUsedItemBagIndex = Get_XParam_INT(1)
		DuanWu_BoatShow_ZS_Show()
		DuanWu_BoatShow_ZS_DragTitle:SetText("#{DWKC_260515_01}")
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 88557603) then
		DuanWu_BoatShow_ZS_Close()
	end 

    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		DuanWu_BoatShow_ZS_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DuanWu_BoatShow_ZS_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       DuanWu_BoatShow_ZS_Close()
    end
         
end

--===============================================
-- DuanWu_BoatShow_ZS_Close()
--===============================================
function DuanWu_BoatShow_ZS_Close() 
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
function DuanWu_BoatShow_ZS_Show()
	local theAction = DataPool:CreateActionItemForShow(g_DuanWu_BoatShow_ZS_ShowID,g_DuanWu_BoatShow_ZS_Num)
	if theAction:GetID() ~= 0 then
		DuanWu_BoatShow_ZS_Page_Lace1Item:SetActionItem(theAction:GetID());
		DuanWu_BoatShow_ZS_Page_Lace1Item:Show();
	end
	this:Show()
	
	-- 背包格子蒙红锁定
	LifeAbility : Lock_Packet_Item( g_nUsedItemBagIndex, 1 )
	
end

--=========================================================
--购买按钮
--=========================================================
function DuanWu_BoatShow_ZS_GetClick() 
	if g_DuanWu_BoatShow_ZS_ShowID == 38007736 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItemCheck")
			Set_XSCRIPT_ScriptID(999553) 
			Set_XSCRIPT_Parameter(0, g_nUsedItemBagIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_DuanWu_BoatShow_ZS_ShowID == 38008007 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItemCheck")
			Set_XSCRIPT_ScriptID(999697) 
			Set_XSCRIPT_Parameter(0, g_nUsedItemBagIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_DuanWu_BoatShow_ZS_ShowID == 38008225 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItemCheck")
			Set_XSCRIPT_ScriptID(999781) 
			Set_XSCRIPT_Parameter(0, g_nUsedItemBagIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_DuanWu_BoatShow_ZS_ShowID == 38008595 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItemCheck")
			Set_XSCRIPT_ScriptID(885576) 
			Set_XSCRIPT_Parameter(0, g_nUsedItemBagIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItemCheck")
			Set_XSCRIPT_ScriptID(999101) 
			Set_XSCRIPT_Parameter(0, g_nUsedItemBagIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

function DuanWu_BoatShow_ZS_Preview_Click()
	if g_DuanWu_BoatShow_ZS_ShowID == 38007736 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
		--Set_XSCRIPT_Parameter(0, 10126466) 
		--Set_XSCRIPT_Parameter(1, 123)
		--Set_XSCRIPT_Parameter(2, 91)
			Set_XSCRIPT_Parameter(0, 10128133)
			Set_XSCRIPT_Parameter(1, 249)--hair
			Set_XSCRIPT_Parameter(2, 183)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_DuanWu_BoatShow_ZS_ShowID == 38008007 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
		--Set_XSCRIPT_Parameter(0, 10126466) 
		--Set_XSCRIPT_Parameter(1, 123)
		--Set_XSCRIPT_Parameter(2, 91)
			Set_XSCRIPT_Parameter(0, 10128283)
			Set_XSCRIPT_Parameter(1, 264)--hair
			Set_XSCRIPT_Parameter(2, 194)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_DuanWu_BoatShow_ZS_ShowID == 38008225 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
		--Set_XSCRIPT_Parameter(0, 10126466) 
		--Set_XSCRIPT_Parameter(1, 123)
		--Set_XSCRIPT_Parameter(2, 91)
			Set_XSCRIPT_Parameter(0, 10128520)
			Set_XSCRIPT_Parameter(1, 279)--hair
			Set_XSCRIPT_Parameter(2, 203)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_DuanWu_BoatShow_ZS_ShowID == 38008595 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
		--Set_XSCRIPT_Parameter(0, 10126466) 
		--Set_XSCRIPT_Parameter(1, 123)
		--Set_XSCRIPT_Parameter(2, 91)
			Set_XSCRIPT_Parameter(0, 10128752)
			Set_XSCRIPT_Parameter(1, 296)--hair
			Set_XSCRIPT_Parameter(2, 214)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
		--Set_XSCRIPT_Parameter(0, 10126466) 
		--Set_XSCRIPT_Parameter(1, 123)
		--Set_XSCRIPT_Parameter(2, 91)
			Set_XSCRIPT_Parameter(0, 10127741)
			Set_XSCRIPT_Parameter(1, 232)--hair
			Set_XSCRIPT_Parameter(2, 173)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end

	
end