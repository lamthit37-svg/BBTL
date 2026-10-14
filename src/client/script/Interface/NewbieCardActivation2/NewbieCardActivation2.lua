local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local g_uicmd = 0;
local g_cardId = -1;

local g_NewbieCardActivation2_Frame_UnifiedXPosition;
local g_NewbieCardActivation2_Frame_UnifiedYPosition;

function NewbieCardActivation2_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("NewUserCard_Check_Result");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NewbieCardActivation2_OnLoad()
g_NewbieCardActivation2_Frame_UnifiedXPosition	= NewbieCardActivation2_Frame:GetProperty("UnifiedXPosition");
g_NewbieCardActivation2_Frame_UnifiedYPosition	= NewbieCardActivation2_Frame:GetProperty("UnifiedYPosition");
end

function NewbieCardActivation2_OnEvent(event)
	--if(event == "UI_COMMAND" and not this:IsVisible()) then
	if(event == "UI_COMMAND") then
		if tonumber(arg0) == 20111020
		then
			objCared = Get_XParam_INT(0);
			g_cardId = Get_XParam_INT(1);
			objCared = Target:GetServerId2ClientId(objCared);
			NewUserCard2_SetText(g_cardId);
			this:CareObject(objCared, 1, "NewUserCard2");
			NewbieCardActivation2_Input:SetProperty("DefaultEditBox", "True");
			this:Show();
			g_uicmd = tonumber(arg0);
		end
	elseif(event == "OBJECT_CARED_EVENT") then
		--AxTrace(0, 0, "arg0:"..arg0.." arg1:"..arg1.." arg2:"..arg2.." objCared:"..objCared);
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Guild_Create_Close();
		end

	elseif(event == "NewUserCard_Check_Result")then
		local result = tonumber(arg0)
		if(tonumber(arg0)== 0) then
			NewUserCard2_Close();
			return;
		end
		if(tonumber(arg0)== 1 or tonumber(arg0)== 2) then
			NewbieCardActivation2_Input:SetProperty("DefaultEditBox", "True");
			NewbieCardActivation2_Input:SetSelected( 0, -1 );
			return;
		end
	elseif( event == "ADJEST_UI_POS" ) then
		NewbieCardActivation2_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NewbieCardActivation2_ResetPos()

	end

end

function NewUserCard2_Open_Click()
	local cardNum = NewbieCardActivation2_Input:GetText();
	if(0 == string.len(cardNum)) then return; end
	
	--因为与KFC合作制出的卡只能印出大写，并且使用的是AABD，而已有小写aabd，这就存在一定问题，
	--这里直接把大写AABD转换成小写，再走后续流程。
	--等这批卡过期，把这块代码删除即可
	local CardPrefix = string.sub(cardNum, 0, 5)
	if CardPrefix == "AABD6" then
		cardNum = string.lower(cardNum);
	end
	
	CardPrefix = string.len(cardNum)
	if CardPrefix == 8 and string.upper(cardNum) == "TLBB8888" then
		cardNum = string.upper(cardNum);
	end

	NewUserCard(cardNum,g_cardId,1)	--参数3: 0为物品卡, 1为财富卡
end

function NewUserCard2_Close()
	this:Hide();
	this:CareObject(objCared, 0, "NewUserCard2");
	g_uicmd = 0;
end

function NewUserCard2_SetText(uicmd)
	if uicmd == 2084 then	--财富卡激活
		NewbieCardActivation2_DragTitle:SetText("#{INTERFACE_XML_73}");
		NewbieCardActivation2_Text:SetText("#{INTERFACE_XML_536}");
	elseif uicmd == 889262 then --畅游金卡激活
		NewbieCardActivation2_DragTitle:SetText("#{CYJK_101027_08}");
		NewbieCardActivation2_Text:SetText("#{CYJK_101027_09}");
	end

	NewbieCardActivation2_Input:SetText("");
end

function NewbieCardActivation2_ResetPos()
	NewbieCardActivation2_Frame:SetProperty("UnifiedXPosition", g_NewbieCardActivation2_Frame_UnifiedXPosition);
	NewbieCardActivation2_Frame:SetProperty("UnifiedYPosition", g_NewbieCardActivation2_Frame_UnifiedYPosition);

end
