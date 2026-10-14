local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_DaKa_HuiTu_Button = {}
local g_DaKa_HuiTu_Bk = {}
local g_DaKa_HuiTu_flag = {}
local g_DaKa_HuiTu_OK = 1

local g_DaKa_HuiTu_tagobj = 0

local g_DaKa_HuiTu_time = 0

local g_DaKa_HuiTu_Min = 1
local g_DaKa_HuiTu_Max = 5

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

local g_DaKa_HuiTu_TimeClick = 0;	--上次点击时间

function DaKa_HuiTu_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("OBJECT_CARED_EVENT",false);

end

function DaKa_HuiTu_OnLoad()

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= DaKa_HuiTu_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= DaKa_HuiTu_Frame:GetProperty("UnifiedYPosition");

end

function DaKa_HuiTu_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		DaKa_HuiTu_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		DaKa_HuiTu_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this : Hide()
	elseif ( event == "UI_COMMAND") and (tonumber(arg0) == 89265303)  then
		g_DaKa_HuiTu_tagobj = Get_XParam_INT( 0 );
		
		if Get_XParam_INT( 1 ) ~= nil and Get_XParam_INT( 1 ) == 0 then
			DaKa_HuiTu_Close()
			return;
		end
		
		if Get_XParam_INT( 2 ) ~= nil and Get_XParam_INT( 2 ) ~= 0 then
			KillTimer("DaKa_HuiTu_OnTimer()")
			g_DaKa_HuiTu_time = Get_XParam_INT( 2 );
			DaKa_HuiTu_text:SetText(ScriptGlobal_Format("#{HMLZ_171214_216}",g_DaKa_HuiTu_time))
			SetTimer("DaKa_HuiTu","DaKa_HuiTu_OnTimer()", 1000)
		else
			DaKa_HuiTu_text:SetText("")
		end
		
		DaKa_HuiTu_Init();
		DaKa_HuiTu_FreshDate()
		
		if g_DaKa_HuiTu_tagobj ~= 0 then
			--关注NPC
			objCared = Target:GetServerId2ClientId( tonumber( g_DaKa_HuiTu_tagobj ));
		end

		this : Show();
		
		this:CareObject(objCared, 1, "DaKa_HuiTu");
		
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();

			--取消关心
			this:CareObject(objCared, 0, "DaKa_HuiTu");
		end
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DaKa_HuiTu_ResetPos()
	DaKa_HuiTu_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	DaKa_HuiTu_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 初始化数据
--================================================
function DaKa_HuiTu_Init()

	g_DaKa_HuiTu_Button[1] = DaKa_HuiTu_Button1
	g_DaKa_HuiTu_Button[2] = DaKa_HuiTu_Button2
	g_DaKa_HuiTu_Button[3] = DaKa_HuiTu_Button3
	g_DaKa_HuiTu_Button[4] = DaKa_HuiTu_Button4
	g_DaKa_HuiTu_Button[5] = DaKa_HuiTu_Button5
	
	g_DaKa_HuiTu_Bk[1] = DaKa_HuiTu_Bk1
	g_DaKa_HuiTu_Bk[2] = DaKa_HuiTu_Bk2
	g_DaKa_HuiTu_Bk[3] = DaKa_HuiTu_Bk3
	g_DaKa_HuiTu_Bk[4] = DaKa_HuiTu_Bk4
	g_DaKa_HuiTu_Bk[5] = DaKa_HuiTu_Bk5

	g_DaKa_HuiTu_flag[1] = 0
	g_DaKa_HuiTu_flag[2] = 0
	g_DaKa_HuiTu_flag[3] = 0
	g_DaKa_HuiTu_flag[4] = 0
	g_DaKa_HuiTu_flag[5] = 0
	
	for i = g_DaKa_HuiTu_Min, g_DaKa_HuiTu_Max do
		g_DaKa_HuiTu_Bk[i]:Hide()
		g_DaKa_HuiTu_Button[i]:Enable()
	end
end

--================================================
-- 刷新物品数量
--================================================
function DaKa_HuiTu_FreshDate()

	for i = g_DaKa_HuiTu_Min , g_DaKa_HuiTu_Max do
		if g_DaKa_HuiTu_flag[i] == 1 then
			g_DaKa_HuiTu_OK = 0
		end		
	end
	
end

--================================================
-- 点击事件
--================================================
function DaKa_HuiTu_clicked(index)
	if index < g_DaKa_HuiTu_Min or index > g_DaKa_HuiTu_Max then
		return
	end
	
	--检查CD 
	--if not DaKa_HuiTu_PassTime() then 
		--PushDebugMessage("#{ZYPT_081127_2}")  --"不可连续点击，请稍等片刻后再点击。";
	--	return
	--end 
	
	g_DaKa_HuiTu_flag[index] = 1
	g_DaKa_HuiTu_Bk[index]:Show()
	g_DaKa_HuiTu_Button[index]:Disable()
	
	DaKa_HuiTu_FreshDate()
	
	g_DaKa_HuiTu_OK = 1
	
	local nCount = 0
	for i = g_DaKa_HuiTu_Min , g_DaKa_HuiTu_Max do
		if g_DaKa_HuiTu_flag[i] ~= 1 then
			g_DaKa_HuiTu_OK = 0
		else
			nCount = nCount + 1
		end		
	end
	
	if g_DaKa_HuiTu_Max - nCount > 0 then
		PushDebugMessage(ScriptGlobal_Format( "#{HMLZ_171214_172}",g_DaKa_HuiTu_Max - nCount))
	end
	
	if g_DaKa_HuiTu_OK == 1 then
		-- 完成了 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ReFreshHanMeiData" )
			Set_XSCRIPT_ScriptID(892653)
			Set_XSCRIPT_Parameter(0,g_DaKa_HuiTu_tagobj)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		
	end
end

function DaKa_HuiTu_PassTime()
   local iCur = OSAPI:GetTickCount()
   if( iCur - g_DaKa_HuiTu_TimeClick) < 1000 then
       return false;
   else
       g_DaKa_HuiTu_TimeClick = iCur;
       return true;
   end
end

function DaKa_HuiTu_OnTimer()
	if g_DaKa_HuiTu_time <= 0 then
		DaKa_HuiTu_Close()
	end
	g_DaKa_HuiTu_time = g_DaKa_HuiTu_time - 1
	DaKa_HuiTu_text:SetText(ScriptGlobal_Format("#{HMLZ_171214_216}",g_DaKa_HuiTu_time))
end
--================================================
-- 关闭界面事件
--================================================
function DaKa_HuiTu_Close()
	this:Hide();

	this:CareObject(objCared, 0, "DaKa_HuiTu");
	KillTimer("DaKa_HuiTu_OnTimer()")
end

function DaKa_HuiTu_CancleEvent()
	this:Hide();

	this:CareObject(objCared, 0, "DaKa_HuiTu");
	KillTimer("DaKa_HuiTu_OnTimer()")
end
