local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_ChangYouJia_Plus_Time=0;
local g_ChangYouJia_Plus_OpName='';
local g_ChangYouJia_Plus_CanCheck=1;

function ChangYouJia_Plus_PreLoad()

	this:RegisterEvent("OPEN_CHANGYOUJIA_PLUS")
	this:RegisterEvent("CHANGYOUJIA_PLUS_RESULT")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

end

function ChangYouJia_Plus_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ChangYouJia_Plus_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ChangYouJia_Plus_Frame:GetProperty("UnifiedYPosition");
	ChangYouJia_Plus_Clear()

end

function ChangYouJia_Plus_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		ChangYouJia_Plus_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ChangYouJia_Plus_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
	elseif ( event == "OPEN_CHANGYOUJIA_PLUS") then
	
		ChangYouJia_Plus_Clear()
		g_ChangYouJia_Plus_OpName = tostring(arg0);
		local szText = ScriptGlobal_Format( "#{GWYZ_190925_05}", g_ChangYouJia_Plus_OpName)
		ChangYouJia_Plus_Lace1_SimpleText:SetText( szText );
		this:Show()
		
	elseif ( event == "CHANGYOUJIA_PLUS_RESULT" ) then
		ChangYouJia_Plus_OnResult( tonumber(arg0) )
			
	end
end

function ChangYouJia_Plus_OnResult( nResult )

	if nResult == 0 then			-- 验证成功
		PushDebugMessage("#{GWYZ_190925_17}");
		g_ChangYouJia_Plus_CanCheck = 0;
		ChangYouJia_Plus_Clear()
		ChangYouJia_Plus_Button:SetText("#{GWYZ_190925_12}")
		
	elseif nResult == 1 then	-- 验证失败
		PushDebugMessage("#{GWYZ_190925_16}");
		ChangYouJia_Plus_Clear()
	
	elseif nResult == 2 then	-- 没有绑定畅游+
		PushDebugMessage("#{GWYZ_190925_13}");
		this:Hide();
	
	elseif nResult == 3 then	-- 仍在高危验证安全周期内
		this:Hide();
	
	elseif nResult == 4 then	-- 服务器时间60s限制未到
		PushDebugMessage("#{GWYZ_190925_14}");
	
	elseif nResult == 5 then	-- 点击等待验证成功
		PushDebugMessage("#{GWYZ_190925_15}");
		
		KillTimer("ChangYouJia_Plus_TimerHandler()")
		g_ChangYouJia_Plus_Time = 60;
		ChangYouJia_Plus_Time:Show();
		ChangYouJia_Plus_TimerHandler();
		SetTimer( "ChangYouJia_Plus", "ChangYouJia_Plus_TimerHandler()", 1000 )
	
		ChangYouJia_Plus_Lace3_Text:SetText("#{GWYZ_190925_11}")
		ChangYouJia_Plus_Button:SetText("#{GWYZ_190925_09}")
		ChangYouJia_Plus_Button:Disable();
	
	elseif nResult == 6 then	-- 验证超时
		PushDebugMessage("#{GWYZ_190925_18}");
		ChangYouJia_Plus_Clear()
		
	end
end

function ChangYouJia_Plus_OnCheck()

	if g_ChangYouJia_Plus_CanCheck ~= 1 then
		return
	end
	Lua_CheckChangYouJiaPlus( g_ChangYouJia_Plus_OpName );
		
end

function ChangYouJia_Plus_TimerHandler()

	if g_ChangYouJia_Plus_Time > 0 then
		local szTime = ScriptGlobal_Format( "#{GWYZ_190925_10}", tostring(g_ChangYouJia_Plus_Time))
		ChangYouJia_Plus_Time:SetText( szTime )
		g_ChangYouJia_Plus_Time = g_ChangYouJia_Plus_Time - 1	
				
	else
		ChangYouJia_Plus_Clear();

	end
	
end

function ChangYouJia_Plus_Clear()
	ChangYouJia_Plus_Time:Hide();
	
	g_ChangYouJia_Plus_CanCheck = 1;
	g_ChangYouJia_Plus_Time = 0;
	ChangYouJia_Plus_Time:SetText( "" )
	KillTimer("ChangYouJia_Plus_TimerHandler()")
	ChangYouJia_Plus_Lace3_Text:SetText("")
	ChangYouJia_Plus_Button:SetText("#{GWYZ_190925_07}")
	ChangYouJia_Plus_Button:Enable();
end

function ChangYouJia_Plus_OnHiden()
	ChangYouJia_Plus_Clear()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ChangYouJia_Plus_ResetPos()
	ChangYouJia_Plus_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ChangYouJia_Plus_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

