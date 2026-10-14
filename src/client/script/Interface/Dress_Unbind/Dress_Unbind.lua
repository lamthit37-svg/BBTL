
local g_Dress_Unbind_UnifiedPosition;

local g_Dress_Unbind_ExpendItem = 0
local g_Dress_Unbind_ExpendNum = 0
local g_Dress_Unbind_AvailableItemCount = 0
local g_Dress_Unbind_TuJian = 0

local g_Dress_Unbind_bagIdx = -1
local g_Dress_Unbind_targetId = -1
local g_Dress_Unbind_objCared = -1
local MAX_OBJ_DISTANCE = 3.0

function Dress_Unbind_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	
	this:RegisterEvent("UPDATE_DRESS_UNBIND",false)	
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);
	this:RegisterEvent("OPEN_STALL_SALE")
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	
	
end

function Dress_Unbind_OnLoad()

	g_Dress_Unbind_UnifiedPosition = Dress_Unbind_Frame:GetProperty("UnifiedPosition");

end

function Dress_Unbind_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99908601 ) then 
		
		if Get_XParam_INT(0) == 0 then
			Dress_Unbind_Close_Clicked()
			return 
		end
		
		g_Dress_Unbind_targetId = Get_XParam_INT(1) 
		g_Dress_Unbind_ExpendItem = Get_XParam_INT(2) 
		g_Dress_Unbind_ExpendNum = Get_XParam_INT(3) 
		
		--关心NPC
		g_Dress_Unbind_objCared = DataPool : GetNPCIDByServerID(g_Dress_Unbind_targetId)
		if g_Dress_Unbind_objCared == -1 then
			Dress_Unbind_Close_Clicked()
			return
		end
		this:CareObject(g_Dress_Unbind_objCared, 1, "Dress_Unbind");	
	
		Dress_Unbind_Show()
		
	elseif(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		
		if( arg0 ~= nil and -1 == tonumber(arg0) ) then
			return;
		end		

		if (g_Dress_Unbind_bagIdx == tonumber(arg0) ) then
			Dress_Unbind_Clear()
			Dress_Unbind_Update(g_Dress_Unbind_bagIdx, 1)
		end	
	
		if g_Dress_Unbind_ExpendItem > 0 then
			Dress_Unbind_UpdateItem()
		end
	
	elseif( event == "UPDATE_DRESS_UNBIND" and this:IsVisible() ) then
		if arg0 ~= nil then
			Dress_Unbind_Update(arg0, 0);
		end
		
	elseif (event == "OBJECT_CARED_EVENT") then
	
		if(tonumber(arg0) ~= g_Dress_Unbind_objCared) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1 == "destroy") then
			Dress_Unbind_Close_Clicked()
		end
	
	elseif ( event == "OPEN_STALL_SALE" and this:IsVisible() ) then
		--和摆摊界面互斥
		Dress_Unbind_Close_Clicked()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Dress_Unbind_Close_Clicked()

	elseif (event == "ADJEST_UI_POS" ) then
		Dress_Unbind_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Dress_Unbind_ResetPos()
	end
end

function Dress_Unbind_Show()

	Dress_Unbind_Clear()
	
	this:Show();
	
	if not IsWindowShow("Packet") then
		OpenWindow("Packet")
	end

end

--位置 是否有提示
function Dress_Unbind_Update(arg, IsMessage)
	
	if arg == nil or tonumber(arg) < 0 then
		return
	end

	local bagPos = tonumber(arg)

	local theActionItem = EnumAction(bagPos, "packageitem")
	if theActionItem:GetID() ~= 0 then
		local dressEquipPoint = LifeAbility : Get_Equip_Point_NoMsg(bagPos)
		if dressEquipPoint ~= 16 then
			PushDebugMessage("#{SZPR_091023_77}")
			return
		end
		
		--将之前放入UI的物品解锁
		Dress_Unbind_Clear()
		g_Dress_Unbind_bagIdx = bagPos
		Dress_Unbind_Object:SetActionItem(theActionItem:GetID())
		LifeAbility : Lock_Packet_Item(g_Dress_Unbind_bagIdx, 1)		
		
		Dress_Unbind_UpdateItem()
	
		-- 衣裳值
		local nDressIndex = PlayerPackage : GetItemTableIndex( g_Dress_Unbind_bagIdx )
		local nVisualID = Exterior:LuaFnGetPreviewDressStdVisualID(nDressIndex)
		g_Dress_Unbind_TuJian = WGAch : GetCfgById( 0, nDressIndex, nVisualID, Player:GetMySex() )
		local str = "#cfff263"..g_Dress_Unbind_TuJian
		Dress_Unbind_Num:SetText(str)
	else
		Dress_Unbind_Clear()
		return
	end
	
end

function Dress_Unbind_UpdateItem()

	if g_Dress_Unbind_ExpendItem > 0 then			
		--所消耗道具
		local str = "#cfff263"..g_Dress_Unbind_ExpendNum
		Dress_Unbind_Need:SetText(str)
			
		g_Dress_Unbind_AvailableItemCount = PlayerPackage:CountAvailableItemByIDTable(g_Dress_Unbind_ExpendItem)	
		if g_Dress_Unbind_AvailableItemCount >= g_Dress_Unbind_ExpendNum then
			str = "#G"..g_Dress_Unbind_AvailableItemCount
		else
			str = "#cff0000"..g_Dress_Unbind_AvailableItemCount
		end
		Dress_Unbind_Self:SetText(str)
	end
	
end

function Dress_Unbind_OK_Clicked()

	if g_Dress_Unbind_bagIdx < 0 then
		PushDebugMessage("#{SZBH_240124_46}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NumberingFashionJieQi")
		Set_XSCRIPT_ScriptID(999086)
		Set_XSCRIPT_Parameter(0, g_Dress_Unbind_targetId)
		Set_XSCRIPT_Parameter(1, g_Dress_Unbind_bagIdx)
		Set_XSCRIPT_Parameter(2, 1)
		Set_XSCRIPT_ParamCount(3)			
	Send_XSCRIPT()	
	
end

function Dress_Unbind_ItemBtnRBClicked()

	Dress_Unbind_Clear()
	
end

function Dress_Unbind_Clear()

	if(g_Dress_Unbind_bagIdx ~= -1) then
		LifeAbility : Lock_Packet_Item(g_Dress_Unbind_bagIdx,0);
		g_Dress_Unbind_bagIdx	= -1;
	end
	
	Dress_Unbind_Object:SetActionItem(-1)
	
	Dress_Unbind_Num:SetText("")
	Dress_Unbind_Need:SetText("")
	Dress_Unbind_Self:SetText("")
	
end

function Dress_Unbind_OnHidden()

	Dress_Unbind_Close_Clicked()
	
end

function Dress_Unbind_Close_Clicked()

	Dress_Unbind_Clear()
	
	--取消关心
	this:CareObject(g_Dress_Unbind_objCared, 0, "Dress_Unbind");
	g_Dress_Unbind_objCared = -1

	this:Hide()
	
end

function Dress_Unbind_ResetPos()

	Dress_Unbind_Frame:SetProperty("UnifiedPosition", g_Dress_Unbind_UnifiedPosition);
  
end



