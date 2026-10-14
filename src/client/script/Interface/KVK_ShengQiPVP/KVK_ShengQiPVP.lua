
local g_Frame_UnifiedPosition;
local g_YaoTa_Ceng = 0;
local g_YaoTa_Pos = 0;
local g_YaoTa_CengButton ={} 
local g_objCared = -1;
function KVK_ShengQiPVP_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	
end
--=========
--OnLoad
--=========
function KVK_ShengQiPVP_OnLoad()
	
	g_Frame_UnifiedPosition = KVK_ShengQiPVP_Frame:GetProperty("UnifiedPosition")
	g_YaoTa_CengButton[1] = KVK_ShengQiPVP_LeftFrame_Button9
	g_YaoTa_CengButton[2] = KVK_ShengQiPVP_LeftFrame_Button8
	g_YaoTa_CengButton[3] = KVK_ShengQiPVP_LeftFrame_Button7
	g_YaoTa_CengButton[4] = KVK_ShengQiPVP_LeftFrame_Button6
	g_YaoTa_CengButton[5] = KVK_ShengQiPVP_LeftFrame_Button5
	g_YaoTa_CengButton[6] = KVK_ShengQiPVP_LeftFrame_Button4
	g_YaoTa_CengButton[7] = KVK_ShengQiPVP_LeftFrame_Button3
	g_YaoTa_CengButton[8] = KVK_ShengQiPVP_LeftFrame_Button2
	g_YaoTa_CengButton[9] = KVK_ShengQiPVP_LeftFrame_Button1
	
end
--=========
--OnEvent
--=========
function KVK_ShengQiPVP_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 20170809 then
		local nType = Get_XParam_INT(0);
		if nType == 0 then
			this:Hide()
		elseif nType == 1 then
			local nLastCeng = Get_XParam_INT(1);
			g_objCared =  DataPool:GetNPCIDByServerID(Get_XParam_INT(2));
			this:CareObject(g_objCared, 1, "KVK_ShengQiPVP");
			if nLastCeng <=0 then
				for i=1,9 do
					g_YaoTa_CengButton[i]:SetCheck(0)
					g_YaoTa_CengButton[i]:Enable()
				end				
				g_YaoTa_Ceng = 0
			else
				for i=1,9 do
					g_YaoTa_CengButton[i]:SetCheck(0)
					g_YaoTa_CengButton[i]:Disable()
				end							
				g_YaoTa_CengButton[nLastCeng]:Enable()
				g_YaoTa_CengButton[nLastCeng]:SetCheck(1)
				g_YaoTa_Ceng = nLastCeng
			end
			this:Show()
		end
		return
	elseif(event ==  "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCared) then
			return;
		end
		
		if(arg1 == "distance" and tonumber(arg2) > 3.0 or arg1=="destroy" ) then
			KVK_ShengQiPVP_CloseFrame()
		end				
	elseif ( event == "HIDE_ON_SCENE_TRANSED") then
		KVK_ShengQiPVP_CloseFrame()
		return		
	end

end


function KVK_ShengQiPVP_CengClicked(nCeng)
	for i=1,9 do
		g_YaoTa_CengButton[i]:SetCheck(0)
	end
	g_YaoTa_CengButton[nCeng]:SetCheck(1)
	g_YaoTa_Ceng = nCeng

end


function KVK_ShengQiPVP_PosClicked(nPos)
	g_YaoTa_Pos = nPos
end

function KVK_ShengQiPVP_EnterClicked()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnEnterYaoTa" )
			Set_XSCRIPT_ScriptID( 892506)
			Set_XSCRIPT_Parameter( 0, g_YaoTa_Ceng )
			Set_XSCRIPT_Parameter( 1, g_YaoTa_Pos )
			Set_XSCRIPT_Parameter( 2, 1 )	
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
end

--=========
--OnClose "X"
--=========
function KVK_ShengQiPVP_CloseFrame()
	g_objCared = -1
	this:Hide()
end
--=========
--handle Hide Event
--=========
function KVK_ShengQiPVP_OnHiden()
	
end

function KVK_ShengQiPVP_On_ResetPos()
	KVK_ShengQiPVP_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end


