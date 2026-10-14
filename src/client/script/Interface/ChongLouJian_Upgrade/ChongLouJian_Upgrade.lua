
--ChongLouJian_Upgrade
local g_ChongLouJian_Upgrade_item = 10415055
local g_ChongLouJian_Upgrade_needitem = 39901012
local g_ChongLouJian_Upgrade_ItemPos = -1
local g_ChongLouJian_Upgrade_normalAction;
local g_ChongLouJian_Upgrade_realAction;
local g_ChongLouJian_Upgrade_NPCID = -1
local g_ChongLouJian_Upgrade_OBJDISTANCE = 3.0;

local g_ChongLouJian_Upgrade_UnifiedPosition;
function ChongLouJian_Upgrade_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("EXCHONGLONG_EQUIP",false);	-- 
	this:RegisterEvent("RESUME_ENCHASE_GEM")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	

end

function ChongLouJian_Upgrade_OnLoad()
	g_ChongLouJian_Upgrade_normalAction = ChongLouJian_Upgrade_Object1;
	g_ChongLouJian_Upgrade_realAction = ChongLouJian_Upgrade_Object2;
	g_ChongLouJian_Upgrade_UnifiedPosition=ChongLouJian_Upgrade_Frame:GetProperty("UnifiedPosition")
	
end

function ChongLouJian_Upgrade_OnEvent(event)
	if (event == "UI_COMMAND") then
		if(tonumber(arg0) == 99860801 ) then
			ChongLouJian_Upgrade_OK:Disable()
			local NPCID = Get_XParam_INT(0);
			g_ChongLouJian_Upgrade_NPCID = DataPool:GetNPCIDByServerID(NPCID);
			ChongLouJian_Upgrade_BeginCareObject(g_ChongLouJian_Upgrade_NPCID)
			ChongLouJian_Upgrade_DataClean()
			this:Show()
		end
		
		if(tonumber(arg0) == 99860802) then
			ChongLouJian_Upgrade_DataClean()
		end
		return 
	end
	
	if (event == "EXCHONGLONG_EQUIP") then
		ChongLouJian_Upgrade_SetEquipData(tonumber(arg0))
		return
	end
	
	if(event == "RESUME_ENCHASE_GEM") then
		ChongLouJian_Upgrade_DataClean()
		return
	end
	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCaredId) then
			return;
		end
		
		if(arg1 == "distance" and tonumber(arg2) > g_ChongLouJian_Upgrade_OBJDISTANCE or arg1=="destroy" ) then
			ChongLouJian_Upgrade_OnHide()
		end
	end
	
	if (event == "ADJEST_UI_POS") then
		ChongLouJian_Upgrade_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		ChongLouJian_Upgrade_On_ResetPos()
		return
	end


end

function ChongLouJian_Upgrade_BeginCareObject(objCaredId)
	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "ChongLouJian_Upgrade");
end

function ChongLouJian_Upgrade_On_ResetPos()
  ChongLouJian_Upgrade_Frame:SetProperty("UnifiedPosition", g_ChongLouJian_Upgrade_UnifiedPosition);
end

function ChongLouJian_Upgrade_SetEquipData(pos)
	local pos_packet = tonumber(pos)
	if g_ChongLouJian_Upgrade_ItemPos ~= -1 then
		g_ChongLouJian_Upgrade_normalAction:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_ChongLouJian_Upgrade_ItemPos,0)
		g_ChongLouJian_Upgrade_ItemPos = -1	
	end
	g_ChongLouJian_Upgrade_ItemPos = pos_packet
	local theAction = EnumAction(pos_packet, "packageitem")
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	if ItemID ~= g_ChongLouJian_Upgrade_item then
		PushDebugMessage("#{CLSJ_190404_19}")
		return
	end
	

	LifeAbility:Lock_Packet_Item(pos_packet,1);
	g_ChongLouJian_Upgrade_normalAction:SetActionItem(theAction:GetID())
	
	ChongLouJian_Upgrade_CheckItem()

	ChongLouJian_Upgrade_CheckFullInfo()
end


function ChongLouJian_Upgrade_CheckItem()
	if(PlayerPackage:CountAvailableItemByIDTable(g_ChongLouJian_Upgrade_needitem) >= 840 ) then
		ChongLouJian_Upgrade_OK:Enable()
		ChongLouJian_Upgrade_Text3:SetText(ScriptGlobal_Format("#{CLJJ_230705_09}",840)) 
	else
		ChongLouJian_Upgrade_OK:Disable()
		ChongLouJian_Upgrade_Text3:SetText(ScriptGlobal_Format("#{CLJJ_230705_05}",840))
	end
	
end


function ChongLouJian_Upgrade_CheckFullInfo()
	if g_ChongLouJian_Upgrade_ItemPos >= 0 then
		local theAction = CreateRealChonglouModle(tonumber(g_ChongLouJian_Upgrade_ItemPos))
		g_ChongLouJian_Upgrade_realAction:SetActionItem(theAction:GetID())
	end
end
function ChongLouJian_Upgrade_OnHide()
	ChongLouJian_Upgrade_DataClean()
	this:Hide()
end


function ChongLouJian_Upgrade_OKClick()
	if (g_ChongLouJian_Upgrade_ItemPos == -1 ) then	
		return
	end	 

	if PlayerPackage:GetItemBindStatusByIndex(g_ChongLouJian_Upgrade_ItemPos) == 1 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientChange");
			Set_XSCRIPT_ScriptID(998608);
			Set_XSCRIPT_Parameter(0,g_ChongLouJian_Upgrade_ItemPos);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
	else 
		local index, bindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(g_ChongLouJian_Upgrade_needitem))
		if bindState == 1 then -- 
			PushEvent("EXCHONGLONG_ITEM_LLMZ", tonumber(g_ChongLouJian_Upgrade_ItemPos));
		else
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("ClientChange");
				Set_XSCRIPT_ScriptID(998608);
				Set_XSCRIPT_Parameter(0,g_ChongLouJian_Upgrade_ItemPos);
				Set_XSCRIPT_ParamCount(1);
			Send_XSCRIPT();				
		end	
	end
end


function ChongLouJian_Upgrade_DataClean()
	if (g_ChongLouJian_Upgrade_ItemPos ~= -1) then
		g_ChongLouJian_Upgrade_normalAction:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_ChongLouJian_Upgrade_ItemPos,0)
		g_ChongLouJian_Upgrade_ItemPos = -1
	end
	
	ChongLouJian_Upgrade_OK:Disable()
	ChongLouJian_Upgrade_Text3:SetText(ScriptGlobal_Format("#{CLJJ_230705_05}",840))
	g_ChongLouJian_Upgrade_realAction:SetActionItem(-1)
end
