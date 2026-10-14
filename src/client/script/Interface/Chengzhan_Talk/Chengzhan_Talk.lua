--!!!reloadscript =Chengzhan_Talk

local g_Chengzhan_Talk_Frame_UnifiedXPosition
local g_Chengzhan_Talk_Frame_UnifiedYPosition

local MAX_OBJ_DISTANCE = 5.0;
local objCared = -1;
local g_Object = -1;

local g_Chengzhan_Talk_targetId = 0
local g_Chengzhan_Talk_nPrize = 0
local g_Chengzhan_Talk_nChoice = 0

local g_Chengzhan_Talk_ItemId = 
{
	[1] = { [1] = 39925384, [2] = 39925385, [3] = 39925369, [4] = 39925383, [5] = 39925371, [6] = 39925382 },
	[2] = { [1] = 39925449, [2] = 39925451, [3] = 39925441, [4] = 39925447, [5] = 39925443, [6] = 39925445 },
	[3] = { [1] = 39925450, [2] = 39925452, [3] = 39925442, [4] = 39925448, [5] = 39925444, [6] = 39925446 },
}

local g_Chengzhan_Talk_Select = {};

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Chengzhan_Talk_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Chengzhan_Talk_OnLoad()
	-- 保存界面的默认相对位置
	g_Chengzhan_Talk_Frame_UnifiedXPosition	= Chengzhan_Talk_Frame:GetProperty("UnifiedXPosition");
	g_Chengzhan_Talk_Frame_UnifiedYPosition	= Chengzhan_Talk_Frame:GetProperty("UnifiedYPosition");

	g_Chengzhan_Talk_Select[1] = Chengzhan_Talk_List_Select1;
	g_Chengzhan_Talk_Select[2] = Chengzhan_Talk_List_Select2;
	g_Chengzhan_Talk_Select[3] = Chengzhan_Talk_List_Select3;
	g_Chengzhan_Talk_Select[4] = Chengzhan_Talk_List_Select4;
	g_Chengzhan_Talk_Select[5] = Chengzhan_Talk_List_Select5;
	g_Chengzhan_Talk_Select[6] = Chengzhan_Talk_List_Select6;
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Chengzhan_Talk_ResetPos()
	Chengzhan_Talk_Frame:SetProperty("UnifiedXPosition", g_Chengzhan_Talk_Frame_UnifiedXPosition);
	Chengzhan_Talk_Frame:SetProperty("UnifiedYPosition", g_Chengzhan_Talk_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Chengzhan_Talk_OnEvent(event)
	if event == "UI_COMMAND" and (tonumber(arg0) == 90001701) then

		g_Chengzhan_Talk_targetId = Get_XParam_INT(0);
		g_Chengzhan_Talk_nPrize = Get_XParam_INT(1);
		g_Chengzhan_Talk_nChoice = 0

		if (this:IsVisible()) then
			if g_Chengzhan_Talk_targetId == -1 and g_Chengzhan_Talk_nPrize == -1 then
				Chengzhan_Talk_Close_Clicked()
				return
			end
		end

		objCared = -1;
		objCared = DataPool : GetNPCIDByServerID(g_Chengzhan_Talk_targetId);
		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end
		Chengzhan_Talk_BeginCareObject(objCared)

		if g_Chengzhan_Talk_nPrize > 3 or g_Chengzhan_Talk_nPrize < 1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end

		--打开界面
		Chengzhan_Talk_Show()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Chengzhan_Talk_Close_Clicked()
		end	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Chengzhan_Talk_Close_Clicked()
	elseif event == "ADJEST_UI_POS" then
		Chengzhan_Talk_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Chengzhan_Talk_ResetPos()
	end
end

--显示UI
function Chengzhan_Talk_Show()

	for i=1,6 do
		g_Chengzhan_Talk_Select[i]:SetActionItem(-1)
		local theAction = DataPool:CreateBindActionItemForShow(g_Chengzhan_Talk_ItemId[g_Chengzhan_Talk_nPrize][i], 1)
		if theAction:GetID() ~= 0 then
			g_Chengzhan_Talk_Select[i]:SetActionItem(theAction:GetID())
		end
		g_Chengzhan_Talk_Select[i]:SetPushed(0);	
	end

	this:Show()

end

--隐藏UI
function Chengzhan_Talk_OnHide()
	this:Hide()
end

function Chengzhan_Talk_Close_Clicked()
	Chengzhan_Talk_StopCareObject()
	Chengzhan_Talk_OnHide()
end

function Chengzhan_Talk_Pre_Clicked()

	if(g_Chengzhan_Talk_nChoice < 1 or g_Chengzhan_Talk_nChoice > 6) then
		PushDebugMessage("#{ZTPVP_260515_146}")
		return;
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "CheckPrizeUI" ); 					-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 900017 );											-- 脚本编号  
		Set_XSCRIPT_Parameter( 0, g_Chengzhan_Talk_targetId );
		Set_XSCRIPT_Parameter( 1, g_Chengzhan_Talk_nChoice );			 
		Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
	Send_XSCRIPT()	
end

--=========================================================
--开始关心NPC
--=========================================================
function Chengzhan_Talk_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "Chengzhan_Talk");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "Chengzhan_Talk")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function Chengzhan_Talk_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "Chengzhan_Talk");
		g_Object = -1;
	end
end

--===============================================
-- 选中图标
--===============================================
function Chengzhan_Talk_List_Select(nIndex)
	-- 数据超过范围，返回
	if(nIndex < 1 or nIndex > 6) then
		return;
	end

	local i = 1;
	for i=1, 6 do
		if(i==nIndex) then
			g_Chengzhan_Talk_Select[i]:SetPushed(1);
		else
			g_Chengzhan_Talk_Select[i]:SetPushed(0);
		end
	end

	g_Chengzhan_Talk_nChoice = nIndex
end