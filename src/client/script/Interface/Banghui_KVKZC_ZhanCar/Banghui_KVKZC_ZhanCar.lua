
local g_Banghui_KVKZC_UnifiedXPosition;
local g_Banghui_KVKZC_UnifiedYPosition;

local g_Index = nil

local lastselete = nil

-- local locatname = {}
function Banghui_KVKZC_ZhanCar_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("SCENE_TRANSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Banghui_KVKZC_ZhanCar_OnLoad()
	g_Banghui_KVKZC_UnifiedXPosition = Banghui_KVKZC_ZhanCar_Frame : GetProperty("UnifiedXPosition");
	g_Banghui_KVKZC_UnifiedYPosition = Banghui_KVKZC_ZhanCar_Frame : GetProperty("UnifiedYPosition");
	
	g_Index = { 4,5,3,2,1};
	lastselete = -1;
	
	-- locatname = { "#{KFZC_141013_116}", "#{KFZC_141013_117}","#{KFZC_141013_118}",
							-- "#{KFZC_141013_119}", "#{KFZC_141013_120}",
							-- }
end

function Banghui_KVKZC_ZhanCar_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 20141114) then
		local dataid  = Get_XParam_INT(0)
		local name = TServerUI:GetMonsterNamebyDataID(dataid)
		local str =  ScriptGlobal_Format("#{KFZC_141013_93}", name)
		
		Banghui_KVKZC_ZhanCar_Frame1_DragTitle:SetText(str)
		this:Show()
	elseif(event == "SCENE_TRANSED") then
		if IsInTServer() ~= 1 then
			Banghui_KVKZC_ZhanCar_OnHide()
			this:Hide()
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 201409011 ) then
		Banghui_KVKZC_ZhanCar_OnHide()
		this:Hide()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20141118) then
		Banghui_KVKZC_ZhanCar_OnHide()
		this:Hide()
	elseif (event == "ADJEST_UI_POS") then
		Banghui_KVKZC_ZhanCar_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Banghui_KVKZC_ZhanCar_ResetPos()
	end
end

function Banghui_KVKZC_ZhanCar_OnHide()
	lastselete = -1
end

function Banghui_KVKZC_ZhanCar_GoTo(index)

	-- if index == lastselete then
		-- local str = ScriptGlobal_Format("#{KFZC_141013_115}", locatname[index])
		-- PushDebugMessage(str);
		-- return
	-- end
	
	-- local str = ScriptGlobal_Format("#{KFZC_141013_115}", locatname[index])
	-- PushDebugMessage("缚龙战车正在前往"..locatname[tonumber(index)].."处！");
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ZhanCarGO");
		Set_XSCRIPT_ScriptID(506025);
		Set_XSCRIPT_Parameter(0,g_Index[index]);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	
	-- lastselete = index
end

function Banghui_KVKZC_ZhanCar_ResetPos()
	Banghui_KVKZC_ZhanCar_Frame : SetProperty("UnifiedXPosition", g_Banghui_KVKZC_UnifiedXPosition);
	Banghui_KVKZC_ZhanCar_Frame : SetProperty("UnifiedYPosition", g_Banghui_KVKZC_UnifiedYPosition);
end