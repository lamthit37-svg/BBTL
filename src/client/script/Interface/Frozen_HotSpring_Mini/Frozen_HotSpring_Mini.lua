--******************************************
--冰雪世界元旦打卡-泡温泉
--任务进度界面
--create by  limengyue 
--2024-10-09
--******************************************

local g_Frozen_HotSpring_Mini_Frame_UnifiedPosition;

--===============================================
-- OnLoad()
--===============================================
function Frozen_HotSpring_Mini_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BXSJ_PAOWENQUAN_MINI",true)
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
function Frozen_HotSpring_Mini_OnLoad()   
	-- 保存界面的默认相对位置
	g_Frozen_HotSpring_Mini_Frame_UnifiedPosition = Frozen_HotSpring_Mini_Frame:GetProperty("UnifiedPosition");
	
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_HotSpring_Mini_Frame_On_ResetPos()
	Frozen_HotSpring_Mini_Frame:SetProperty("UnifiedPosition", g_Frozen_HotSpring_Mini_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Frozen_HotSpring_Mini_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 99951202) then
		--关闭界面
		if(IsWindowShow("Frozen_HotSpring_Mini")) then
			CloseWindow("Frozen_HotSpring_Mini", true)
		end
	end
	if (event == "BXSJ_PAOWENQUAN_MINI") then
		--打开mini界面
		if(IsWindowShow("Frozen_HotSpring")) then
			CloseWindow("Frozen_HotSpring", true)
		end
		if(IsWindowShow("Frozen_HotSpring_Mini")) then
			CloseWindow("Frozen_HotSpring_Mini", true)
		end
		Frozen_HotSpring_Mini_Open()
	elseif (event == "ADJEST_UI_POS" ) then
		-- 游戏窗口尺寸发生了变化
		Frozen_HotSpring_Mini_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then	
		-- 游戏分辨率发生了变化
		Frozen_HotSpring_Mini_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       Frozen_HotSpring_Mini_OnClose()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end
         
end

--===============================================
-- Frozen_HotSpring_Mini_OnClose()
--===============================================
function Frozen_HotSpring_Mini_OnClose()
	this:Hide()
end


--=========================================================
--默认打开界面
--=========================================================
function Frozen_HotSpring_Mini_Open()
	--PushDebugMessage(" Frozen_HotSpring_Mini_Open")
	
	this:Show()		
end


--=========================================================
--打开详情界面
--=========================================================
function Frozen_HotSpring_Mini_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenFrozenHotSpring" )
		Set_XSCRIPT_ScriptID( 999512)	
		Set_XSCRIPT_Parameter( 0 ,0)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

