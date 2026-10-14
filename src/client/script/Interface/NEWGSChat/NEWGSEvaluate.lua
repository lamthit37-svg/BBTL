----------------------
-- NEWGSEvaluate ---
----------------------
local g_EvaluateBtn = {}

--===============================================
-- PreLoad()
--===============================================
function NEWGSEvaluate_PreLoad()
	this:RegisterEvent("OPEN_GSEVALUATE_NEW");
	this:RegisterEvent("GS_CANCELBIND_NEW");	
	this:RegisterEvent("FATIE_SECCONFIRM");		
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	--切场景
end

--===============================================
-- OnLoad()
--===============================================
function NEWGSEvaluate_OnLoad()
		g_EvaluateBtn[1]  = NEWGSEvaluate_Frame2_Button3
		g_EvaluateBtn[2]  = NEWGSEvaluate_Frame2_Button2
		g_EvaluateBtn[3]  = NEWGSEvaluate_Frame2_Button1
		g_EvaluateBtn[4]  = NEWGSEvaluate_Frame2_Button6
		g_EvaluateBtn[5]  = NEWGSEvaluate_Frame2_Button5
		g_EvaluateBtn[6]  = NEWGSEvaluate_Frame2_Button4
end

--===============================================
-- OnEvent()
--===============================================
function NEWGSEvaluate_OnEvent(event)

	if( event == "OPEN_GSEVALUATE_NEW" ) then
		NEWGSEvaluate_OnInit()
	elseif ( event == "GS_CANCELBIND_NEW" ) then
		this:Hide()	
	elseif ( event == "FATIE_SECCONFIRM" and arg0 == "close") then		
		Talk:GSChat_SendScoreNew(0,0)
		this:Hide()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()			
	end
end

function NEWGSEvaluate_OnInit()
	local isConnectGS = Talk:IsInGSService()
	if isConnectGS ~= 2 then
		 return
	end
	
	local mGSName = Talk:GetNewGSName()
	NEWGSEvaluate_Frame1_Info1:SetText(mGSName)
	local chatname =ScriptGlobal_Format( "#{GS_130923_18}", mGSName)
	NEWGSEvaluate_Frame1_Info1:SetText(chatname)
	
	for i = 1, table.getn(g_EvaluateBtn) do
		g_EvaluateBtn[i]:SetCheck(0)
	end
	
	this:Show()
end

function NEWGSEvaluate_Close_Clicked()
	PushEvent("FATIE_SECCONFIRM","confirm")
	--this:Hide()
end

function NEWGSEvaluate_Buttons_Clicked()
	local isConnectGS = Talk:IsInGSService()
	if isConnectGS ~= 2 then
		 PushDebugMessage("#{GS_130923_11}")
		 return
	end
	
	local nscroe1 =0
	local nscroe2 =0
	
	for i = 1, 3 do
		if g_EvaluateBtn[i]:GetCheck() == 1 then
			nscroe1 = i
		end
	end

	for i = 4, 6 do
		if g_EvaluateBtn[i]:GetCheck() == 1 then
			nscroe2 = i-3
		end
	end	
	
	if nscroe1 == 0 and nscroe2 == 0 then
		PushDebugMessage("#{GS_130923_20}")
		return
	end
	
	Talk:GSChat_SendScoreNew(nscroe1,nscroe2)  
	PushDebugMessage("#{GSQD_150511_11}")
	this:Hide()
end

--===============================================
-- Btn_Clicked()
--===============================================
function NEWGSEvaluate_MarkBtn_Clicked(nIdx)

	if nIdx >=1 and nIdx <=3 then
		for i=1,3 do
			if i~=nIdx then
				g_EvaluateBtn[i]:SetCheck(0)	
			end
		end
	end	
	
	if nIdx >=4 and nIdx <=6 then
		for i=4,6 do
			if i~=nIdx then
				g_EvaluateBtn[i]:SetCheck(0)	
			end
		end
	end		
end
