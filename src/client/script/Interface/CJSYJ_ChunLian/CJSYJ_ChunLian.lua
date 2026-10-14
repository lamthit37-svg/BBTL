--辞旧岁应景活动-贴春联
-- !!!reloadscript =CJSYJ_ChunLian
local g_CJSYJ_ChunLian_Frame_UnifiedXPosition
local g_CJSYJ_ChunLian_Frame_UnifiedYPosition

local g_CJSYJ_ChunLian_Chooses = {}
local g_CJSYJ_ChunLian_CurSelectIndex = 0

local g_CareObj = -1

local g_CJSYJ_ChunLian_QuestionAnser = 
{
	[1] = 
	{
	   ChooseImage={"set:CJSYJ05 image:CLWord01","set:CJSYJ05 image:CLWord02","set:CJSYJ05 image:CLWord03","set:CJSYJ05 image:CLWord04","set:CJSYJ05 image:CLWord05","set:CJSYJ05 image:CLWord06"},
	   AnswerCount = 3,
	   AnswerIndex = {1,2,3},
	   AnswerChoose = {1,6,4},
	},
	[2] = 
	{
	   ChooseImage={"set:CJSYJ05 image:CLWord07","set:CJSYJ05 image:CLWord08","set:CJSYJ05 image:CLWord09","set:CJSYJ05 image:CLWord10","set:CJSYJ05 image:CLWord11","set:CJSYJ05 image:CLWord12"},
	   AnswerCount = 3,
	   AnswerIndex = {4,5,6},
	   AnswerChoose = {3,4,2},
	}
}

local g_CJSYJ_ChunLian_Anseres = {}
local g_CJSYJ_ChunLian_RightCount = 0

local g_CJSYJ_ChunLian_CurStep = 0

local g_CJSYJ_ChunLian_CurQuestionType = 0
--===============================================
-- OnLoad()
--===============================================
function CJSYJ_ChunLian_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)

end

function CJSYJ_ChunLian_OnLoad()

	g_CJSYJ_ChunLian_Chooses={
		[1]={bLock=0,btn=CJSYJ_ChunLian_Choose_Button1,bkg=CJSYJ_ChunLian_Choose_Button1_Lace},
		[2]={bLock=0,btn=CJSYJ_ChunLian_Choose_Button2,bkg=CJSYJ_ChunLian_Choose_Button2_Lace},
		[3]={bLock=0,btn=CJSYJ_ChunLian_Choose_Button3,bkg=CJSYJ_ChunLian_Choose_Button3_Lace},
		[4]={bLock=0,btn=CJSYJ_ChunLian_Choose_Button4,bkg=CJSYJ_ChunLian_Choose_Button4_Lace},
		[5]={bLock=0,btn=CJSYJ_ChunLian_Choose_Button5,bkg=CJSYJ_ChunLian_Choose_Button5_Lace},
		[6]={bLock=0,btn=CJSYJ_ChunLian_Choose_Button6,bkg=CJSYJ_ChunLian_Choose_Button6_Lace},
	};
	g_CJSYJ_ChunLian_Anseres={
		[1]={secIndex=0,bLock=0,btn=CJSYJ_ChunLian_Button1,bkg=CJSYJ_ChunLian_Button1_Lace,Animate=CJSYJ_ChunLian_Button1_Animate},
		[2]={secIndex=0,bLock=0,btn=CJSYJ_ChunLian_Button2,bkg=CJSYJ_ChunLian_Button2_Lace,Animate=CJSYJ_ChunLian_Button2_Animate},
		[3]={secIndex=0,bLock=0,btn=CJSYJ_ChunLian_Button3,bkg=CJSYJ_ChunLian_Button3_Lace,Animate=CJSYJ_ChunLian_Button3_Animate},
		[4]={secIndex=0,bLock=0,btn=CJSYJ_ChunLian_Button4,bkg=CJSYJ_ChunLian_Button4_Lace,Animate=CJSYJ_ChunLian_Button4_Animate},
		[5]={secIndex=0,bLock=0,btn=CJSYJ_ChunLian_Button5,bkg=CJSYJ_ChunLian_Button5_Lace,Animate=CJSYJ_ChunLian_Button5_Animate},
		[6]={secIndex=0,bLock=0,btn=CJSYJ_ChunLian_Button6,bkg=CJSYJ_ChunLian_Button6_Lace,Animate=CJSYJ_ChunLian_Button6_Animate},
	};
	g_CJSYJ_ChunLian_QuestionAnser[1].Frame = CJSYJ_ChunLian_Frame1
	g_CJSYJ_ChunLian_QuestionAnser[2].Frame = CJSYJ_ChunLian_Frame2
	-- 保存界面的默认相对位置
	g_CJSYJ_ChunLian_Frame_UnifiedXPosition	= CJSYJ_ChunLian_Frame : GetProperty("UnifiedXPosition");
	g_CJSYJ_ChunLian_Frame_UnifiedYPosition	= CJSYJ_ChunLian_Frame : GetProperty("UnifiedYPosition");
end
--===============================================
-- OnEvent()
--===============================================
function CJSYJ_ChunLian_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 2018010502) then	
		local npcid = Get_XParam_INT(0)
		if( npcid ~= -1 ) then
			g_CareObj = DataPool:GetNPCIDByServerID(npcid)
		end
		CJSYJ_ChunLian_ClearUIData()
		g_CJSYJ_ChunLian_CurQuestionType = math.random(1,2)
		g_CJSYJ_ChunLian_CurStep = 1
		CJSYJ_ChunLian_RrefreshUI()
		this:Show()
		CJSYJ_ChunLian_CareObject()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		CJSYJ_ChunLian_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		CJSYJ_ChunLian_Frame_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if (tonumber(arg0) ~= g_CareObj) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > 15) or arg1=="destroy") then
			CJSYJ_ChunLian_Frame_OnHiden()
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		CJSYJ_ChunLian_Frame_OnHiden()
	end
end

function CJSYJ_ChunLian_ClearUIData()
	g_CJSYJ_ChunLian_CurSelectIndex = 0
	g_CJSYJ_ChunLian_RightCount = 0
	g_CJSYJ_ChunLian_CurStep = 0
	for i=1,table.getn(g_CJSYJ_ChunLian_Chooses) do
		g_CJSYJ_ChunLian_Chooses[i].bLock = 0
		if(g_CJSYJ_ChunLian_Anseres[i] ~= nil) then
			g_CJSYJ_ChunLian_Anseres[i].bLock = 0
			g_CJSYJ_ChunLian_Anseres[i].secIndex = 0
		end
	end
end

--===============================================
-- OnHiden
--===============================================
function CJSYJ_ChunLian_Frame_OnHiden()
	CJSYJ_ChunLian_ClearUIData()
	CJSYJ_ChunLian_StopCareObject()
	KillTimer("CJSYJ_ChunLian_OnFinshTimer()")
	this:Hide()
end

function CJSYJ_ChunLian_Quit_Clicked()
	CJSYJ_ChunLian_Frame_OnHiden()
end

--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function CJSYJ_ChunLian_CareObject()
	this:CareObject(g_CareObj, 1, "CJSYJ_ChunLian")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function CJSYJ_ChunLian_StopCareObject()
	this:CareObject(g_CareObj, 0, "CJSYJ_ChunLian")
	g_CareObj = -1
	return
end

function CJSYJ_ChunLian_RrefreshUI()
	if(g_CJSYJ_ChunLian_CurQuestionType<1 or g_CJSYJ_ChunLian_CurQuestionType >2)then
		g_CJSYJ_ChunLian_CurQuestionType = math.random(1,2)
	end
	for i=1,table.getn(g_CJSYJ_ChunLian_QuestionAnser) do
		if(g_CJSYJ_ChunLian_CurQuestionType == i) then
			g_CJSYJ_ChunLian_QuestionAnser[i].Frame:Show()
		else
			g_CJSYJ_ChunLian_QuestionAnser[i].Frame:Hide()
		end
	end
	--设置备选底图
	for i=1,table.getn(g_CJSYJ_ChunLian_Chooses) do
		local szImage = g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].ChooseImage[i]	
		g_CJSYJ_ChunLian_Chooses[i].bkg:SetProperty("Image",szImage)
		g_CJSYJ_ChunLian_Chooses[i].bkg:Show()
	end

	--显示答案空
	for i=1,table.getn(g_CJSYJ_ChunLian_Anseres)  do
		g_CJSYJ_ChunLian_Anseres[i].bkg:Hide()
		g_CJSYJ_ChunLian_Anseres[i].Animate:Hide()
		g_CJSYJ_ChunLian_Anseres[i].btn:SetProperty("Image","")
	end
	local AnswerIndex = g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].AnswerIndex
	for i=1,table.getn(AnswerIndex) do
		local n = AnswerIndex[i]
		if(g_CJSYJ_ChunLian_Anseres[n] ~= nil) then
			g_CJSYJ_ChunLian_Anseres[n].bkg:Show()
		end
		local nSecIndex = g_CJSYJ_ChunLian_Anseres[n].secIndex
		if(g_CJSYJ_ChunLian_Chooses[nSecIndex]~= nil) then
			g_CJSYJ_ChunLian_Chooses[nSecIndex].bkg:Hide()
		end
		local szImage = g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].ChooseImage[nSecIndex]
		if(szImage ~= nil) then
			g_CJSYJ_ChunLian_Anseres[n].btn:SetProperty("Image",szImage)
		end
		if(i == g_CJSYJ_ChunLian_CurStep) then
			g_CJSYJ_ChunLian_Anseres[n].Animate:Show()
		end
	end
	if(g_CJSYJ_ChunLian_RightCount == g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].AnswerCount) then
		CJSYJ_ChunLian_Finish:Show()
		SetTimer("CJSYJ_ChunLian","CJSYJ_ChunLian_OnFinshTimer()",2000)
	else
		CJSYJ_ChunLian_Finish:Hide()
	end
end

function CJSYJ_ChunLian_OnFinshTimer()
	CJSYJ_ChunLian_Finish:Hide()
	KillTimer("CJSYJ_ChunLian_OnFinshTimer()")
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function CJSYJ_ChunLian_Frame_On_ResetPos()

	CJSYJ_ChunLian_Frame : SetProperty("UnifiedXPosition", g_CJSYJ_ChunLian_Frame_UnifiedXPosition);
	CJSYJ_ChunLian_Frame : SetProperty("UnifiedYPosition", g_CJSYJ_ChunLian_Frame_UnifiedYPosition);

end


function CJSYJ_ChunLian_ClickSelct(nIndex)
	if(g_CJSYJ_ChunLian_RightCount == g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].AnswerCount) then
		PushDebugMessage("全部回答正确")
		return
	end
	if(nIndex < 1 or nIndex > table.getn(g_CJSYJ_ChunLian_Chooses)) then
		return
	end

	local szImage = g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].ChooseImage[nIndex]	
	local AnswerChoose = g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].AnswerChoose
	local AnswerIndex = g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].AnswerIndex
	if(nIndex == AnswerChoose[g_CJSYJ_ChunLian_CurStep]) then
		g_CJSYJ_ChunLian_Anseres[AnswerIndex[g_CJSYJ_ChunLian_CurStep]].btn:SetProperty("Image",szImage)
		g_CJSYJ_ChunLian_Anseres[AnswerIndex[g_CJSYJ_ChunLian_CurStep]].secIndex = nIndex
		g_CJSYJ_ChunLian_CurStep = g_CJSYJ_ChunLian_CurStep + 1
		g_CJSYJ_ChunLian_RightCount = g_CJSYJ_ChunLian_RightCount + 1
		PushDebugMessage("#{CJSX_180103_57}")
		if(g_CJSYJ_ChunLian_RightCount == g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].AnswerCount) then
			CJSYJ_ChunLian_OnClickOk()
		end
	else
		PushDebugMessage("#{CJSX_180103_56}")
	end
	CJSYJ_ChunLian_RrefreshUI()
end

function CJSYJ_ChunLian_OnClickOk()
	if(g_CJSYJ_ChunLian_RightCount ~= g_CJSYJ_ChunLian_QuestionAnser[g_CJSYJ_ChunLian_CurQuestionType].AnswerCount) then
		PushDebugMessage("#{CJSX_180103_26}")
		return
	end
	PushDebugMessage("#{CJSX_180103_28}")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnQuestionOk" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892665 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end

