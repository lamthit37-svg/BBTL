local g_Timers = 0
local g_Seconds = 1
local g_targetID = -1


local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function BS_Match_Ing_PreLoad()
    this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BS_Match_Ing_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BS_Match_Ing:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BS_Match_Ing:GetProperty("UnifiedYPosition");

end

function BS_Match_Ing_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		BS_Match_Ing_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BS_Match_Ing_ResetPos()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 20181217) then 
		if Get_XParam_INT(0) ~= nil then
			local nParam1 = Get_XParam_INT(0) 
			g_targetID = Get_XParam_INT(1) 
			BS_Match_Ing_FillListData(nParam1)
		end
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		--清理时间
		KillTimer("BS_Match_Ing_List_On_Trans()")
		this:Hide()
	end
end
function BS_Match_Ing_ClearItemList()
	
end

function BS_Match_Ing_FillListData(nTime)
	if nTime > 0 then
		this:Show()
		SetTimer("BS_Match_Ing","BS_Match_Ing_List_On_Trans()", nTime)
	else
		BS_Match_Ing_EnterLobby()
	end
end

function BS_Match_Ing_List_On_Trans()
	this:Hide()
	KillTimer("BS_Match_Ing_List_On_Trans()")
	BS_Match_Ing_EnterLobby()	
end

function BS_Match_Ing_CloseClicked()
    this:Hide()
end

function BS_Match_Ing_EnterLobby()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "EnterLobby" )
		Set_XSCRIPT_ScriptID(892847) --别忘了：AllowableScriptFunc.txt中加上这个接口和脚本号
		Set_XSCRIPT_Parameter(0, g_targetID)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BS_Match_Ing_ResetPos()
	BS_Match_Ing:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BS_Match_Ing:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BS_Match_Ing_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end
