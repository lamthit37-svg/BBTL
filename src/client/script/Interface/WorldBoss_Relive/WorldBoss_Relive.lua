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

local Event_WorldBoss_Relive = 0;
local Event_Callof = 1;

local g_WorldBoss_Relive_Frame_UnifiedXPosition = 0
local g_WorldBoss_Relive_Frame_UnifiedYPosition = 0

local g_RelivePos = {
	[1] = {255,166},
	[2] = {255,405},
	[3] = {375,273},
	[4] = {129,274}
}
local g_RelivePosStr = {
	[1] = "#{SJBS_240124_145}",
	[2] = "#{SJBS_240124_146}",
	[3] = "#{SJBS_240124_147}",
	[4] = "#{SJBS_240124_148}"
}
local g_RelivePosChoose = 1
local g_UI_RelivePosBtn = {}

--***********************************************************************************************************************************************
--
-- OnLoad
--
--************************************************************************************************************************************************
function WorldBoss_Relive_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("RELIVE_MODIFY",true);
    this:RegisterEvent("RELIVE_HIDE",false);
	this:RegisterEvent("TWB_DIE", true)
	this:RegisterEvent("UI_COMMAND", true);
	this:RegisterEvent("RELIVE_REFESH_TIME",false);
end

function WorldBoss_Relive_OnLoad()
	g_WorldBoss_Relive_Frame_UnifiedXPosition =WorldBoss_Relive_Frame:GetProperty("UnifiedXPosition")
	g_WorldBoss_Relive_Frame_UnifiedYPosition =WorldBoss_Relive_Frame:GetProperty("UnifiedYPosition")
	g_UI_RelivePosBtn[1] = WorldBoss_Relive_Text3_Btn1
	g_UI_RelivePosBtn[2] = WorldBoss_Relive_Text3_Btn2
	g_UI_RelivePosBtn[3] = WorldBoss_Relive_Text3_Btn3
	g_UI_RelivePosBtn[4] = WorldBoss_Relive_Text3_Btn4
end


--***********************************************************************************************************************************************
--
-- 事件响应函数
--
--
--************************************************************************************************************************************************
function WorldBoss_Relive_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		WorldBoss_Relive_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WorldBoss_Relive_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "TWB_DIE") then
		
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
			WorldBoss_Relive_Text1:SetText(ScriptGlobal_Format("#{SJBS_240124_142}",tostring(arg3),killername));
		else
			WorldBoss_Relive_Text1:SetText(ScriptGlobal_Format("#{SJBS_240124_142}",tostring(arg3),"unknown") );
		end
		
		--有复活按钮
		if ( arg1 == "1" ) then
			WorldBoss_Relive_Relive_Button:Enable();
		--无复活按钮
		else
			WorldBoss_Relive_Relive_Button:Disable();
		end

		WorldBoss_Relive_Text3_SelfClick(1)
		
		WorldBoss_Relive_Time_Text : SetProperty("Timer",tostring(arg2));
		g_Event = Event_WorldBoss_Relive;
		WorldBoss_Relive_Help:Disable();
		WorldBoss_Relive_Close:Disable();
		Current_status = 0;
		
		this:Show()
	elseif  (event == "RELIVE_HIDE") then
		this:Hide()
	elseif ( event == "RELIVE_REFESH_TIME" ) then
	
		WorldBoss_Relive_Time_Text : SetProperty("Timer",tostring(arg0));
		Current_status = 0;
	elseif( event == "RELIVE_MODIFY") then
		
		--有复活按钮
		if ( arg1 == "1" ) then
			WorldBoss_Relive_Relive_Button:Enable();
		--无复活按钮
		else
			WorldBoss_Relive_Relive_Button:Disable();
		end
		
		WorldBoss_Relive_Help:Disable();
		WorldBoss_Relive_Close:Disable();
		Current_status = 0;
		--WorldBoss_Relive_Text:SetText("#gFF0FA0复活");
		
	end
end

function WorldBoss_Relive_Text3_SelfClick(index)
	if index < 1 or index > 4 then
		return 
	end
	g_RelivePosChoose = index
	for i = 1, 4 do
		g_UI_RelivePosBtn[i]:Enable()
	end
	g_UI_RelivePosBtn[index]:Disable()

	WorldBoss_Relive_Text3:SetText("#{SJBS_240124_144}"..g_RelivePosStr[index])
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function WorldBoss_Relive_ResetPos()
	WorldBoss_Relive_Frame:SetProperty("UnifiedXPosition", g_WorldBoss_Relive_Frame_UnifiedXPosition);
	WorldBoss_Relive_Frame:SetProperty("UnifiedYPosition", g_WorldBoss_Relive_Frame_UnifiedYPosition);
end

--***********************************************************************************************************************************************
--
-- 点击出窍按钮
--
--
--************************************************************************************************************************************************
function WorldBoss_Relive_Out_Ghost()

	if(g_Event == Event_WorldBoss_Relive)then
		if(Current_status == 1) then
			if(Current_Quest > -1) then
				QuestFrameMissionAbnegate(Current_Quest);
			end
			this:Hide();
			return;
		else
			Player:SendReliveMessage_OutGhost();--去掉选择复活点功能了 重开时另想办法
		end
	end
end




--计时器＝0
function WorldBoss_Relive_Time_Zero()
	if( g_Event == Event_Callof )  then
		this:Hide();
	end;
end

function WorldBoss_Relive_WorldBoss_Relive()

	if( g_Event == Event_WorldBoss_Relive )  then
		if(Current_status == 1) then
			this:Hide();
			return;
		else
			Player:SendReliveMessage_Relive();
		end;
	end

end