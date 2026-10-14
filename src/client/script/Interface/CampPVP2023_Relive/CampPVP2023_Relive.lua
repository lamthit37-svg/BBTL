--***********************************************************************************************************************************************
-- 复活界面		
--注意，此界面为复活专用，请不要用来做其他用途
--***********************************************************************************************************************************************
local Current_status = 0;
local Current_Quest = -1;
-------------------------------------------------------------------------------------------------------------------------------------------------
--
-- 此处定义需要保存数据的局部变量
--
local g_KillerGUID = "";
local g_KillerName = "";
local g_KillerZoneWorldID = -1;
--------------------------------------------------------
-- 当前对话框的操作类型
local g_Event;

local Event_CampPVP2023_Relive = 0;
local Event_Callof = 1;

local g_CampPVP2023_Relive_Frame_UnifiedXPosition = 0
local g_CampPVP2023_Relive_Frame_UnifiedYPosition = 0

--阵营pvp专用
local g_CampPVP2023_Relive_iszypvp = 0

--获取聊天输入框的位置大小，死亡后模拟点击聊天输入框
local g_Chat_EditboxX= 0
local g_Chat_EditboxY = 0
local g_Chat_EditboxWidth = 0
local g_Chat_EditboxHeight = 0

--***********************************************************************************************************************************************
--
-- OnLoad
--
--************************************************************************************************************************************************
function CampPVP2023_Relive_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("RELIVE_MODIFY",true);
    this:RegisterEvent("RELIVE_HIDE",false);
	this:RegisterEvent("ZYPVP_DIE", true)
	 this:RegisterEvent("UI_COMMAND", true);
	 this:RegisterEvent("RELIVE_REFESH_TIME",false);
end

function CampPVP2023_Relive_OnLoad()
	g_CampPVP2023_Relive_Frame_UnifiedXPosition = CampPVP2023_Relive_Frame:GetProperty("UnifiedXPosition")
	g_CampPVP2023_Relive_Frame_UnifiedYPosition = CampPVP2023_Relive_Frame:GetProperty("UnifiedYPosition")
end


--***********************************************************************************************************************************************
--
-- 事件响应函数
--
--
--************************************************************************************************************************************************
function CampPVP2023_Relive_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		CampPVP2023_Relive_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CampPVP2023_Relive_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "ZYPVP_DIE") then
		
		if (arg6 ~= nil) then
			g_KillerZoneWorldID = tonumber(arg6);
		else
			g_KillerZoneWorldID = -1
		end
		
		if tostring(arg4) ~= "" then--如果杀手名不为空
			g_KillerName = tostring(arg4)
			local killername = tostring(arg4)
			if g_KillerZoneWorldID ~= -1 and g_KillerZoneWorldID ~= DataPool:GetSelfZoneWorldID() then
				local servername = DataPool:GetServerName(g_KillerZoneWorldID)
				if servername ~= nil and servername ~= "" then
					killername = killername.."@"..servername
				end
			end
			CampPVP2023_Relive_Text1:SetText( "#{SWTS_20101029_02}"..tostring(arg3).."#{SWTS_20101029_03}"..killername.."#{SWTS_20101029_04}" );
		else
			CampPVP2023_Relive_Text1:SetText( "#{SWTS_20101029_02}"..tostring(arg3).."#{SWTS_20101029_13}" );
		end
		
		--有复活按钮
		if ( arg1 == "1" ) then
			CampPVP2023_Relive_Relive_Button:Enable();
		--无复活按钮
		else
			CampPVP2023_Relive_Relive_Button:Disable();
		end
		
		CampPVP2023_Relive_Text2:ClearAllElement();
		CampPVP2023_Relive_Text2:AddTextElement("#{ZYZC_220213_44}")
		CampPVP2023_Relive_Time_Text2:SetText("#{ZYZC_220213_45}")
		CampPVP2023_Relive_Release_Button:SetText("#{ZYZC_220213_47}")
		
		CampPVP2023_Relive_Time_Text : SetProperty("Timer",tostring(arg2));
		g_Event = Event_CampPVP2023_Relive;
		CampPVP2023_Relive_Help:Disable();
		CampPVP2023_Relive_Close:Disable();
		Current_status = 0;
		CampPVP2023_Relive_Text:SetText("#gFF0FA0复活");
		
		this:Show()
	elseif  (event == "RELIVE_HIDE") then
		this:Hide()
	elseif ( event == "RELIVE_REFESH_TIME" ) then
	
		CampPVP2023_Relive_Time_Text : SetProperty("Timer",tostring(arg0));
		Current_status = 0;
	elseif( event == "RELIVE_MODIFY") then
		
		--有复活按钮
		if ( arg1 == "1" ) then
			CampPVP2023_Relive_Relive_Button:Enable();
		--无复活按钮
		else
			CampPVP2023_Relive_Relive_Button:Disable();
		end
		
		

		CampPVP2023_Relive_Help:Disable();
		CampPVP2023_Relive_Close:Disable();
		Current_status = 0;
		CampPVP2023_Relive_Text:SetText("#gFF0FA0复活");

		
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CampPVP2023_Relive_ResetPos()
	CampPVP2023_Relive_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	CampPVP2023_Relive_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--***********************************************************************************************************************************************
--
-- 点击出窍按钮
--
--
--************************************************************************************************************************************************
function CampPVP2023_Relive_Out_Ghost()

	if(g_Event == Event_CampPVP2023_Relive)then
		if(Current_status == 1) then
			if(Current_Quest > -1) then
				QuestFrameMissionAbnegate(Current_Quest);
			end
			this:Hide();
			return;
		else
			Player:SendReliveMessage_OutGhost();
		end
		
	end

end


--计时器＝0
function CampPVP2023_Relive_Time_Zero()
	if( g_Event == Event_Callof )  then
		this:Hide();
	end;

end

function CampPVP2023_Relive_CampPVP2023_Relive()

	if( g_Event == Event_CampPVP2023_Relive )  then
		if(Current_status == 1) then
			this:Hide();
			return;
		else
			Player:SendReliveMessage_Relive();
		end;
		 
	end

end