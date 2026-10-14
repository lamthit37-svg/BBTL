
local g_WuLin_TL_decade = {}
function WuLin_TL_PreLoad()
	this:RegisterEvent("REFRESH_SONGLIAOWAR_SINGLE_SCORE");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("SONGLIAOSINGLE_MINI");
	this:RegisterEvent("UI_COMMAND");
end
local nOpen = 0
local nScene = -1
local nselfId = -1
local nshengyu = -1
function WuLin_TL_OnLoad()
	nOpen = 0
	nScene = -1
	nselfId = -1
	nshengyu = -1

	for i = 0,9 do 
		local image = "set:GuanShanHai03 image:QianJi"..i
		table.insert(g_WuLin_TL_decade,i,image)
	end
end

function WuLin_TL_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		WuLin_TL_ImageNumber:SetProperty("Image",g_WuLin_TL_decade[0])
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20200317 then
		nOpen = Get_XParam_INT(0)	
		nScene = Get_XParam_INT(1)			
		nselfId = Get_XParam_INT(2)			
		nshengyu = Get_XParam_INT(3)	
		
		if nshengyu <= 0 then
			WuLin_TL_Btn1:SetProperty("Disabled", "True");
			WuLin_TL_Btn2:SetProperty("Disabled", "True");
		else
			WuLin_TL_Btn1:SetProperty("Disabled", "False");			
			WuLin_TL_Btn2:SetProperty("Disabled", "False");
		end

		WuLin_TL_ImageNumber:SetProperty("Image",g_WuLin_TL_decade[nshengyu])

		if nOpen ==  1 then
			this:Show()
		else
			this:Hide()
		end
	end
end
function WuLin_TL_Click(click)
	if 0 == click  then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RefixHpMp" )
		Set_XSCRIPT_ScriptID(888011) --别忘了：AllowableScriptFunc.txt中加上这个接口和脚本号
		Set_XSCRIPT_Parameter(0,0) 	
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif 1 == click  then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "RefixHpMp" )
			Set_XSCRIPT_ScriptID(888011) --别忘了：AllowableScriptFunc.txt中加上这个接口和脚本号
			Set_XSCRIPT_Parameter(0,1) 			
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end
