
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_JinZhiZhuYu_Button = {}
local g_JinZhiZhuYu_ButtonBK = {}
local g_JinZhiZhuYu_Human = {}
local g_JinZhiZhuYu_HumanAnimate = {}


local g_JinZhiZhuYu_Min = 0
local g_JinZhiZhuYu_Max = 8

local g_JinZhiZhuYu_Count = 0
local g_JinZhiZhuYu_Play = 0

local g_JinZhiZhuYu_Text = 0
local g_JinZhiZhuYu_ShowTips = 0

local g_JinZhiZhuYu_Obj = 0
local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

function JinZhiZhuYu_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function JinZhiZhuYu_OnLoad()

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= JinZhiZhuYu_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= JinZhiZhuYu_Frame:GetProperty("UnifiedYPosition");
	
	JinZhiZhuYu_Init()
	
end

function JinZhiZhuYu_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		JinZhiZhuYu_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		JinZhiZhuYu_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this : Hide()
	elseif ( event == "UI_COMMAND") and (tonumber(arg0) == 88820902)  then
		g_JinZhiZhuYu_Count = Get_XParam_INT( 0 );
		g_JinZhiZhuYu_Play = Get_XParam_INT( 1 );
		g_JinZhiZhuYu_Obj = Get_XParam_INT( 2 );
		g_JinZhiZhuYu_Text = Get_XParam_INT( 3 );
		g_JinZhiZhuYu_ShowTips = Get_XParam_INT( 4 );
		
		if g_JinZhiZhuYu_Obj ~= 0 then
			--关注NPC
			objCared = Target:GetServerId2ClientId( tonumber( g_JinZhiZhuYu_Obj ));
		end
		
		if(IsWindowShow("JinZhiZhuYu")) then
			CloseWindow("JinZhiZhuYu", true);
			return
		end
		
		JinZhiZhuYu_FreshDate()
		
		if g_JinZhiZhuYu_ShowTips == 1 then
			if g_JinZhiZhuYu_Count < 10 then
				PushDebugMessage( ScriptGlobal_Format("#{ZYPX_200829_05}", g_JinZhiZhuYu_Count) )
			else
				PushDebugMessage( "#{ZYPX_200829_06}" )
			end
		end

		this : Show();
		
		this:CareObject(objCared, 1, "JinZhiZhuYu");
		
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();

			--取消关心
			this:CareObject(objCared, 0, "JinZhiZhuYu");
		end
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function JinZhiZhuYu_ResetPos()
	JinZhiZhuYu_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	JinZhiZhuYu_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 初始化数据
--================================================
function JinZhiZhuYu_Init()

	g_JinZhiZhuYu_Button = {
		JinZhiZhuYu_ActionButtonBK1, JinZhiZhuYu_ActionButtonBK2,
		JinZhiZhuYu_ActionButtonBK3, JinZhiZhuYu_ActionButtonBK4,
		JinZhiZhuYu_ActionButtonBK5, JinZhiZhuYu_ActionButtonBK6,
		JinZhiZhuYu_ActionButtonBK7, JinZhiZhuYu_ActionButtonBK8,
	}
	
	g_JinZhiZhuYu_ButtonBK = {
		JinZhiZhuYu_ActionButton1_BK, JinZhiZhuYu_ActionButton2_BK,
		JinZhiZhuYu_ActionButton3_BK, JinZhiZhuYu_ActionButton4_BK,
		JinZhiZhuYu_ActionButton5_BK, JinZhiZhuYu_ActionButton6_BK,
		JinZhiZhuYu_ActionButton7_BK, JinZhiZhuYu_ActionButton8_BK,
	}
			
	g_JinZhiZhuYu_Human = {
		JinZhiZhuYu_Human1, JinZhiZhuYu_Human2, JinZhiZhuYu_Human3,
		JinZhiZhuYu_Human4, JinZhiZhuYu_Human5, JinZhiZhuYu_Human6,
		JinZhiZhuYu_Human7, JinZhiZhuYu_Human8, JinZhiZhuYu_Human9,
	}
	
	g_JinZhiZhuYu_HumanAnimate = { 
		JinZhiZhuYu_ActionButton1, JinZhiZhuYu_ActionButton2, JinZhiZhuYu_ActionButton3, 
		JinZhiZhuYu_ActionButton4, JinZhiZhuYu_ActionButton5, JinZhiZhuYu_ActionButton6, 
		JinZhiZhuYu_ActionButton7, JinZhiZhuYu_ActionButton8, JinZhiZhuYu_ActionButton9,
	}

end

--================================================
-- 刷新物品数量
--================================================
function JinZhiZhuYu_FreshDate()

	for i = g_JinZhiZhuYu_Min + 1, g_JinZhiZhuYu_Max do
		-- 灰底显示
		g_JinZhiZhuYu_ButtonBK[i]:Show()
		-- 亮底隐藏
		g_JinZhiZhuYu_Button[i]:Hide()
	end	
	
	if g_JinZhiZhuYu_Count < g_JinZhiZhuYu_Min then
		g_JinZhiZhuYu_Count = g_JinZhiZhuYu_Min		
	end
	
	if g_JinZhiZhuYu_Count > g_JinZhiZhuYu_Max then
		g_JinZhiZhuYu_Count = g_JinZhiZhuYu_Max
	end
	
	for i = g_JinZhiZhuYu_Min, g_JinZhiZhuYu_Max do
		if i == g_JinZhiZhuYu_Count then
			g_JinZhiZhuYu_Human[i+1]:Hide()
			g_JinZhiZhuYu_HumanAnimate[i+1]:Play(true)
		else
			g_JinZhiZhuYu_Human[i+1]:Hide()
			g_JinZhiZhuYu_HumanAnimate[i+1]:Play(false)
		end
	end
			
	for i = g_JinZhiZhuYu_Min + 1, g_JinZhiZhuYu_Max do
		if i <= g_JinZhiZhuYu_Count then
			g_JinZhiZhuYu_Button[i]:Show()
		end
		--if i == g_JinZhiZhuYu_Count then
		--	if g_JinZhiZhuYu_Play == 1 then
		--		SetTimer("JinZhiZhuYu", "JinZhiZhuYu_TickClose()", 6000)
		--		g_JinZhiZhuYu_Human[i+1]:Hide()
		--		g_JinZhiZhuYu_HumanAnimate[i+1]:Play(true)
		--	else
		--		g_JinZhiZhuYu_HumanAnimate[i+1]:Play(false)
		--	end
		--else
		--	g_JinZhiZhuYu_HumanAnimate[i+1]:Play(false)
		--end
	end	
	
	JinZhiZhuYu_Frame_info:Show()
	if g_JinZhiZhuYu_Text == 1 then
		JinZhiZhuYu_Frame_info:SetText(ScriptGlobal_Format("#{ZYPX_200829_07}", g_JinZhiZhuYu_Count))
	else
		JinZhiZhuYu_Frame_info:Hide()
	end
end

--================================================
-- 点击事件
--================================================
function JinZhiZhuYu_clicked(index)
	
end

function JinZhiZhuYu_TickClose()

	if g_JinZhiZhuYu_Count > g_JinZhiZhuYu_Min and g_JinZhiZhuYu_Count <= g_JinZhiZhuYu_Max then
		g_JinZhiZhuYu_HumanAnimate[g_JinZhiZhuYu_Count + 1]:Play(false)
		g_JinZhiZhuYu_Human[g_JinZhiZhuYu_Count+1]:Show()
	end
	KillTimer("JinZhiZhuYu_TickClose()")
	
end

--================================================
-- 关闭界面事件
--================================================
function JinZhiZhuYu_Close()

	JinZhiZhuYu_TickClose()

	this:CareObject(objCared, 0, "JinZhiZhuYu");
	
end

function JinZhiZhuYu_CancleEvent()
	KillTimer("JinZhiZhuYu_TickClose()")	
	this:Hide();
	this:CareObject(objCared, 0, "JinZhiZhuYu");
end

