local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local Exchange_Rate = 1;
local g_Point = 0;
local g_Object = -1;
local g_JiFenExchange_Frame_UnifiedPosition;
function JiFenExchange_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function JiFenExchange_OnLoad()
	g_JiFenExchange_Frame_UnifiedPosition=JiFenExchange_Frame:GetProperty("UnifiedPosition");
end

function JiFenExchange_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 20101213 ) then
			if this:IsVisible() then
				JiFenExchange_Close();
				return
			end
			g_Object = Get_XParam_INT(0);
			BeginCareObject_JiFenExchange(Target:GetServerId2ClientId(g_Object));
			JiFenExchange_Moral_Value:SetProperty("DefaultEditBox", "True");
			JiFenExchange_Moral_Value:SetSelected( 0, -1 );
			JiFenExchange_OnShown();
			this:Show();
			JiFenExchange_Count_Change();
			JiFenExchange_Max:Disable()
			JiFenExchange_OK : Disable()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20101214 ) then
		if(this:IsVisible()) then
			JiFenExchange_Moral_Value:SetProperty("DefaultEditBox", "True");
			JiFenExchange_Moral_Value:SetSelected( 0, -1 );
			g_Point = Get_XParam_INT(0);
			JiFenExchange_Text4 : SetText("#{FQ_XML_04}"..g_Point)
			local FanQuan = g_Point*Exchange_Rate
			JiFenExchange_Text5 : SetText("#{YBXD_141218_01}"..FanQuan)
			JiFenExchange_Max:Enable()
			JiFenExchange_OK:Enable()
			JiFenExchange_Moral_Value:Enable();
		end
	elseif ( event == "OBJECT_CARED_EVENT") then
		JiFenExchange_CareEventHandle(arg0,arg1,arg2);
		-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		JiFenExchange_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JiFenExchange_Frame_On_ResetPos()
	end
end

function JiFenExchange_OnShown()
	JiFenExchange_Clear();
	JiFenExchange_Update();
end

function JiFenExchange_Clear()
	JiFenExchange_Moral_Value : SetText("")
	JiFenExchange_Text3 : SetText("")
	JiFenExchange_Text4 : SetText("")
	JiFenExchange_Text5 : SetText("")
	g_Point = 0;
	Exchange_Rate = 1;
end

function JiFenExchange_Update()
	Exchange_Rate = Get_XParam_INT(1)
	
	if GameProduceLogin:IsWeGameClient() > 0 then
		JiFenExchange_Text1:SetText("#{WEJR_230303_31}")
	else
		JiFenExchange_Text1:SetText("#{FQ_XML_02}")
	end
	
	JiFenExchange_Text4 : SetText("#{FQ_XML_07}")
	JiFenExchange_Text5 : SetText("#{YBXD_141218_01}")
	JiFenExchange_Text3 : SetText("#{FQ_XML_06}"..tostring(0))
end

function JiFenExchange_CareEventHandle(careId, op, distance)
		if(nil == careId or nil == op or nil == distance) then
			return;
		end
		
		if(tonumber(careId) ~= g_clientNpcId) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
			JiFenExchange_Close();
		end
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_JiFenExchange(objCaredId)

	g_Object = objCaredId;
	--AxTrace(0,0,"LUA___CareObject g_Object =" .. g_Object );
	this:CareObject(g_Object, 1, "JiFenExchange");

end

function JiFenExchange_Count_Change()
	local str = JiFenExchange_Moral_Value : GetText();
	local strNumber = 0;	
	
	if ( str == nil ) then
		return;
	elseif( str == "" ) then
		strNumber = 1;
	else
		strNumber = tonumber( str );
	end
	str = tostring( strNumber );
	JiFenExchange_Moral_Value:SetTextOriginal( str );
	JiFenExchange_Text3 : SetText("#{FQ_XML_06}"..tostring( Exchange_Rate * strNumber ) )
end

function JiFenExchange_Close()
	JiFenExchange_OnHiden();
	this:Hide()
end

function JiFenExchange_Cancel_Clicked()
	JiFenExchange_Close();
	return;
end

function JiFenExchange_OnHiden()
	StopCareObject_JiFenExchange(objCared)
	JiFenExchange_Clear()
	return
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_JiFenExchange(objCaredId)
	this:CareObject(objCaredId, 0, "JiFenExchange");
	g_Object = -1;
end

function JiFenExchange_Max_Clicked()
	local maxJiFen = 500000;
	local point2JiFen = g_Point/Exchange_Rate;
	if point2JiFen < 0 then point2JiFen = 0; end
	
	JiFenExchange_Moral_Value:SetProperty("ClearOffset", "True");
	if point2JiFen > maxJiFen then
		JiFenExchange_Moral_Value:SetText(tostring(maxJiFen));
	else
		JiFenExchange_Moral_Value:SetText(tostring(point2JiFen));
	end
	JiFenExchange_Moral_Value:SetProperty("CaratIndex", 1024);
end

function JiFenExchange_OK_Clicked()
	local str = JiFenExchange_Moral_Value : GetText();
	

	if str == nil or str == "" then
		JiFenExchange_Text3 : SetText("#{FQ_XML_06}"..tostring(0))
		PushDebugMessage("#{FQ_XML_03}")
		return
	end
	
	if tonumber(str) > 500000 then
		PushDebugMessage("#{FQ_101210_14}")
		return
	end
	if( tonumber(str) <= 0 ) then
		PushDebugMessage("#{FQ_101210_15}")
		return
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ExchangeJiFen");
		Set_XSCRIPT_ScriptID(181000);
		Set_XSCRIPT_Parameter(0,tonumber(str));
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	
	
	JiFenExchange_Close();
end
function JiFenExchange_Frame_On_ResetPos()
	JiFenExchange_Frame:SetProperty("UnifiedPosition", g_JiFenExchange_Frame_UnifiedPosition);
end