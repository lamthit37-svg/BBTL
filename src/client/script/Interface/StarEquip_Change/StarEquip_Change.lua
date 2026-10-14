-- 全民8星 打造属性界面
-- !!!reloadscript =StarEquip_Change

local g_StarEquip_Change_Idx = -1

local g_StarEquip_Change_Frame_UnifiedPosition = nil

function StarEquip_Change_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("QM8X_OPEN_CHANGE");
	this:RegisterEvent("QM8X_UPDATA_MAINUI");
	
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	
end

function StarEquip_Change_OnLoad()

	g_StarEquip_Change_Frame_UnifiedPosition = StarEquip_Change_Frame:GetProperty("UnifiedPosition");

end

function StarEquip_Change_OnEvent(event)

	if (event == "QM8X_OPEN_CHANGE") then
	
		g_StarEquip_Change_Idx = tonumber(arg0) + 1
		if g_StarEquip_Change_Idx < 1 or g_StarEquip_Change_Idx > 4 then
			StarEquip_Change_DoClose()
			return
		end

		StarEquip_Change_Clear()
		
		StarEquip_Change_Show()
		
		StarEquip_Change_Frame:SetForce()
		
		this:Show()
		
	elseif (event == "QM8X_UPDATA_MAINUI") then
	
		if this:IsVisible() then
			StarEquip_Change_DoClose()
			return
		end
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		StarEquip_Change_DoClose()
			
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS") then
		StarEquip_Change_ResetPos()
		
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		StarEquip_Change_ResetPos()
	end
	
end

function StarEquip_Change_Show()

	local nYear, nMonth, nDay = Player:LuaFnGetQM8XActEndTime()
	local str = ScriptGlobal_Format("#{XFXB_230823_64}", nYear, nMonth, nDay)
	StarEquip_Change_Info:SetText(str)
						
	local theAction = EnumAction(g_StarEquip_Change_Idx-1, "quanmin8xing");
	if theAction:GetID() ~= 0 then						
		local num = theAction:GetEquipAttrCount()
		local str = ""
		for i = 0, num-1 do
			local tempstr = theAction:EnumEquipExtAttr(i)
			str = str..tempstr
		end
		StarEquip_Change_Bk1_Text2:SetText(str)
	end
				
	local theActionOld = EnumAction(6, "quanmin8xing");
	if theActionOld:GetID() ~= 0 then						
		local num = theActionOld:GetEquipAttrCount()
		local str = ""
		for i = 0, num-1 do
			local tempstr = theActionOld:EnumEquipExtAttr(i)
			str = str..tempstr
		end
		StarEquip_Change_Bk2_Text2:SetText(str)
	end
	
end

function StarEquip_Change_OnHidden()
	StarEquip_Change_Clear()
end

function StarEquip_Change_DoClose()
	StarEquip_Change_Clear()
	this:Hide()
end

function StarEquip_Change_OnClosed()
	PushEvent("QM8X_CLOSE_CHANGEUI", g_StarEquip_Change_Idx)
end

function StarEquip_Change_Clear()

	StarEquip_Change_Bk1_Text2:SetText("")
	StarEquip_Change_Bk2_Text2:SetText("")

end

--保留原有属性
function StarEquip_Change_ReGain_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ChongZhuDaZaoCancel");
		Set_XSCRIPT_ScriptID(998847);
		Set_XSCRIPT_Parameter(0, g_StarEquip_Change_Idx);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();	
end

--保留新属性
function StarEquip_Change_Change_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ChongZhuDaZaoOk");
		Set_XSCRIPT_ScriptID(998847);
		Set_XSCRIPT_Parameter(0,g_StarEquip_Change_Idx);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();		
end

function StarEquip_Change_ResetPos()

	StarEquip_Change_Frame:SetProperty("UnifiedPosition", g_StarEquip_Change_Frame_UnifiedPosition)
	
end


