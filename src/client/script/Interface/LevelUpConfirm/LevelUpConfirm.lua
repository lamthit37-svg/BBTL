local g_LevelUpConfirm_Frame_UnifiedPosition = ""

local g_LevelUpConfirm_ConfirmLevel = 0  
local g_LevelUpConfirm_AddOrSub = 0   -- 0加法 1减法
local g_LevelUpConfirm_NumA = 0
local g_LevelUpConfirm_NumB = 0
local g_LevelUpConfirm_Answer = 0

local g_LevelUpConfirm_IsOk = 0

local g_LevelUpConfirm_InfoText = ""
local g_LevelUpConfirm_QuestionText = ""
local g_LevelUpConfirm_OKBtn = ""
local g_LevelUpConfirm_CancelBtn = ""
local g_LevelUpConfirm_InputAnswerText = ""


function LevelUpConfirm_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false) 	    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false); 
end

function LevelUpConfirm_OnLoad()
	g_LevelUpConfirm_QuestionText = LevelUpConfirm_QustionText
	g_LevelUpConfirm_InfoText = LevelUpConfirm_InfoText
	g_LevelUpConfirm_Frame_UnifiedPosition = LevelUpConfirm_Frame:GetProperty("UnifiedPosition")
	g_LevelUpConfirm_OKBtn = LevelUpConfirm_ConfirmBtn
	g_LevelUpConfirm_CancelBtn = LevelUpConfirm_CancelBtn
	g_LevelUpConfirm_InputAnswerText = LevelUpConfirm_InputAnswer
end

function LevelUpConfirm_OnEvent(event)

	if event == "VIEW_RESOLUTION_CHANGED" then
		LevelUpConfirm_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ActivitySchedule_MBuy_Closed()
	elseif event == "ADJEST_UI_POS" then
		LevelUpConfirm_Frame_On_ResetPos() 		
	end

	
	-- 打开界面
	if (event == "UI_COMMAND" and tonumber(arg0) == 20150417) then 
		
		if ( Get_XParam_INT_Count() < 4 ) then
			return
		end

		g_LevelUpConfirm_ConfirmLevel = tostring(Get_XParam_INT(0))
		g_LevelUpConfirm_AddOrSub = tonumber(Get_XParam_INT(1))
		g_LevelUpConfirm_NumA = tonumber(Get_XParam_INT(2))
		g_LevelUpConfirm_NumB = tonumber(Get_XParam_INT(3))

		--local randomA = math.random( 10, 99 ) 
		--local randomB = math.random( 10, 99 ) 	
		--local addorsub = math.random( 1, 2 ) - 1	
		--if (randomA < randomB) then
		--	randomB = randomA + randomB;
		--	randomA = randomB - randomA;
		--	randomB = randomB - randomA;
		--end
		
		--g_LevelUpConfirm_ConfirmLevel = tostring(Get_XParam_INT(0))
		--g_LevelUpConfirm_AddOrSub = tostring(addorsub)
		--g_LevelUpConfirm_NumA = tostring(randomA)
		--g_LevelUpConfirm_NumB = tostring(randomB)

		LevelUpConfirm_Update() 

		this:Show()
		return
	end	
	
end

function LevelUpConfirm_Update()
	
	local questionText = ""
	if g_LevelUpConfirm_AddOrSub == 0 then   -- 0 加法
		g_LevelUpConfirm_Answer = g_LevelUpConfirm_NumA + g_LevelUpConfirm_NumB
		questionText = ScriptGlobal_Format("#{SJQR_210805_01}", tostring(g_LevelUpConfirm_NumA),tostring(g_LevelUpConfirm_NumB))	
	else  -- 1 减法
		g_LevelUpConfirm_Answer = g_LevelUpConfirm_NumA - g_LevelUpConfirm_NumB
		questionText = ScriptGlobal_Format("#{SJQR_210805_02}", tostring(g_LevelUpConfirm_NumA),tostring(g_LevelUpConfirm_NumB))	
	end

	local confirmLevel = g_LevelUpConfirm_ConfirmLevel
	local curLevel = confirmLevel - 1
	local strText = ScriptGlobal_Format("#{SJQR_150417_3}", tostring(curLevel),tostring(confirmLevel))	

	g_LevelUpConfirm_QuestionText:SetText(questionText)
	g_LevelUpConfirm_InfoText:SetText(strText)
	g_LevelUpConfirm_OKBtn:Disable()
	g_LevelUpConfirm_InputAnswerText:SetText("")

end

function LevelUpConfirm_Frame_On_ResetPos()
	LevelUpConfirm_Frame:SetProperty("UnifiedPosition", g_LevelUpConfirm_Frame_UnifiedPosition)
end


function LevelUpConfirm_OnClose()
	g_LevelUpConfirm_ConfirmLevel = 0  
	g_LevelUpConfirm_AddOrSub = 0   -- 0加法 1减法
	g_LevelUpConfirm_NumA = 0
	g_LevelUpConfirm_NumB = 0
	g_LevelUpConfirm_Answer = 0
	g_LevelUpConfirm_IsOk = 0
	this:Hide()
end


function LevelUpConfirm_TextChanged()
	
	local isOk = LevelUpConfirm_CheckAnswer()	
	if isOk == 1 then 
		g_LevelUpConfirm_IsOk = 1
		g_LevelUpConfirm_OKBtn:Enable()
	else
		g_LevelUpConfirm_OKBtn:Disable()
	end
end


function LevelUpConfirm_CheckAnswer()
	local ret = 0
	local inputAnswer = tonumber(g_LevelUpConfirm_InputAnswerText:GetText())
	if inputAnswer == g_LevelUpConfirm_Answer then
		ret = 1
	end
	return ret
end


function LevelUpConfirm_OnOkBtn()
	AskLevelUpAfterSec(0);
	AskLevelUpAfterValidate();
	LevelUpConfirm_OnClose()
end


function LevelUpConfirm_OnCancelBtn()
	LevelUpConfirm_OnClose()
end

function LevelUpConfirm_Cancel_Clicked()
	LevelUpConfirm_OnClose()
end
