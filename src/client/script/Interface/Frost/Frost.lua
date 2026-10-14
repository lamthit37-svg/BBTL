local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_Frost_Button ={}
local g_Frost_lowcount = 0;
local g_Frost_highcount = 0;
local g_Frost_sceneIndex = 0;
local g_Frost_ImageTbl = {
	"set:Frost0 image:Frost_2",
	"set:Frost1 image:Frost_3",
	"set:Frost1 image:Frost_4",
	"set:Frost2 image:Frost_5",
	"set:Frost2 image:Frost_6",
	"set:Frost3 image:Frost_7",
	"set:Frost3 image:Frost_8",
	"set:Frost4 image:Frost_9",
	}
function Frost_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Frost_OnEvent(event)
	if event == "UI_COMMAND"  and tonumber(arg0) == 891415 then
		g_Frost_sceneIndex = Get_XParam_INT(0)
		g_Frost_lowcount = Get_XParam_INT(1)
		g_Frost_highcount = Get_XParam_INT(2)
		Frost_OnShown()
	elseif( event == "ADJEST_UI_POS" ) then
		Frost_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frost_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function Frost_OnLoad()

		-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Frost_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Frost_Frame:GetProperty("UnifiedYPosition");
		
end

function Frost_OnShown()
	Frost_Image:SetProperty("Image",g_Frost_ImageTbl[g_Frost_sceneIndex])
	Frost_TimesText1:SetText(ScriptGlobal_Format("#{QFGS_180807_46}",g_Frost_lowcount))
	Frost_TimesText2:SetText(ScriptGlobal_Format("#{QFGS_180807_47}",g_Frost_highcount))
	this:Show();
end

function Frost_MouseEnter(nIndex)
	if nIndex== 2 then
		--local strTemp = ScriptGlobal_Format("#{QFGS_180807_20}",g_Frost_lowcount)
		if KaJi:LuaFnGetKaJiType(97) == 1 then
			FrostButton2:SetToolTip("#{QFGS_220725_03}")
		else
			FrostButton2:SetToolTip("#{QFGS_180807_20}")
		end
		
	elseif nIndex == 3 then
		--local strTemp = ScriptGlobal_Format("#{QFGS_180807_33}",g_Frost_highcount)
		if KaJi:LuaFnGetKaJiType(97) == 1 then
			FrostButton3:SetToolTip("#{QFGS_220725_04}")
		else
			FrostButton3:SetToolTip("#{QFGS_180807_33}")
		end
		
	else
		return
	end
end

function Frost_MouseLeave()

end

function Frost_ButtonClick(nIndex)
	if nIndex >= 1 and nIndex <=3  then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetAward" )
		Set_XSCRIPT_ScriptID( 891415 )
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		return
	end
end
--================================================
-- 界面的默认相对位置
--================================================
function Frost_ResetPos()
	Frost_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Frost_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end