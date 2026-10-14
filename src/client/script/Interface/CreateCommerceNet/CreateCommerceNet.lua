local g_clientNpcId = -1;
local MAX_OBJ_DISTANCE = 3.0;

local g_CreateCommerceNet_Frame_UnifiedPosition;

function CreateCommerceNet_PreLoad()
	this:RegisterEvent("OBJECT_CARED_EVENT");	
	this:RegisterEvent("CITY_SHOW_CREATE_ROAD");	
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

function CreateCommerceNet_OnLoad()
		g_CreateCommerceNet_Frame_UnifiedPosition=CreateCommerceNet_Frame:GetProperty("UnifiedPosition");
end

function CreateCommerceNet_OnEvent(event)
	if ( event == "OBJECT_CARED_EVENT") then
		City_CreateRoad_CareEventHandle(arg0,arg1,arg2);
	elseif(event == "CITY_SHOW_CREATE_ROAD") then
		if(this:IsVisible()) then
		else
			g_clientNpcId = tonumber(arg0);
			if(g_clientNpcId > 0) then
				this:CareObject(g_clientNpcId, 1, "CityCreateRoad");
			end
			CreateCommerceNet_Input:SetText("");
			CreateCommerceNet_Input:SetProperty("DefaultEditBox", "True");
			this:Show();
		end
	elseif (event == "ADJEST_UI_POS" ) then
		CreateCommerceNet_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CreateCommerceNet_Frame_On_ResetPos()
	end
end

function City_CreateRoad_Accept_Clicked()
	local txt = CreateCommerceNet_Input:GetText();
	if("" == txt) then return; end
	local guildId = tonumber(txt);
	
	City:DoConfirm(9, guildId);
	this:Hide();
end

function City_CreateRoad_Cancel_Clicked()
	this:Hide();
end

function City_CreateRoad_CareEventHandle(careId, op, distance)
		if(nil == careId or nil == op or nil == distance) then
			return;
		end
		
		if(tonumber(careId) ~= g_clientNpcId) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
			this:Hide();
			g_clientNpcId = -1;
		end
end

function City_CreateRoad_CheckState()
	local txt = CreateCommerceNet_Input:GetText();
	if("" == txt) then 
		CreateCommerceNet_Accept:Disable();
	else
		CreateCommerceNet_Accept:Enable();
	end
end

function CreateCommerceNet_Frame_On_ResetPos()
  CreateCommerceNet_Frame:SetProperty("UnifiedPosition", g_CreateCommerceNet_Frame_UnifiedPosition);
end