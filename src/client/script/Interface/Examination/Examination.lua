
local g_Examination_UnifiedPosition;

local g_Examination_Type = -1
local g_Examination_Script = -1
local g_Examination_targetId = -1;

local Examination_Buttons = {}
local Examination_TextButtons = {}
local Examination_Answer = {}
local Examination_False = {}

local Current = -1;
local Question = 0;
local Question_Sequence = 0;
local Button_Answer = {}
local Current_Answer = -1;

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local g_Object = -1;

local HaveClicked = 0

local Button_Answer_True = "set:Keju image:Keju_TRUE_Normal"
local Button_Answer_False = "set:Keju image:Keju_FALSE_Normal"
local Button_Answer_Normal = "set:Keju image:Keju_Btn_Normal"
local Button_Answer_Disable = "set:Keju image:Keju_Btn_Disabled"

function Examination_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);	
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Examination_OnLoad()

	Examination_Buttons[1] = Examination_Button_1;
	Examination_Buttons[2] = Examination_Button_2;
	Examination_Buttons[3] = Examination_Button_3;
	
	Examination_TextButtons[1] = Examination_Button_1_Text
	Examination_TextButtons[2] = Examination_Button_2_Text
	Examination_TextButtons[3] = Examination_Button_3_Text

	g_Examination_UnifiedPosition = Examination_Frame:GetProperty("UnifiedPosition");
	
end

function Examination_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 28) then
	
		Examination_OnShown();
			
	elseif ( event == "OBJECT_CARED_EVENT" ) then
		
		if(tonumber(arg0) ~= objCared) then
			return
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then			
			--取消关心
			Examination_Cancel_Clicked()
		end

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Examination_Cancel_Clicked()
		
	elseif (event == "ADJEST_UI_POS" ) then
		Examination_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Examination_On_ResetPos()
		
	end
end

function Examination_OnShown()

	local UI_ID = Get_XParam_INT(0)
	if UI_ID == 0 then
	-- 关闭界面
		Examination_Cancel_Clicked()
		return
		
	elseif UI_ID == 2 then
	-- 答题
		Question_Sequence = Get_XParam_INT(1)
		Question = Get_XParam_INT(2)
			
		local strquest = Get_XParam_STR(0)
		str = ScriptGlobal_Format("#{KJYH_221116_72}", strquest) -- 题目
		Examination_Text:SetText( str );
		Examination_Text:Show();
			
		local strtype = Get_XParam_STR(7)
		str = ScriptGlobal_Format("#{KJYH_221116_70}", strtype) -- 类型：
		Examination_Type_Text:SetText( str )
		Examination_Type_Text:Show();
			
		str = ScriptGlobal_Format("#{KJYH_221116_71}", Question_Sequence) -- 第X题
		Examination_Number_Text:SetText( str )
		Examination_Number_Text:Show();
					
		for i=1,3 do
			Examination_Buttons[i]:SetText("")
			Examination_TextButtons[i]:SetText("")
			Button_Answer[i] = -1
		end									
		for i=1,3 do
			local str_temp = Get_XParam_STR(i);
			local answer_position = Get_XParam_INT(2+i)
			if  str_temp~= "#" and str_temp~="" then
				Examination_TextButtons[answer_position+1] : Show();
				Examination_TextButtons[answer_position+1] : SetText(str_temp)
				--Examination_Buttons[answer_position+1] : Show();
				--Examination_Buttons[answer_position+1] : SetText(str_temp)
				Button_Answer[answer_position+1] = i;
			end
		end
			
		g_Examination_Type = Get_XParam_INT(9);
		local NPCName =	Target:GetDialogNpcName();
		local str = ScriptGlobal_Format("#{KJYH_221116_69}", NPCName) -- NPCName..(共5题)  
		if g_Examination_Type == 2 then
			str = ScriptGlobal_Format("#{KJYH_221116_73}", NPCName)
		end
		Examination_NPCName_Text:SetText( str )
		Examination_NPCName_Text:Show()
		
		g_Examination_Script = Get_XParam_INT(10); 
		g_Examination_targetId = Get_XParam_INT(11);
		objCared = DataPool : GetNPCIDByServerID(g_Examination_targetId);
		if objCared == -1 then
			return;
		end
		BeginCareObject_Examination(objCared)
						
		HaveClicked = 0
		
		Examination_Yes:Hide()
		Examination_No:Hide()
		Examination_Button_Next:Hide()
		
		Current = UI_ID;
		
		this:Show();
		
	elseif UI_ID == 11 then
	-- 回答错误
		Examination_Button_Next:Show()		
		Examination_No:Show()		
		Examination_Yes:Hide()
		
		if Get_XParam_INT(1) == 1 then
			Examination_Button_Next:SetText("#{KJYH_221116_66}")
		else
			Examination_Button_Next:SetText("#{KJYH_221116_65}")
		end
		
		for i=1,3 do 
			Examination_Buttons[i]:Disable()
		end
		
		if Examination_Buttons[Current_Answer] ~= nil then
			Examination_Buttons[Current_Answer]:SetProperty("DisabledImage", Button_Answer_False)
		end
		
		for i = 1, 3 do
			local nRightPos = Get_XParam_INT(2)
			if Button_Answer[i] == nRightPos then 	
				Examination_Buttons[i]:SetProperty("DisabledImage", Button_Answer_True)
			end
		end
		
		Current = UI_ID;
		
		return
		
	elseif UI_ID == 22 then
	-- 回答正确
		Examination_Button_Next:Show()		
		Examination_Yes:Show()
		Examination_No:Hide()
		
		if Get_XParam_INT(1) == 1 then
			Examination_Button_Next:SetText("#{KJYH_221116_66}")
		else
			Examination_Button_Next:SetText("#{KJYH_221116_65}")
		end
		
		for i=1,3 do 
			Examination_Buttons[i]:Disable()
		end
		
		if Examination_Buttons[Current_Answer] ~= nil then
			Examination_Buttons[Current_Answer]:SetProperty("DisabledImage", Button_Answer_True)
		end
		
		Current = UI_ID;
		
		return
	end
	
	Examination_Time_Text : Show();			
	Examination_Time_Text : SetProperty("Timer","1");
	
	for i=1,3 do
		Examination_Buttons[i]:Disable()
		Examination_Buttons[i]:SetProperty("DisabledImage", Button_Answer_Normal)	
	end
	
end

function Examination_Button_Clicked( nAnswerNumber )
	
	-- 答题
	if Question > 0 then
		if nAnswerNumber > 0 and nAnswerNumber < 4 then
			if HaveClicked == 1 then
				return
			end
			HaveClicked = 1
			
			for i=1,3 do 
				Examination_Buttons[i]:Disable()
			end
			
			Current_Answer = nAnswerNumber 
			
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("AnswerQuestion");
				Set_XSCRIPT_ScriptID(998372);
				Set_XSCRIPT_Parameter(0, Question);
				Set_XSCRIPT_Parameter(1, Button_Answer[nAnswerNumber]);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
			return
		end
	end

end

function Examination_Cancel_Clicked()
	
	Current = -1
	Current_Answer = -1
	StopCareObject_Examination(objCared)
	this:Hide();
	
end

function Examination_Next_Clicked()

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("AnswerNextQuestion");
		Set_XSCRIPT_ScriptID(998372);
		Set_XSCRIPT_Parameter(0, 1);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
			
end

function Examination_On_ResetPos()

  Examination_Frame:SetProperty("UnifiedPosition", g_Examination_UnifiedPosition);
  
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_Examination(objCaredId)
	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "Examination");
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_Examination(objCaredId)
	this:CareObject(objCaredId, 0, "Examination");
	g_Object = -1;
end

function Examination_OnHidden()

	Current_Answer = -1 	

	if (Current == 22 or Current == 11) and Question > 0 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnOverTime");
			Set_XSCRIPT_ScriptID(998372);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end		
	
	StopCareObject_Examination(objCared)
	this:Hide();
	
end

--记时到0后
function Examination_TimeOut()

	for i=1,3 do
		Examination_Buttons[i]:Enable()
		Examination_Buttons[i]:SetProperty("DisabledImage", Button_Answer_Disable)		
	end
	
end

