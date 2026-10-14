----------------------
-- GSEvaluate ---
----------------------
local g_EvaluateBtn = {}

--===============================================
-- PreLoad()
--===============================================
function GSEvaluate_PreLoad()
	this:RegisterEvent("OPEN_GSEVALUATE");
	this:RegisterEvent("GS_CANCELBIND");	
end

--===============================================
-- OnLoad()
--===============================================
function GSEvaluate_OnLoad()
		g_EvaluateBtn[1]  = GSEvaluate_Frame2_Button1
		g_EvaluateBtn[2]  = GSEvaluate_Frame2_Button2
		g_EvaluateBtn[3]  = GSEvaluate_Frame2_Button3
		g_EvaluateBtn[4]  = GSEvaluate_Frame2_Button4
		g_EvaluateBtn[5]  = GSEvaluate_Frame2_Button5
		g_EvaluateBtn[6]  = GSEvaluate_Frame2_Button6
		g_EvaluateBtn[7]  = GSEvaluate_Frame2_Button7
		g_EvaluateBtn[8]  = GSEvaluate_Frame2_Button8
		g_EvaluateBtn[9]  = GSEvaluate_Frame2_Button9
		g_EvaluateBtn[10]  = GSEvaluate_Frame2_Button10
end

--===============================================
-- OnEvent()
--===============================================
function GSEvaluate_OnEvent(event)

	if( event == "OPEN_GSEVALUATE" ) then
		GSEvaluate_OnInit()
	elseif ( event == "GS_CANCELBIND" ) then
		this:Hide()	
	end
end

function GSEvaluate_OnInit()
	local isConnectGS = Talk:IsInGSService()
	if isConnectGS ~= 1 then
		 return
	end
	
	local mGSName = Talk:GetGSName()
	GSEvaluate_Frame1_Info1:SetText(mGSName)
	local chatname =ScriptGlobal_Format( "#{GS_130923_18}", mGSName)
	GSEvaluate_Frame1_Info1:SetText(chatname)
	
	for i = 1, table.getn(g_EvaluateBtn) do
		g_EvaluateBtn[i]:SetCheck(0)
	end
	
	--默认为满意
	g_EvaluateBtn[1]:SetCheck(1)
	
	this:Show()
end

function GSEvaluate_Close_Clicked()
	this:Hide()
end

function GSEvaluate_Buttons_Clicked()
	local isConnectGS = Talk:IsInGSService()
	if isConnectGS ~= 1 then
		 PushDebugMessage("#{GS_130923_11}")
		 return
	end
	
	for i = 1, table.getn(g_EvaluateBtn) do
		if g_EvaluateBtn[i]:GetCheck() == 1 then
			Talk:GSChat_SendScore(11-i)  --第一个按钮对应的是10分 所以是11-i 
		  this:Hide()
		end
	end
	
end

--===============================================
-- Btn_Clicked()
--===============================================
function GSEvaluate_MarkBtn_Clicked(nIdx)
	
	for i = 1, table.getn(g_EvaluateBtn) do
		g_EvaluateBtn[i]:SetCheck(0)
	end
	
	g_EvaluateBtn[nIdx]:SetCheck(1)
end
