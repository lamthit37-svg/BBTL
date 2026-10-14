--ZidianLottery.lua
local g_UnifiedPosition;
local g_bIsDownTickStart=0
local g_DownTick=0
local g_IsShowTick=0
local g_TimerID=-1
local g_ZidianLottery_ActionButton = {};

function ZidianLottery_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
end

function ZidianLottery_OnLoad()

	g_ZidianLottery_ActionButton[1] = ZidianLottery_Item1;
	g_ZidianLottery_ActionButton[2] = ZidianLottery_Item2;
	g_ZidianLottery_ActionButton[3] = ZidianLottery_Item3;
	g_ZidianLottery_ActionButton[4] = ZidianLottery_Item4;
	g_ZidianLottery_ActionButton[5] = ZidianLottery_Item5;
	
	g_UnifiedPosition	= ZidianLottery_Frame:GetProperty("UnifiedPosition");
	
end

function ZidianLottery_OnEvent(event)

		if 1==1 then
			return
		end
		
	if ( event == "UI_COMMAND" and tonumber(arg0) == 50603602 ) then
		g_bIsDownTickStart = Get_XParam_INT(0);
		g_DownTick = Get_XParam_INT(1);
		
		ZidianLottery_ShowDownTick()
		if g_TimerID >= 0 then
			KillTimer( g_TimerID );
		end
		g_TimerID = SetTimer("ZidianLottery", "ZidianLottery_ShowDownTick()", 1000)
		
		DataPool:Lua_ClearZiDianZengYingHaoActionItem();
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 0, 39921019 );		--飞凰羽翼永久
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 1, 39921044 );		--飞凰羽翼90
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 2, 39921045 );		--飞凰羽翼30
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 3, 39921218 );		--福瑞锦龙7
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 4, 39921217 );		--战天狼7
		DataPool:Lua_UpdateZiDianZengYingHaoActionItem();
		for i = 1 , 5 do
			local theAction = EnumAction(i - 1, "zidianzengyinghao")
			if theAction:GetID() ~= 0 then	
				g_ZidianLottery_ActionButton[i]:SetActionItem(theAction:GetID())
			end
		end
		
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 50603605 ) then
		g_bIsDownTickStart = Get_XParam_INT( 0 );		--是否开始的标志
		g_DownTick = Get_XParam_INT( 1 );		--倒计时时间
		g_IsShowTick = Get_XParam_INT( 2 );
	
	elseif event == "ADJEST_UI_POS" then
		ZidianLottery_ResetPos();
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZidianLottery_ResetPos();	
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
end

--领取奖励
function ZidianLottery_GetPrizeClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetPrize" )
		Set_XSCRIPT_ScriptID( 506036 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

function ZidianLottery_ShowDownTick()
	
	ZidianLottery_Button:Enable();
	local strTime = "";
	if g_bIsDownTickStart == 0 then	--未开始
		strTime = "#{ZDZYH_151012_31}";
	elseif g_bIsDownTickStart == 1 then	--时间数字
		strTime = string.format( "%d:%02d", math.floor(g_DownTick/60), math.mod(g_DownTick, 60) )
	elseif g_bIsDownTickStart == 2 then	--倒计时结束
		if g_DownTick == 0 then	--可领奖
			strTime = "#{ZDZYH_151012_33}";
		else	--已过期
			strTime = "#{ZDZYH_151012_32}";
			ZidianLottery_Button:Disable();
		end
	elseif g_bIsDownTickStart == 3 then	--已领奖
		strTime = "#{ZDZYH_151012_34}";
		ZidianLottery_Button:Disable();
	end
	
	strText = ScriptGlobal_Format("#{ZDZYH_151012_9}", strTime )	
	ZidianLottery_Explain_Text:SetText( strText );
	
	if g_DownTick > 0 then
		g_DownTick = g_DownTick  - 1;
	end
		
end

function ZidianLottery_OnHiden()
	KillTimer("ZidianLottery_ShowDownTick()")
	g_TimerID = -1
	
	for i = 1 , 5 do
		g_ZidianLottery_ActionButton[i]:SetActionItem(-1)
	end
	DataPool:Lua_ClearZiDianZengYingHaoActionItem();
end

function ZidianLottery_ResetPos()
	ZidianLottery_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition);
end