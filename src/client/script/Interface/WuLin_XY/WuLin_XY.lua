
local g_Timers = 0
function WuLin_XY_PreLoad()
	this:RegisterEvent("REFRESH_SONGLIAOWAR_SINGLE_SCORE");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("SONGLIAOSINGLE_MINI");
	this:RegisterEvent("UI_COMMAND");
end
local nOpen = 0
local nScene = -1
local nselfId = -1
local nnum = 0
local g_WuLin_XY_decade = {}
function WuLin_XY_OnLoad()
	nOpen = 0
	nScene = -1
	nselfId = -1
	nnum = 0
	for i = 0,9 do 
		local image = "set:GuanShanHai03 image:QianJi"..i
		table.insert(g_WuLin_XY_decade,i,image)
	end
end

function WuLin_XY_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20200320 then
		nOpen = Get_XParam_INT(0)	
		nScene = Get_XParam_INT(1)			
		nselfId = Get_XParam_INT(2)			
		nnum = Get_XParam_INT(3)			

		if nnum == 0 then
			WuLin_XY_BtnNumber:SetProperty("Image",g_WuLin_XY_decade[0])
			WuLin_XY_Btn:SetProperty("Disabled", "True");

		else
			WuLin_XY_BtnNumber:SetProperty("Image",g_WuLin_XY_decade[nnum])
			WuLin_XY_Btn:SetProperty("Disabled", "False");
		end
		if nOpen ==  1 then
			this:Show()
		else
			this:Hide()
		end
	end
end
function WuLin_XY_Click()

		--CD时间
		if not WuLin_XY_PassTime(1) then
			PushDebugMessage("#{BSJN_200327_187}");
			return
		end

		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "CreateBaiZiMonster" )
		Set_XSCRIPT_ScriptID(888013) --别忘了：AllowableScriptFunc.txt中加上这个接口和脚本号
		Set_XSCRIPT_Parameter(0,nselfId) 	
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

end

function WuLin_XY_PassTime(iSeconds)
	local iCur = FindFriendDataPool:GetTickCount()
	if ( iCur - g_Timers < iSeconds * 1000) then
	   return false;
	else
	   g_Timers = iCur;
		  return true;
	end
 end