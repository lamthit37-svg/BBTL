local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_ItemID = {}

function ModifyMenPai_Preheat1_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("SCENE_TRANSED")
end

function ModifyMenPai_Preheat1_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition = ModifyMenPai_Preheat1_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = ModifyMenPai_Preheat1_Frame:GetProperty("UnifiedYPosition");		
	
	g_ItemID =
	{
		[1] = {itemid = 39920847, count = 35,},
		[2] = {itemid = 39921299, count = 10,},
		[3] = {itemid = 39921554, count = 1, },		
	}	
end

function ModifyMenPai_Preheat1_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		ModifyMenPai_Preheat1_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ModifyMenPai_Preheat1_ResetPos()
	elseif( event == "SCENE_TRANSED") then
		this:Hide()		
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 89295102) then	
		local param = Get_XParam_INT(0)
		if param == 1 then
			local theAction1 = DataPool:CreateActionItemForShow(g_ItemID[1].itemid, g_ItemID[1].count)
			ModifyMenPai_Preheat1_Item1:SetActionItem(theAction1:GetID())
			local theAction2 = DataPool:CreateActionItemForShow(g_ItemID[2].itemid, g_ItemID[2].count)
			ModifyMenPai_Preheat1_Item2:SetActionItem(theAction2:GetID())
			local theAction3 = DataPool:CreateActionItemForShow(g_ItemID[3].itemid, g_ItemID[3].count)
			ModifyMenPai_Preheat1_Item3:SetActionItem(theAction3:GetID())			
			this:Show()
		else
			this:Hide()
		end
	end
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function ModifyMenPai_Preheat1_ResetPos()
	ModifyMenPai_Preheat1_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ModifyMenPai_Preheat1_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function ModifyMenPai_Preheat1_Close()
	this:Hide()
end

function ModifyMenPai_Preheat1_Button()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAccept")
		Set_XSCRIPT_ScriptID(892951)
		--Set_XSCRIPT_Parameter(0,1) --默认打开第1个分页
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

