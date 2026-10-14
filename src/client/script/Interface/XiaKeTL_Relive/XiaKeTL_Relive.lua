--***********************************************************************************************************************************************
-- 复活界面		
--注意，此界面为复活专用，请不要用来做其他用途
-- !!!reloadscript =XiaKeTL_Relive
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

local Event_XiaKeTL_Relive = 0;
local Event_Callof = 1;

local g_XiaKeTL_Relive_Frame_UnifiedXPosition = 0
local g_XiaKeTL_Relive_Frame_UnifiedYPosition = 0

-- 自动复活时间，避开系统设置的5分钟，提前2分钟自动复活，防止走系统的自动复活逻辑
local g_nAutoReliveOutGhostTime = 60 * 3

local g_RelivePosStr = {
	[1] = "#{YWXK_250113_76}",
	[2] = "#{YWXK_250113_77}",
	[3] = "#{YWXK_250113_75}",
	[4] = "#{YWXK_250113_74}"
}
local g_RelivePosChoose = 1
local g_UI_RelivePosBtn = {}

--***********************************************************************************************************************************************
--
-- OnLoad
--
--************************************************************************************************************************************************
function XiaKeTL_Relive_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("RELIVE_MODIFY",true);
    this:RegisterEvent("RELIVE_HIDE",false);
	this:RegisterEvent("RELIVE_IN_XIAKE_BOSS_SCENE", true)
	this:RegisterEvent("UI_COMMAND", true);
	this:RegisterEvent("RELIVE_REFESH_TIME",false);
end

function XiaKeTL_Relive_OnLoad()
	g_XiaKeTL_Relive_Frame_UnifiedXPosition =XiaKeTL_Relive_Frame:GetProperty("UnifiedXPosition")
	g_XiaKeTL_Relive_Frame_UnifiedYPosition =XiaKeTL_Relive_Frame:GetProperty("UnifiedYPosition")
	g_UI_RelivePosBtn[1] = XiaKeTL_Relive_Text3_Btn1
	g_UI_RelivePosBtn[2] = XiaKeTL_Relive_Text3_Btn2
	g_UI_RelivePosBtn[3] = XiaKeTL_Relive_Text3_Btn3
	g_UI_RelivePosBtn[4] = XiaKeTL_Relive_Text3_Btn4
end


--***********************************************************************************************************************************************
--
-- 事件响应函数
--
--
--************************************************************************************************************************************************
function XiaKeTL_Relive_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		XiaKeTL_Relive_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiaKeTL_Relive_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "RELIVE_IN_XIAKE_BOSS_SCENE") then
		
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

			local strShow = "#{SWTS_20101029_02}"..tostring(arg3).."#{SWTS_20101029_03}"..killername.."#{SWTS_20101029_04}"
			XiaKeTL_Relive_Text1:SetText(strShow);
		else

			local strShow = "#{SWTS_20101029_02}"..tostring(arg3).."#{SWTS_20101029_13}"
			XiaKeTL_Relive_Text1:SetText( strShow );
		end
		
		--有复活按钮
		if ( arg1 == "1" ) then
			XiaKeTL_Relive_Relive_Button:Enable();
		--无复活按钮
		else
			XiaKeTL_Relive_Relive_Button:Disable();
		end

		XiaKeTL_Relive_Text3_SelfClick(1)
		
		-- XiaKeTL_Relive_Time_Text : SetProperty("Timer",tostring(arg2));
		-- 自动复活时间，避开系统设置的5分钟，提前2分钟自动复活，防止走系统的自动复活逻辑
		XiaKeTL_Relive_Time_Text : SetProperty("Timer", g_nAutoReliveOutGhostTime);

		g_Event = Event_XiaKeTL_Relive;
		XiaKeTL_Relive_Help:Disable();
		XiaKeTL_Relive_Close:Disable();
		Current_status = 0;
		
		this:Show()
	elseif  (event == "RELIVE_HIDE") then
		this:Hide()
	-- elseif ( event == "RELIVE_REFESH_TIME" ) then
	
	-- 	XiaKeTL_Relive_Time_Text : SetProperty("Timer",tostring(arg0));
	-- 	Current_status = 0;
	elseif( event == "RELIVE_MODIFY") then
		
		--有复活按钮
		if ( arg1 == "1" ) then
			XiaKeTL_Relive_Relive_Button:Enable();
		--无复活按钮
		else
			XiaKeTL_Relive_Relive_Button:Disable();
		end
		
		XiaKeTL_Relive_Help:Disable();
		XiaKeTL_Relive_Close:Disable();
		Current_status = 0;
		--XiaKeTL_Relive_Text:SetText("#gFF0FA0复活");
		
	end
end

function XiaKeTL_Relive_Text3_SelfClick(index)
	if index < 1 or index > 4 then
		return 
	end
	g_RelivePosChoose = index
	for i = 1, 4 do
		g_UI_RelivePosBtn[i]:Enable()
	end
	g_UI_RelivePosBtn[index]:Disable()

	-- XiaKeTL_Relive_Text3:SetText("#{YWXK_250113_78}"..g_RelivePosStr[index])
	XiaKeTL_Relive_Text3:SetText("#{YWXK_250113_73}")
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function XiaKeTL_Relive_ResetPos()
	XiaKeTL_Relive_Frame:SetProperty("UnifiedXPosition", g_XiaKeTL_Relive_Frame_UnifiedXPosition);
	XiaKeTL_Relive_Frame:SetProperty("UnifiedYPosition", g_XiaKeTL_Relive_Frame_UnifiedYPosition);
end

--***********************************************************************************************************************************************
--
-- 点击出窍按钮
--
--
--************************************************************************************************************************************************
function XiaKeTL_Relive_Out_Ghost()
	-- PushDebugMessage("XiaKeTL_Relive_Out_Ghost")

	if(g_Event == Event_XiaKeTL_Relive)then
		-- PushDebugMessage("XiaKeTL_Relive_Out_Ghost 1")
		if(Current_status == 1) then
			-- PushDebugMessage("XiaKeTL_Relive_Out_Ghost 2")
			if(Current_Quest > -1) then
				QuestFrameMissionAbnegate(Current_Quest);
			end
			this:Hide();			
			return;
		else
			-- PushDebugMessage("XiaKeTL_Relive_Out_Ghost 3")
			-- 绕开正常逻辑 直接调服务器专属复活逻辑
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnPlayerOutGhostRelive" )
				Set_XSCRIPT_ScriptID(790100)
				Set_XSCRIPT_Parameter(0, g_RelivePosChoose)					
				Set_XSCRIPT_Parameter(1, 1)				
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end
	end
end




--计时器＝0
function XiaKeTL_Relive_Time_Zero()

	-- 绕开正常逻辑 直接调服务器专属复活逻辑
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnPlayerOutGhostRelive" )
		Set_XSCRIPT_ScriptID(790100)
		Set_XSCRIPT_Parameter(0, g_RelivePosChoose)					
		Set_XSCRIPT_Parameter(1, 1)				
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	if( g_Event == Event_Callof )  then
		this:Hide();
	end;
end

function XiaKeTL_Relive_XiaKeTL_Relive()

	if( g_Event == Event_XiaKeTL_Relive )  then
		if(Current_status == 1) then
			this:Hide();
			return;
		else
			Player:SendReliveMessage_Relive();
		end;
	end

end