local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_DaKa_HanMei_Button = {}
local g_DaKa_HanMei_ButtonBK = {}
local g_DaKa_HanMei_Image = {}
local g_DaKa_HanMei_HuiImage = {}

local g_DaKa_HanMei_Min = 0
local g_DaKa_HanMei_Max = 10

local g_DaKa_HanMei_Count = 0
local g_DaKa_HanMei_Play = 0

local g_DaKa_HanMei_Text = 0
local g_DaKa_HanMei_ShowTips = 0

local g_DaKa_HanMei_Obj = 0
local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

function DaKa_HanMei_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function DaKa_HanMei_OnLoad()

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= DaKa_HanMei_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= DaKa_HanMei_Frame:GetProperty("UnifiedYPosition");

end

function DaKa_HanMei_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		DaKa_HanMei_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		DaKa_HanMei_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this : Hide()
	elseif ( event == "UI_COMMAND") and (tonumber(arg0) == 89265301)  then
		g_DaKa_HanMei_Count = Get_XParam_INT( 0 );
		g_DaKa_HanMei_Play = Get_XParam_INT( 1 );
		g_DaKa_HanMei_Obj = Get_XParam_INT( 2 );
		g_DaKa_HanMei_Text = Get_XParam_INT( 3 );
		g_DaKa_HanMei_ShowTips = Get_XParam_INT( 4 );
		
		if g_DaKa_HanMei_Obj ~= 0 then
			--关注NPC
			objCared = Target:GetServerId2ClientId( tonumber( g_DaKa_HanMei_Obj ));
		end
		
		if(IsWindowShow("DaKa_HanMei")) then
			CloseWindow("DaKa_HanMei", true);
			return
		end
		
		DaKa_HanMei_Init();
		DaKa_HanMei_FreshDate()
		
		if g_DaKa_HanMei_ShowTips == 1 then
			if g_DaKa_HanMei_Count < 10 then
				PushDebugMessage( ScriptGlobal_Format("#{HMLZ_171214_203}", g_DaKa_HanMei_Count) )
			else
				PushDebugMessage( "#{HMLZ_171214_204}" )
			end
		end

		this : Show();
		
		this:CareObject(objCared, 1, "DaKa_HanMei");
		
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();

			--取消关心
			this:CareObject(objCared, 0, "DaKa_HanMei");
		end
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DaKa_HanMei_ResetPos()
	DaKa_HanMei_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	DaKa_HanMei_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 初始化数据
--================================================
function DaKa_HanMei_Init()

	g_DaKa_HanMei_Button[1] = DaKa_HanMei_ActionButton1
	g_DaKa_HanMei_ButtonBK[1] = DaKa_HanMei_ActionButtonBK1
	g_DaKa_HanMei_HuiImage[1] = "set:DaKa_HanMei02 image:3_01"
	g_DaKa_HanMei_Image[1] = "set:DaKa_HanMei02 image:3_07"
	
	g_DaKa_HanMei_Button[2] = DaKa_HanMei_ActionButton2
	g_DaKa_HanMei_ButtonBK[2] = DaKa_HanMei_ActionButtonBK2
	g_DaKa_HanMei_HuiImage[2] = "set:DaKa_HanMei02 image:2_01"
	g_DaKa_HanMei_Image[2] = "set:DaKa_HanMei02 image:2_07"
	
	g_DaKa_HanMei_Button[3] = DaKa_HanMei_ActionButton3
	g_DaKa_HanMei_ButtonBK[3] = DaKa_HanMei_ActionButtonBK3
	g_DaKa_HanMei_HuiImage[3] = "set:DaKa_HanMei02 image:3_01"
	g_DaKa_HanMei_Image[3] = "set:DaKa_HanMei02 image:3_07"
	
	--g_DaKa_HanMei_Button[4] = DaKa_HanMei_ActionButton4
	--g_DaKa_HanMei_ButtonBK[4] = DaKa_HanMei_ActionButtonBK4
	--g_DaKa_HanMei_HuiImage[4] = "set:DaKa_HanMei02 image:2_01"
	--g_DaKa_HanMei_Image[4] = "set:DaKa_HanMei02 image:2_07"
	
	g_DaKa_HanMei_Button[4] = DaKa_HanMei_ActionButton5
	g_DaKa_HanMei_ButtonBK[4] = DaKa_HanMei_ActionButtonBK5
	g_DaKa_HanMei_HuiImage[4] = "set:DaKa_HanMei02 image:3_01"
	g_DaKa_HanMei_Image[4] = "set:DaKa_HanMei02 image:3_07"
	
	--g_DaKa_HanMei_Button[6] = DaKa_HanMei_ActionButton6
	--g_DaKa_HanMei_ButtonBK[6] = DaKa_HanMei_ActionButtonBK6
	--g_DaKa_HanMei_HuiImage[6] = "set:DaKa_HanMei02 image:2_01"
	--g_DaKa_HanMei_Image[6] = "set:DaKa_HanMei02 image:2_07"
	
	g_DaKa_HanMei_Button[5] = DaKa_HanMei_ActionButton7
	g_DaKa_HanMei_ButtonBK[5] = DaKa_HanMei_ActionButtonBK7
	g_DaKa_HanMei_HuiImage[5] = "set:DaKa_HanMei02 image:3_01"
	g_DaKa_HanMei_Image[5] = "set:DaKa_HanMei02 image:3_07"
	
	g_DaKa_HanMei_Button[6] = DaKa_HanMei_ActionButton8
	g_DaKa_HanMei_ButtonBK[6] = DaKa_HanMei_ActionButtonBK8
	g_DaKa_HanMei_HuiImage[6] = "set:DaKa_HanMei02 image:2_01"
	g_DaKa_HanMei_Image[6] = "set:DaKa_HanMei02 image:2_07"
	
	g_DaKa_HanMei_Button[7] = DaKa_HanMei_ActionButton9
	g_DaKa_HanMei_ButtonBK[7] = DaKa_HanMei_ActionButtonBK9
	g_DaKa_HanMei_HuiImage[7] = "set:DaKa_HanMei02 image:2_01"
	g_DaKa_HanMei_Image[7] = "set:DaKa_HanMei02 image:2_07"
	
	--g_DaKa_HanMei_Button[10] = DaKa_HanMei_ActionButton10
	--g_DaKa_HanMei_ButtonBK[10] = DaKa_HanMei_ActionButtonBK10
	--g_DaKa_HanMei_HuiImage[10] = "set:DaKa_HanMei02 image:2_01"
	--g_DaKa_HanMei_Image[10] = "set:DaKa_HanMei02 image:2_07"
	
	g_DaKa_HanMei_Button[8] = DaKa_HanMei_ActionButton11
	g_DaKa_HanMei_ButtonBK[8] = DaKa_HanMei_ActionButtonBK11
	g_DaKa_HanMei_HuiImage[8] = "set:DaKa_HanMei02 image:2_01"
	g_DaKa_HanMei_Image[8] = "set:DaKa_HanMei02 image:2_07"
	
	g_DaKa_HanMei_Button[9] = DaKa_HanMei_ActionButton12
	g_DaKa_HanMei_ButtonBK[9] = DaKa_HanMei_ActionButtonBK12
	g_DaKa_HanMei_HuiImage[9] = "set:DaKa_HanMei02 image:2_01"
	g_DaKa_HanMei_Image[9] = "set:DaKa_HanMei02 image:2_07"
	
	--g_DaKa_HanMei_Button[13] = DaKa_HanMei_ActionButton13
	--g_DaKa_HanMei_ButtonBK[13] = DaKa_HanMei_ActionButtonBK13
	--g_DaKa_HanMei_HuiImage[13] = "set:DaKa_HanMei02 image:2_01"
	--g_DaKa_HanMei_Image[13] = "set:DaKa_HanMei02 image:2_07"
	
	g_DaKa_HanMei_Button[10] = DaKa_HanMei_ActionButton14
	g_DaKa_HanMei_ButtonBK[10] = DaKa_HanMei_ActionButtonBK14
	g_DaKa_HanMei_HuiImage[10] = "set:DaKa_HanMei02 image:2_01"
	g_DaKa_HanMei_Image[10] = "set:DaKa_HanMei02 image:2_07"

end

--================================================
-- 刷新物品数量
--================================================
function DaKa_HanMei_FreshDate()

	for i = g_DaKa_HanMei_Min + 1, g_DaKa_HanMei_Max do
		g_DaKa_HanMei_ButtonBK[i]:SetProperty("Image", g_DaKa_HanMei_HuiImage[i])
	end	
	
	if g_DaKa_HanMei_Count < g_DaKa_HanMei_Min then
		g_DaKa_HanMei_Count = g_DaKa_HanMei_Min		
	end
	
	if g_DaKa_HanMei_Count > g_DaKa_HanMei_Max then
		g_DaKa_HanMei_Count = g_DaKa_HanMei_Max
	end
			
	DaKa_HanMei_Frame_info:Show()
	for i = g_DaKa_HanMei_Min + 1, g_DaKa_HanMei_Max do
		if i < g_DaKa_HanMei_Count then
			--g_DaKa_HanMei_ButtonBK[i]:Show()
			g_DaKa_HanMei_ButtonBK[i]:SetProperty("Image", g_DaKa_HanMei_Image[i])
		end
		if i == g_DaKa_HanMei_Count then
			if g_DaKa_HanMei_Play == 1 then
				SetTimer("DaKa_HanMei", "DaKa_HanMei_Close()", 6000)
				g_DaKa_HanMei_Button[i]:Play(true)
			else
				g_DaKa_HanMei_ButtonBK[i]:SetProperty("Image", g_DaKa_HanMei_Image[i])
				g_DaKa_HanMei_Button[i]:Play(false)
			end
		else
			g_DaKa_HanMei_Button[i]:Play(false)
		end
	end	
	if g_DaKa_HanMei_Text == 1 then
		DaKa_HanMei_Frame_info:SetText(ScriptGlobal_Format("#{HMLZ_171214_202}",g_DaKa_HanMei_Count))
	else
		DaKa_HanMei_Frame_info:Hide()
	end
end

--================================================
-- 点击事件
--================================================
function DaKa_HanMei_clicked(index)
	
end

--================================================
-- 关闭界面事件
--================================================
function DaKa_HanMei_Close()
	if g_DaKa_HanMei_Count > g_DaKa_HanMei_Min and g_DaKa_HanMei_Count <= g_DaKa_HanMei_Max then
		g_DaKa_HanMei_Button[g_DaKa_HanMei_Count]:Play(false)
		g_DaKa_HanMei_ButtonBK[g_DaKa_HanMei_Count]:SetProperty("Image", g_DaKa_HanMei_Image[g_DaKa_HanMei_Count])
	end
	KillTimer("DaKa_HanMei_Close()")

	this:CareObject(objCared, 0, "DaKa_HanMei");
end

function DaKa_HanMei_CancleEvent()
	KillTimer("DaKa_HanMei_Close()")
	this:Hide();

	this:CareObject(objCared, 0, "DaKa_HanMei");
end

