--******************************************
--大话西游打卡活动
--任务道具 毫毛
--limengyue 2024-05-28
--******************************************

local g_DaHua_DaKa_Frame_UnifiedPosition;

--===============================================
-- OnLoad()
--===============================================
function DaHua_DaKa_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--===============================================
-- OnLoad()
--===============================================
function DaHua_DaKa_OnLoad()   
	-- 保存界面的默认相对位置
	g_DaHua_DaKa_Frame_UnifiedPosition = DaHua_DaKa_Frame_BK:GetProperty("UnifiedPosition");
	
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function DaHua_DaKa_Frame_On_ResetPos()
	DaHua_DaKa_Frame_BK:SetProperty("UnifiedPosition", g_DaHua_DaKa_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function DaHua_DaKa_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 99913702) then
		--打开界面
		if(IsWindowShow("DaHua_Guide")) then
			CloseWindow("DaHua_Guide", true)
		end
		if(IsWindowShow("DaHua_DaKa")) then
			CloseWindow("DaHua_DaKa", true)
		end
		DaHua_DaKa_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99913703) then
		AutoRuntoTargetExWithName(238, 268, 0, "菩提小祖")
		DaHua_DaKa_OnClose()
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		DaHua_DaKa_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DaHua_DaKa_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       DaHua_DaKa_OnClose()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end
         
end

--===============================================
-- DaHua_DaKa_OnClose()
--===============================================
function DaHua_DaKa_OnClose()
	this:Hide()
end


--=========================================================
--默认打开界面
--=========================================================
function DaHua_DaKa_Open()
	--PushDebugMessage(" DaHua_DaKa_Open")

	this:Show()		
end

--=========================================================
--前往参与
--=========================================================
function DaHua_DaKa_GoTo()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenUIHelp")
		Set_XSCRIPT_ScriptID(999137)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


--=========================================================
--帮助
--=========================================================
function DaHua_DaKa_Help()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TipsHelp")
		Set_XSCRIPT_ScriptID(999137)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end



