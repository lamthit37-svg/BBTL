
--Zhen_chonglou
local g_Zhen_chonglou_item = 10415055
local g_Zhen_chonglou_needitem = 38002780
local g_Zhen_chonglou_ItemPos = -1
local g_Zhen_chonglou_normalAction;
local g_Zhen_chonglou_realAction;
local g_Zhen_chonglou_NPCID = -1
local g_Zhen_chonglou_OBJDISTANCE = 3.0;

local g_Zhen_chonglou_UnifiedPosition;
function Zhen_chonglou_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("EXCHONGLONG_EQUIP",false);	--放入重楼
	this:RegisterEvent("RESUME_ENCHASE_GEM")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	

end

function Zhen_chonglou_OnLoad()
	g_Zhen_chonglou_normalAction = Zhen_chonglou_Object1;
	g_Zhen_chonglou_realAction = Zhen_chonglou_Object3;
	g_Zhen_chonglou_UnifiedPosition=Zhen_chonglou_Frame:GetProperty("UnifiedPosition")
	
end

function Zhen_chonglou_OnEvent(event)
	if (event == "UI_COMMAND") then
		if(tonumber(arg0) == 20150511 ) then
			Zhen_chonglou_OK:Disable()
			local NPCID = Get_XParam_INT(0);
			g_Zhen_chonglou_NPCID = DataPool:GetNPCIDByServerID(NPCID);
			Zhen_chonglou_BeginCareObject(g_Zhen_chonglou_NPCID)
			Zhen_chonglou_DataClean()
			this:Show()
		end
		
		if(tonumber(arg0) == 20150514) then
			Zhen_chonglou_DataClean()
		end
		return 
	end
	
	if (event == "EXCHONGLONG_EQUIP") then
		Zhen_chonglou_SetEquipData(tonumber(arg0))
		return
	end
	
	if(event == "RESUME_ENCHASE_GEM") then
		Zhen_chonglou_DataClean()
		return
	end
	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCaredId) then
			return;
		end
		
		if(arg1 == "distance" and tonumber(arg2) > g_Zhen_chonglou_OBJDISTANCE or arg1=="destroy" ) then
			Zhen_chonglou_OnHide()
		end
	end
	
	if (event == "ADJEST_UI_POS") then
		Zhen_chonglou_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		Zhen_chonglou_On_ResetPos()
		return
	end


end

function Zhen_chonglou_BeginCareObject(objCaredId)
	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "Zhen_chonglou");
end

function Zhen_chonglou_On_ResetPos()
  Zhen_chonglou_Frame:SetProperty("UnifiedPosition", g_Zhen_chonglou_UnifiedPosition);
end

function Zhen_chonglou_SetEquipData(pos)
	local pos_packet = tonumber(pos)
	if g_Zhen_chonglou_ItemPos ~= -1 then
		g_Zhen_chonglou_normalAction:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_Zhen_chonglou_ItemPos,0)
		g_Zhen_chonglou_ItemPos = -1	
	end
	g_Zhen_chonglou_ItemPos = pos_packet
	local theAction = EnumAction(pos_packet, "packageitem")
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	if ItemID ~= g_Zhen_chonglou_item then
		PushDebugMessage("#{CLSJ_190404_19}")
		return
	end
	

	LifeAbility:Lock_Packet_Item(pos_packet,1);
	g_Zhen_chonglou_normalAction:SetActionItem(theAction:GetID())
	
	Zhen_chonglou_CheckItem()

	Zhen_chonglou_CheckFullInfo()
end


function Zhen_chonglou_CheckItem()
	if(PlayerPackage:CountAvailableItemByIDTable(g_Zhen_chonglou_needitem) >= 200) then
		Zhen_chonglou_OK:Enable()
		Zhen_chonglou_Text2_1:SetText(ScriptGlobal_Format("#{CLSJ_190404_22}",200)) 
	else
		Zhen_chonglou_OK:Disable()
		Zhen_chonglou_Text2_1:SetText(ScriptGlobal_Format("#{CLSJ_190404_23}",200))
	end
	
end


function Zhen_chonglou_CheckFullInfo()
	if g_Zhen_chonglou_ItemPos >= 0 then
		local theAction = CreateRealChonglouModle(tonumber(g_Zhen_chonglou_ItemPos))
		g_Zhen_chonglou_realAction:SetActionItem(theAction:GetID())
	end
end
function Zhen_chonglou_OnHide()
	Zhen_chonglou_DataClean()
	this:Hide()
end


function Zhen_chonglou_OKClick()
	if (g_Zhen_chonglou_ItemPos == -1 ) then
	
		return
	end
	 

	if PlayerPackage:GetItemBindStatusByIndex(g_Zhen_chonglou_ItemPos) == 1 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientChange");
			Set_XSCRIPT_ScriptID(890921);
			Set_XSCRIPT_Parameter(0,g_Zhen_chonglou_ItemPos);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
	else 
		local index, bindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(g_Zhen_chonglou_needitem))
		if bindState == 1 then --有绑定的需要二次确�?
		--二次确认
			PushEvent("EXCHONGLONG_ITEM", tonumber(g_Zhen_chonglou_ItemPos));
		else
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("ClientChange");
				Set_XSCRIPT_ScriptID(890921);
				Set_XSCRIPT_Parameter(0,g_Zhen_chonglou_ItemPos);
				Set_XSCRIPT_ParamCount(1);
			Send_XSCRIPT();				
		end
	
	end


end


function Zhen_chonglou_DataClean()
	if (g_Zhen_chonglou_ItemPos ~= -1) then
		g_Zhen_chonglou_normalAction:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_Zhen_chonglou_ItemPos,0)
		g_Zhen_chonglou_ItemPos = -1
	end
	
	Zhen_chonglou_OK:Disable()
	Zhen_chonglou_Text2_1:SetText(ScriptGlobal_Format("#{CLSJ_190404_23}",200))
	g_Zhen_chonglou_realAction:SetActionItem(-1)
end
