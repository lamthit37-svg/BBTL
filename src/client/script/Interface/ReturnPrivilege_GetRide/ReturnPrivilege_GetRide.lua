
local g_Frame_UnifiedPosition
local g_ReturnPrivilege_GetRide_ScriptId=808110;
--=========
--PreLoad==
--=========
function ReturnPrivilege_GetRide_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end
--=========
--OnLoad
--=========
function ReturnPrivilege_GetRide_OnLoad()
	
	g_Frame_UnifiedPosition = ReturnPrivilege_GetRide_Frame:GetProperty("UnifiedPosition")
end
--=========
--OnEvent
--=========
function ReturnPrivilege_GetRide_OnEvent(event)
	
	if event == "UI_COMMAND" then
		if tonumber(arg0) == 80811005 or tonumber(arg0) == 80811205 then
		
			local nCmd = Get_XParam_INT(0);
			if nCmd == 0 then
				if tonumber(arg0) == 80811005 then
					g_ReturnPrivilege_GetRide_ScriptId = 808110;
				end
				if tonumber(arg0) == 80811205 then
					g_ReturnPrivilege_GetRide_ScriptId = 808112;
				end
				ReturnPrivilege_GetRide_Show( nItemId )
			end
		
			if nCmd == 1 then
				this:Hide()
			end
			return
		end
	end

end
--=========
--Show UI
--=========
function ReturnPrivilege_GetRide_Show()
	
	local theAction = DataPool:CreateActionItemForShow(39921014, 1)
	if theAction:GetID() ~= 0 then	
		ReturnPrivilege_GetRide_Icon:SetActionItem(theAction:GetID())
	else
		ReturnPrivilege_GetRide_Icon:SetActionItem(-1)
	end
	this:Show()

end
--点击领坐骑按钮
function ReturnPrivilege_GetRide_GetRide(bnIndex)
	
	if bnIndex == 0 or bnIndex == 1 or bnIndex == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetOldFriendBonus" )
			Set_XSCRIPT_ScriptID( g_ReturnPrivilege_GetRide_ScriptId )
			Set_XSCRIPT_Parameter( 0, 100 + bnIndex ) --100 免费的 101 加钱换购1 102 加钱换购2
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end

end
--=========
--OnClose "X"
--=========
function ReturnPrivilege_GetRide_OnCloseClicked()
	this:Hide()
end
--=========
--handle Hide Event
--=========
function ReturnPrivilege_GetRide_OnHiden()
	ReturnPrivilege_GetRide_Icon:SetActionItem(-1)
end

function ReturnPrivilege_GetRide_On_ResetPos()
	ReturnPrivilege_GetRide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end