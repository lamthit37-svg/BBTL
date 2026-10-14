local g_Frame_UnifiedPosition = nil
local g_Index = -1
local g_nAwardLevelInfo = {
	[1] = {
		[1] = {id = 20101001, num = 1, rate = 1000},
		[2] = {id = 20101002, num = 1, rate = 2000},
		[3] = {id = 20101003, num = 1, rate = 3000},
		[4] = {id = 20101004, num = 1, rate = 4000},
		[5] = {id = 20101005, num = 1, rate = 5000},
		[6] = {id = 20101006, num = 1, rate = 6000},
		[7] = {id = 20101007, num = 1, rate = 7000},
		[8] = {id = 20101008, num = 1, rate = 8000},
		[9] = {id = 20101007, num = 1, rate = 9000},
		[10] = {id = 20101008, num = 1, rate = 10000},
	},
	[2] = {
		[1] = {id = 20101001, num = 1, rate = 1000},
		[2] = {id = 20101002, num = 1, rate = 2000},
		[3] = {id = 20101003, num = 1, rate = 3000},
		[4] = {id = 20101004, num = 1, rate = 4000},
		[5] = {id = 20101005, num = 1, rate = 5000},
		[6] = {id = 20101006, num = 1, rate = 6000},
		[7] = {id = 20101007, num = 1, rate = 7000},
		[8] = {id = 20101008, num = 1, rate = 8000},
		[9] = {id = 20101007, num = 1, rate = 9000},
		[10] = {id = 20101008, num = 1, rate = 10000},
	},
	[3] = {
		[1] = {id = 20101001, num = 1, rate = 1000},
		[2] = {id = 20101002, num = 1, rate = 2000},
		[3] = {id = 20101003, num = 1, rate = 3000},
		[4] = {id = 20101004, num = 1, rate = 4000},
		[5] = {id = 20101005, num = 1, rate = 5000},
		[6] = {id = 20101006, num = 1, rate = 6000},
		[7] = {id = 20101007, num = 1, rate = 7000},
		[8] = {id = 20101008, num = 1, rate = 8000},
		[9] = {id = 20101007, num = 1, rate = 9000},
		[10] = {id = 20101008, num = 1, rate = 10000},
	},
	
}
--=========
-- PreLoad()
--=========
function ZhouchangPVE_Replace_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function ZhouchangPVE_Replace_OnLoad()
	
	g_Frame_UnifiedPosition = ZhouchangPVE_Replace_Frame_BK:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function ZhouchangPVE_Replace_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 33110603) then
	
		g_Index = Get_XParam_INT(0)
		local nItemId = Get_XParam_INT(1)
		local nItemNum = Get_XParam_INT(2)
		local nRefreshItemId = Get_XParam_INT(3)
		local nRefreshItemNum = Get_XParam_INT(4)
		
		ZhouchangPVE_Replace_Open(nIndex, nItemId, nItemNum, nRefreshItemId, nRefreshItemNum)
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ZhouchangPVE_Replace_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ZhouchangPVE_Replace_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		ZhouchangPVE_Replace_On_ResetPos()
	
	end
end


function ZhouchangPVE_Replace_Close()
	ZhouchangPVE_Replace_Item1:SetActionItem(-1)
	ZhouchangPVE_Replace_Item2:SetActionItem(-1)
	ZhouchangPVE_Replace_Item1_Num:SetText("")
	ZhouchangPVE_Replace_Item2_Num:SetText("")
	ZhouchangPVE_Replace_Item1_EyeSign:Hide()
	ZhouchangPVE_Replace_Item2_EyeSign:Hide()
	this:Hide()
end

--=========
-- 重置
--=========
function ZhouchangPVE_Replace_On_ResetPos()

	ZhouchangPVE_Replace_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function ZhouchangPVE_Replace_Open(nIndex, nItemId, nItemNum, nRefreshItemId, nRefreshItemNum)

	ZhouchangPVE_Replace_Item1:SetActionItem(-1)
	ZhouchangPVE_Replace_Item2:SetActionItem(-1)
	ZhouchangPVE_Replace_Item1_Num:SetText("")
	ZhouchangPVE_Replace_Item2_Num:SetText("")
	ZhouchangPVE_Replace_Item1_EyeSign:Hide()
	ZhouchangPVE_Replace_Item2_EyeSign:Hide()
	
	local theAction1 = DataPool:CreateActionItemForShow(nItemId, nItemNum)
	if theAction1:GetID() ~= 0 then
		ZhouchangPVE_Replace_Item1:SetActionItem(theAction1:GetID());
		ZhouchangPVE_Replace_Item1:Show();
		local str = DataPool:Lua_GetItemNameByIndex(nItemId)
		ZhouchangPVE_Replace_Item1_Name:SetText(ScriptGlobal_Format("#{FHCL_240708_300}",str))
	end
	
	local theAction2 = DataPool:CreateActionItemForShow(nRefreshItemId, nRefreshItemNum)
	if theAction2:GetID() ~= 0 then
		ZhouchangPVE_Replace_Item2:SetActionItem(theAction2:GetID());
		ZhouchangPVE_Replace_Item2:Show();
		local str = DataPool:Lua_GetItemNameByIndex(nRefreshItemId)
		ZhouchangPVE_Replace_Item2_Name:SetText(ScriptGlobal_Format("#{FHCL_240708_300}",str))
	end
	this:Show()
end	

--=========
-- ok
--=========
function ZhouchangPVE_Replace_EX(  )

	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeAward" )
			Set_XSCRIPT_ScriptID(331106)
			Set_XSCRIPT_Parameter(0, g_Index);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	ZhouchangPVE_Replace_Close()
end




