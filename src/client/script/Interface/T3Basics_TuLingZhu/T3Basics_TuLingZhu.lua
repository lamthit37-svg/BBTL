

local g_T3BT_Frame_UnifiedXPosition
local g_T3BT_Frame_UnifiedYPosition
local g_T3BT_ClientObjid
local g_T3BT_ServerObjid

local g_KunwulingzhuID = 38001513
local g_Tulingzhu = 30505216
local g_T3BT_equipPos

function T3Basics_TuLingZhu_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("UPDATE_EXCH_KWLZ",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

-- 当前对话框的操作类型
local g_Event;

local Event_Relive = 0;
local Event_Callof = 1;

function T3Basics_TuLingZhu_OnLoad()
	g_T3BT_Frame_UnifiedXPosition	= T3Basics_TuLingZhu_Frame : GetProperty("UnifiedXPosition")
	g_T3BT_Frame_UnifiedYPosition	= T3Basics_TuLingZhu_Frame : GetProperty("UnifiedYPosition")
		
	g_T3BT_equipPos = -1
end

function T3Basics_TuLingZhu_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 70203901) then
		T3Basics_TuLingZhu_OnDefaultOpen()
	elseif( event == "UPDATE_EXCH_KWLZ" and this:IsVisible()) then
		T3Basics_TuLingZhu_OnUpdateKWLZ(tonumber(arg0), tonumber(arg1))
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		T3Basics_TuLingZhu_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_T3BT_ClientObjid) then
			return
		end

		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			T3Basics_TuLingZhu_Cancel_Clicked()
		end
	end
	
end


function T3Basics_TuLingZhu_OnDefaultOpen()
	g_T3BT_ServerObjid = Get_XParam_INT(0)
	g_T3BT_ClientObjid = DataPool : GetNPCIDByServerID(g_T3BT_ServerObjid)
	if g_T3BT_ClientObjid == nil or g_T3BT_ClientObjid == -1 then				
			return
	end	
	this:CareObject(g_T3BT_ClientObjid, 1, "T3Basics_TuLingZhu")
	T3Basics_TuLingZhu_ClearItem()
	
	local theAction = DataPool:CreateActionItemForShow(g_Tulingzhu, 1)
	T3Basics_TuLingZhu_Object3:Show()
	T3Basics_TuLingZhu_Object3:SetActionItem(theAction:GetID())
	
	if( g_T3BT_equipPos ~= -1) then
		LifeAbility : Lock_Packet_Item(g_T3BT_equipPos,0)
	end
	g_T3BT_equipPos = -1
	
	if( IsWindowShow("Packet") == false ) then
		ToggleContainer()
	end
	this:Show()
end

function T3Basics_TuLingZhu_OnUpdateKWLZ(uiIndex, ItemPos)
	local theActionItem = EnumAction(ItemPos, "packageitem")	
	local itemIndex = PlayerPackage : GetItemTableIndex( ItemPos )
	
	if(g_KunwulingzhuID ~= itemIndex) then
		PushDebugMessage("#{TFJCGZ_20200817_13}")
		return
	end
	
	T3Basics_TuLingZhu_ClearItem()

	if( g_T3BT_equipPos ~= -1) then
		LifeAbility : Lock_Packet_Item(g_T3BT_equipPos,0)
	end
	
	g_T3BT_equipPos = ItemPos
	LifeAbility : Lock_Packet_Item(ItemPos,1)
	T3Basics_TuLingZhu_Object1:SetActionItem(theActionItem:GetID())
	T3Basics_TuLingZhu_OK:Enable()
		
	local nCount= TServerUI:GetItemParam( ItemPos, 3, 0 )
	local nx= TServerUI:GetItemParam( ItemPos, 6, 1 )
	local ny= TServerUI:GetItemParam( ItemPos, 8, 1 )
	if nx <= 0 or ny <= 0 then
		nCount= 30
	end
	local theAction = DataPool:CreateActionItemForShow(g_Tulingzhu, 1)
	if(nCount <= 0) then
	elseif nCount <= 10 then
		T3Basics_TuLingZhu_Object3:Show()
		T3Basics_TuLingZhu_Object3:SetActionItem(theAction:GetID())
	elseif nCount <= 20 then
		T3Basics_TuLingZhu_Object5:Show()
		T3Basics_TuLingZhu_Object6:Show()
		T3Basics_TuLingZhu_Object5:SetActionItem(theAction:GetID())
		T3Basics_TuLingZhu_Object6:SetActionItem(theAction:GetID())
	else
		T3Basics_TuLingZhu_Object2:Show()
		T3Basics_TuLingZhu_Object3:Show()
		T3Basics_TuLingZhu_Object4:Show()
		T3Basics_TuLingZhu_Object2:SetActionItem(theAction:GetID())
		T3Basics_TuLingZhu_Object3:SetActionItem(theAction:GetID())
		T3Basics_TuLingZhu_Object4:SetActionItem(theAction:GetID())
	end
end

function T3Basics_TuLingZhu_ClearItem()
	T3Basics_TuLingZhu_Object1:SetActionItem(-1)
	T3Basics_TuLingZhu_Object2:Hide()
	T3Basics_TuLingZhu_Object3:Hide()
	T3Basics_TuLingZhu_Object4:Hide()
	T3Basics_TuLingZhu_Object5:Hide()
	T3Basics_TuLingZhu_Object6:Hide()

	
	T3Basics_TuLingZhu_OK:Disable()
end

function T3Basics_TuLingZhu_Object1_RClicked()
	T3Basics_TuLingZhu_ClearItem()
	LifeAbility : Lock_Packet_Item(g_T3BT_equipPos,0)
	g_T3BT_equipPos = -1
	
	local theAction = DataPool:CreateActionItemForShow(g_Tulingzhu, 1)
	T3Basics_TuLingZhu_Object3:Show()
	T3Basics_TuLingZhu_Object3:SetActionItem(theAction:GetID())
end

function T3Basics_TuLingZhu_Object2_RClicked()

end

function T3Basics_TuLingZhu_Object3_RClicked()

end

function T3Basics_TuLingZhu_Object4_RClicked()

end

function T3Basics_TuLingZhu_OnHiden()
	T3Basics_TuLingZhu_Cancel_Clicked()
end

function T3Basics_TuLingZhu_Cancel_Clicked()
	if(g_T3BT_equipPos >= 0) then
		LifeAbility : Lock_Packet_Item(g_T3BT_equipPos,0)
	end
	
	g_T3BT_equipPos = -1
	if(IsWindowShow("Packet")) then
		CloseWindow("Packet", true);
	end 
	this:Hide()
end


function T3Basics_TuLingZhu_OK_Clicked()
	if(g_T3BT_equipPos == -1) then
		PushDebugMessage("#{TFJCGZ_20200817_17}")
		return
	end
	
	if PlayerPackage:IsLock( g_T3BT_equipPos ) == 1 then
		PushDebugMessage("#{TFJCGZ_20200817_18}")	
		return
	end

	local nx= TServerUI:GetItemParam( g_T3BT_equipPos, 6, 1 )
	local ny= TServerUI:GetItemParam( g_T3BT_equipPos, 8, 1 )
	
	if( TServerUI:GetItemParam( g_T3BT_equipPos, 3, 0 ) <= 0 and nx > 0 and ny > 0)then
		PushDebugMessage("#{TFJCGZ_20200817_19}")	
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoExchangeKunwulingzhu")
		Set_XSCRIPT_ScriptID(702039)
		Set_XSCRIPT_Parameter(0,g_T3BT_equipPos)
		Set_XSCRIPT_Parameter(1,g_T3BT_ServerObjid)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end


function T3Basics_TuLingZhu_Help_Clicked()
	

end

function T3Basics_TuLingZhu_On_ResetPos()
	T3Basics_TuLingZhu_Frame : SetProperty("UnifiedXPosition", g_T3BT_Frame_UnifiedXPosition);
	T3Basics_TuLingZhu_Frame : SetProperty("UnifiedYPosition", g_T3BT_Frame_UnifiedYPosition);

end

