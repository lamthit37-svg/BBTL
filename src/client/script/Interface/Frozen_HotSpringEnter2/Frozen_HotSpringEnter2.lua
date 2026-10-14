--******************************************
--冰雪世界元旦打卡-泡温泉
--指引界面
--create by  limengyue 
--2024-10-09
--******************************************

local g_Frozen_HotSpringEnter2_Frame_UnifiedPosition;

--===============================================
-- OnLoad()
--===============================================
function Frozen_HotSpringEnter2_PreLoad()
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
function Frozen_HotSpringEnter2_OnLoad()   
	-- 保存界面的默认相对位置
	g_Frozen_HotSpringEnter2_Frame_UnifiedPosition = Frozen_HotSpringEnter2_Frame_BK:GetProperty("UnifiedPosition");
	
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_HotSpringEnter2_Frame_On_ResetPos()
	Frozen_HotSpringEnter2_Frame_BK:SetProperty("UnifiedPosition", g_Frozen_HotSpringEnter2_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Frozen_HotSpringEnter2_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 99951303) then
		--打开界面
		if(IsWindowShow("Frozen_Guide")) then
			CloseWindow("Frozen_Guide", true)
		end
		if(IsWindowShow("Frozen_HotSpringEnter2")) then
			CloseWindow("Frozen_HotSpringEnter2", true)
		end
		Frozen_HotSpringEnter2_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99951304) then
		AutoRuntoTargetExWithName(92, 126, 1007, "小兔兔")
		Frozen_HotSpringEnter2_OnClose()
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Frozen_HotSpringEnter2_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_HotSpringEnter2_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       Frozen_HotSpringEnter2_OnClose()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end
         
end

--===============================================
-- Frozen_HotSpringEnter2_OnClose()
--===============================================
function Frozen_HotSpringEnter2_OnClose()
	this:Hide()
end


--=========================================================
--默认打开界面
--=========================================================
function Frozen_HotSpringEnter2_Open()
	--PushDebugMessage(" Frozen_HotSpringEnter2_Open")
	-- if KaJi:LuaFnIsKaJiServer() ~= 1 then
		-- Frozen_HotSpringEnter2_Text:SetText("#{BXPWQ_240927_84}")
	-- else
		-- --卡级服
		-- Frozen_HotSpringEnter2_Text:SetText("缺字典")
	-- end
	this:Show()		
end

--=========================================================
--前往参与
--=========================================================
function Frozen_HotSpringEnter2_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenUIHelp")
		Set_XSCRIPT_ScriptID(999513)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


--=========================================================
--帮助
--=========================================================
function Frozen_HotSpringEnter2_Help()
	if KaJi:LuaFnIsKaJiServer() ~= 1 then
		PushEvent("QUEST_HELPINFO", "#{BXPWQ_240927_07}")
	else
		--卡级服
		PushEvent("QUEST_HELPINFO", "#{BXPWQ_240927_88}")
	end
end



