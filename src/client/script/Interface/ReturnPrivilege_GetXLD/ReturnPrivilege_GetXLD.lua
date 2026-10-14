
local g_Frame_UnifiedPosition
local g_ReturnPrivilege_GetXLD_ScriptId=808110;
--=========
--PreLoad==
--=========
function ReturnPrivilege_GetXLD_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end
--=========
--OnLoad
--=========
function ReturnPrivilege_GetXLD_OnLoad()
	
	g_Frame_UnifiedPosition = ReturnPrivilege_GetXLD_Frame:GetProperty("UnifiedPosition")
end
--=========
--OnEvent
--=========
function ReturnPrivilege_GetXLD_OnEvent(event)
	
	if event == "UI_COMMAND" then
		if tonumber(arg0) == 80811006 or tonumber(arg0) == 80811206 then
		
			local nCmd = Get_XParam_INT(0);
			if nCmd == 0 then
				if tonumber(arg0) == 80811006 then
					g_ReturnPrivilege_GetXLD_ScriptId = 808110;
				end
				if tonumber(arg0) == 80811206 then
					g_ReturnPrivilege_GetXLD_ScriptId = 808112;
				end
				ReturnPrivilege_GetXLD_Show()
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
function ReturnPrivilege_GetXLD_Show()
	
	local theAction = DataPool:CreateActionItemForShow(39921017, 1)
	if theAction:GetID() ~= 0 then	
		ReturnPrivilege_GetXLD_Icon:SetActionItem(theAction:GetID())
	else
		ReturnPrivilege_GetXLD_Icon:SetActionItem(-1)
	end
	this:Show()

end
--点击领Buff按钮
function ReturnPrivilege_GetXLD_GetXLD(bnIndex)
	
	if bnIndex == 0 or bnIndex == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetOldFriendBonus" )
			Set_XSCRIPT_ScriptID( g_ReturnPrivilege_GetXLD_ScriptId )
			Set_XSCRIPT_Parameter( 0, 200 + bnIndex ) --200 免费的 201 加钱换购
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end

end
--=========
--OnClose "X"
--=========
function ReturnPrivilege_GetXLD_OnCloseClicked()
	this:Hide()
end
--=========
--handle Hide Event
--=========
function ReturnPrivilege_GetXLD_OnHiden()
	ReturnPrivilege_GetXLD_Icon:SetActionItem(-1)
end

function ReturnPrivilege_GetXLD_On_ResetPos()
	ReturnPrivilege_GetXLD_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end