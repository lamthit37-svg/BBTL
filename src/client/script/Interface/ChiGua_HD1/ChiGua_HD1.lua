-- ChiGua_HD1.lua

local g_ChiGua_HD1_Frame_UnifiedPosition;

local g_CurScroce =0;

local g_NpcId =-1;

local g_nCount = 0

--0:未开时；1：开始前倒计时；2：进行中；3结束
local g_State = 0


local objCared = -1

local g_ButtonLastTime = 0;
local g_ButtonCDTime = 0.1

local g_WatermelonType1 =1
local g_WatermelonType2 =1


local g_UseSkillOK = 0

local  ChiGua_HD1_Skill_BUTTONS = {}

local ChiGua_HD1_Skill_INDEX ={}

function ChiGua_HD1_PreLoad()
	this : RegisterEvent( "UI_COMMAND",true )
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SCENE_TRANSED",true);
end

function ChiGua_HD1_OnLoad()
	ChiGua_HD1_Clear()
	g_ChiGua_HD1_Frame_UnifiedPosition=ChiGua_HD1_FrameNULL:GetProperty("UnifiedPosition");
	ChiGua_HD1_Skill_BUTTONS[1] = ChiGua_HD1_SkillFrame_Skill1
	ChiGua_HD1_Skill_BUTTONS[2] = ChiGua_HD1_SkillFrame_Skill2
	ChiGua_HD1_Skill_BUTTONS[3] = ChiGua_HD1_SkillFrame_Skill3
	ChiGua_HD1_Skill_BUTTONS[4] = ChiGua_HD1_SkillFrame_Skill4
end

function ChiGua_HD1_OnEvent(event)


	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928551 then	-- 打开界面
		local nFlag = Get_XParam_INT( 0 );

		if nFlag == 0 then
		--	if this:IsVisible() then
				ChiGua_HD1_Close()
				return
		--	end
		end
		g_NpcId = Get_XParam_INT( 1 );

		g_WatermelonType1 = Get_XParam_INT( 2 );
		g_WatermelonType2 = Get_XParam_INT( 3 );

--PushDebugMessage("g_WatermelonType1="..g_WatermelonType1.."g_WatermelonType2="..g_WatermelonType2.."g_WatermelonType3="..g_WatermelonType3.."g_WatermelonType4="..g_WatermelonType4)
		ChiGua_HD1_Open()

		return
	end

	if event == "SCENE_TRANSED" then
		if this:IsVisible()  then
			ChiGua_HD1_Close()
		end
		return
	end


	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928552 then	-- 使用技能吃西瓜返回
		if this : IsVisible() then
			local nScore = Get_XParam_INT( 0 );
			g_UseSkillOK = Get_XParam_INT( 1 );
			g_WatermelonType1 = Get_XParam_INT( 2 );
			g_WatermelonType2 = Get_XParam_INT( 3 );

			g_CurScroce = nScore
--PushDebugMessage("g_WatermelonType1="..g_WatermelonType1.."g_WatermelonType2="..g_WatermelonType2.."g_WatermelonType3="..g_WatermelonType3.."g_WatermelonType4="..g_WatermelonType4)
--PushDebugMessage("g_UseSkillOK="..g_UseSkillOK)
			ChiGua_HD1_Refresh_Score(nScore)

		end
		return
	end

	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928553 then	-- 结束
		if this : IsVisible()  then
			local isSuccess = Get_XParam_INT( 0 );
			local sumcount = Get_XParam_INT( 1 );
			local isFinish = Get_XParam_INT( 2 );
		--	PushDebugMessage("isFinish="..isFinish)
			ChiGua_HD1_Finish(isSuccess,sumcount,isFinish)
		end
		return
	end

	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928554 then	-- 关闭界面
		local nFlag = Get_XParam_INT( 0 );

		if nFlag == 0 then

			ChiGua_HD1_Close()
			return

		end
	end


	if (event == "ADJEST_UI_POS" ) then
		ChiGua_HD1_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ChiGua_HD1_Frame_On_ResetPos()
	end


end

function ChiGua_HD1_Open()
	--开启计时器
	KillTimer("ChiGua_HD1_TimerProc()")
	SetTimer("ChiGua_HD1","ChiGua_HD1_TimerProc()", 1000)
	g_nCount =0

--当前积分
--	ChiGua_HD1_Score:SetText("#{XGDS_180608_10}")
	ChiGua_HD1_Score_picture1:SetProperty("Image", "set:Sign image:Signorange_"..0)
	ChiGua_HD1_Score_picture2:SetProperty("Image", "set:Sign image:Signorange_"..0)
	ChiGua_HD1_Score_picture3:SetProperty("Image", "set:Sign image:Signorange_"..0)
--动画相关设置，显示开始倒计时
	ChiGua_HD1_Times_Begin:Show()
	ChiGua_HD1_Times_Begin:Play(true)
	ChiGua_HD1_Times_Finish:Hide()
--	ChiGua_HD1_Arrow:Show()
	ChiGua_HD1_FinishTextLace:Hide()
	ChiGua_HD1_Mistake_Animate:Hide()
	ChiGua_HD1_Man_Animate:Hide()
	ChiGua_HD1_Man_Dizzy:Hide()

	ChiGua_HD1_Watermelon1_Animate:Hide()
	ChiGua_HD1_Watermelon2_Animate:Hide()

--设置当前状态为开始倒计时
	g_State = 1
	ChiGua_HD1_CountDownText:Show()
	ChiGua_HD1_CountDownText:SetText("#{XGDS_180608_11}")
	ChiGua_HD1_ExplainLace:Show()
	ChiGua_HD1_Explain:Show()
	ChiGua_HD1_Explain:SetText("#{XGDS_180608_12}")
--西瓜显示
	ChiGua_HD1_Watermelon1:Show()
	ChiGua_HD1_Watermelon2:Show()

	ChiGua_HD1_Watermelon1:SetProperty("Image", "set:ChiGua image:ChiGua_Watermelon"..g_WatermelonType1)
	ChiGua_HD1_Watermelon2:SetProperty("Image", "set:ChiGua image:ChiGua_Watermelon"..g_WatermelonType2)

	local AcceArryEx = 10   --自定义快捷键数组中前11个元素不允许玩家自定义
--使用技能提示文字
	ChiGua_HD1_Table_Text1:Show()
	ChiGua_HD1_Table_Text2:Show()
	local  nStr = SystemSetup:GetAcceTip(g_WatermelonType1 + AcceArryEx);
	local nStr1 = ScriptGlobal_Format("#{XGDS_180608_120}", nStr)
	if nStr=="" then
		ChiGua_HD1_Table_Text1:SetText("#{XGDS_180608_128}")
	else
		ChiGua_HD1_Table_Text1:SetText(nStr1)
	end
	ChiGua_HD1_Watermelon1_Text:SetText("#e000001#W"..nStr)
	nStr = SystemSetup:GetAcceTip(g_WatermelonType2 + AcceArryEx);
	ChiGua_HD1_Watermelon2_Text:SetText("#e000001#W"..nStr)
--技能显示

	ChiGua_HD1_SkillFrame:Show()
	ChiGua_HD1_SkillFrameBK:Show()


	for i=1,4 do
		local act = Transfiguration:EnumTransfigeAction(tonumber(i-1));
		if act and act:GetID() ~= 0 then
			ChiGua_HD1_Skill_BUTTONS[i]:Show()
			ChiGua_HD1_Skill_BUTTONS[i]:SetActionItem(act:GetID());
			ChiGua_HD1_Skill_INDEX[i] = theAction:GetID();

			local  str = SystemSetup:GetAcceTip(i + AcceArryEx);
			local tip = string.format( "TopRight %s", str )
			ChiGua_HD1_Skill_BUTTONS[i]:SetProperty("CornerChar", tip)
		end
	end
--瓜皮篓子
	ChiGua_HD1_TrashEmpty:Show()
	ChiGua_HD1_TrashHalf:Hide()
	ChiGua_HD1_TrashFull:Hide()

	this:Show()
end

function ChiGua_HD1_TimerProc()
	--计时器每秒一次，更新状态
	g_nCount = g_nCount+1
	if g_nCount == 3 and g_State == 1 then --开始倒计时结束
		ChiGua_HD1_Times_Begin:Hide()
		ChiGua_HD1_Times_Begin:Play(false)
		g_State =2
		local Str = ScriptGlobal_Format("#{XGDS_180608_13}", 30)
		ChiGua_HD1_CountDownText:Show()
		ChiGua_HD1_CountDownText:SetText(Str)

	end
	if g_State == 2 then --进行中
		local nLeftTime = 33-g_nCount
		if nLeftTime < 0 then
			nLeftTime = 0
		end
		local Str = ScriptGlobal_Format("#{XGDS_180608_13}", nLeftTime)
		ChiGua_HD1_CountDownText:SetText(Str)
		ChiGua_HD1_Explain:SetText("#{XGDS_180608_14}")
	end
	if g_nCount >= 33 and g_State == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnSingleFinish" )
			Set_XSCRIPT_ScriptID( 892855 )
			Set_XSCRIPT_Parameter( 0, g_NpcId )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if g_nCount >= 7 and g_State == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnSingleFinish" )
			Set_XSCRIPT_ScriptID( 892855 )
			Set_XSCRIPT_Parameter( 0, g_NpcId )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if g_nCount >= 50  then
		ChiGua_HD1_Close()
	end
end

 --  -1无效，0未进榜，1 进榜，2已经领过第一名奖励
function ChiGua_HD1_Finish(isSuccess,sumcount,isFinish)
--	PushDebugMessage("isFinish="..isFinish)
	g_State = 3
	g_nCount = 0
--	ChiGua_HD1_Arrow:Hide()
	ChiGua_HD1_Times_Finish:Show()
	ChiGua_HD1_Times_Finish:Play(true)
	ChiGua_HD1_FinishTextLace:Show()
	ChiGua_HD1_ExplainLace:Hide()
	ChiGua_HD1_Explain:Hide()

	ChiGua_HD1_Watermelon1:Hide()
	ChiGua_HD1_Watermelon2:Hide()

	ChiGua_HD1_Watermelon1_Animate:Show()
	ChiGua_HD1_Watermelon1_Animate:Play(true)
	ChiGua_HD1_Watermelon2_Animate:Show()
	ChiGua_HD1_Watermelon2_Animate:Play(true)

	ChiGua_HD1_SkillFrame:Hide()
	ChiGua_HD1_SkillFrameBK:Hide()

	ChiGua_HD1_Table_Text1:Hide()
	ChiGua_HD1_Table_Text2:Hide()

	local Num1 = math.floor(sumcount/100)
	local temp = math.mod(sumcount, 100)
	local Num2 = math.floor(temp/10)
	local Num3 = math.mod(sumcount, 10)

	ChiGua_HD1_Score_picture1:SetProperty("Image", "set:Sign image:Signorange_"..Num1)
	ChiGua_HD1_Score_picture2:SetProperty("Image", "set:Sign image:Signorange_"..Num2)
	ChiGua_HD1_Score_picture3:SetProperty("Image", "set:Sign image:Signorange_"..Num3)

	--瓜皮篓子
	if sumcount < 20 then
		ChiGua_HD1_TrashEmpty:Show()
		ChiGua_HD1_TrashHalf:Hide()
		ChiGua_HD1_TrashFull:Hide()
	end
	if sumcount >= 20 and sumcount <50 then
		ChiGua_HD1_TrashEmpty:Show()
		ChiGua_HD1_TrashHalf:Show()
		ChiGua_HD1_TrashFull:Hide()
	end

	if sumcount >= 50 and sumcount <120 then
		ChiGua_HD1_TrashEmpty:Show()
		ChiGua_HD1_TrashHalf:Hide()
		ChiGua_HD1_TrashFull:Show()
	end

	local Str = ""
	if isSuccess == -1 then --无效
		Str= "#{XGDS_180608_20}"
		PushDebugMessage("#{XGDS_180608_66}")
	end


	if isSuccess == 0 then --没有进榜
		 Str = ScriptGlobal_Format("#{XGDS_180608_19}", sumcount)

		PushDebugMessage("#{XGDS_180608_66}")
	end

	if isSuccess == 1 then --进榜
		 Str = ScriptGlobal_Format("#{XGDS_180608_17}", sumcount)

		PushDebugMessage("#{XGDS_180608_65}")
	end

	if isSuccess == 2 then --得过第一名

		Str= "#{XGDS_180608_15}"
		PushDebugMessage("#{XGDS_180608_64}")
	end

	if isSuccess == 3 then --得过第一名又刷新了历史最高
		Str= "#{XGDS_180608_16}"

		PushDebugMessage("#{XGDS_180608_63}")
	end

	if isSuccess == 4 then --进榜，又刷新了历史最高
		 Str = ScriptGlobal_Format("#{XGDS_180608_18}", sumcount)

		PushDebugMessage("#{XGDS_180608_63}")
	end

	if isFinish == 1 then
		PushDebugMessage("#{XGDS_180608_22}")
		Str = Str.."#r".."#{XGDS_180608_21}"
	end
--	PushDebugMessage("str="..Str)
	ChiGua_HD1_FinishText:SetText(Str)
	ChiGua_HD1_CountDownText:SetText("#{XGDS_180608_23}")

end

function ChiGua_HD1_Refresh_Score(nScore)
	local Num1 = math.floor(nScore/100)
	local temp = math.mod(nScore, 100)
	local Num2 = math.floor(temp/10)
	local Num3 = math.mod(nScore, 10)

	ChiGua_HD1_Score_picture1:SetProperty("Image", "set:Sign image:Signorange_"..Num1)
	ChiGua_HD1_Score_picture2:SetProperty("Image", "set:Sign image:Signorange_"..Num2)
	ChiGua_HD1_Score_picture3:SetProperty("Image", "set:Sign image:Signorange_"..Num3)

	--西瓜显示
	ChiGua_HD1_Watermelon1:SetProperty("Image", "set:ChiGua image:ChiGua_Watermelon"..g_WatermelonType1)
	ChiGua_HD1_Watermelon2:SetProperty("Image", "set:ChiGua image:ChiGua_Watermelon"..g_WatermelonType2)

	local AcceArryEx =10
	local  nStr = SystemSetup:GetAcceTip(g_WatermelonType1 + AcceArryEx);
	local nStr1 = ScriptGlobal_Format("#{XGDS_180608_120}", nStr)
	if nStr=="" then
		ChiGua_HD1_Table_Text1:SetText("#{XGDS_180608_128}")
	else
		ChiGua_HD1_Table_Text1:SetText(nStr1)
	end
	ChiGua_HD1_Watermelon1_Text:SetText("#e000001#W"..nStr)
	nStr = SystemSetup:GetAcceTip(g_WatermelonType2 + AcceArryEx);
	ChiGua_HD1_Watermelon2_Text:SetText("#e000001#W"..nStr)

	--瓜皮篓子
	if nScore < 20 then
		ChiGua_HD1_TrashEmpty:Show()
		ChiGua_HD1_TrashHalf:Hide()
		ChiGua_HD1_TrashFull:Hide()
	end
	if nScore >= 20 and nScore <50 then
		ChiGua_HD1_TrashEmpty:Show()
		ChiGua_HD1_TrashHalf:Show()
		ChiGua_HD1_TrashFull:Hide()
	end

	if nScore >= 50 and nScore <120 then
		ChiGua_HD1_TrashEmpty:Show()
		ChiGua_HD1_TrashHalf:Hide()
		ChiGua_HD1_TrashFull:Show()
	end


	if g_UseSkillOK == 0 then
		ChiGua_HD1_Mistake_Animate:Show()
		ChiGua_HD1_Mistake_Animate:Play(true)
		ChiGua_HD1_DizzyHand_Animate:Show()
		ChiGua_HD1_DizzyHand_Animate:Play(true)
		ChiGua_HD1_Man_Animate:Hide()
		ChiGua_HD1_Man_Dizzy:Show()
		ChiGua_HD1_Man_Dizzy:Play(true)
	elseif g_UseSkillOK == 1 then
		ChiGua_HD1_Man_Animate:Show()
		ChiGua_HD1_Man_Animate:Play(true)
		ChiGua_HD1_Chair_Animate:Show()
		ChiGua_HD1_Chair_Animate:Play(true)
		ChiGua_HD1_ManHand_Animate:Show()
		ChiGua_HD1_ManHand_Animate:Play(true)
		ChiGua_HD1_Mistake_Animate:Hide()
		ChiGua_HD1_Man_Dizzy:Hide()
	end
end


function ChiGua_HD1_Clear()
	g_CurScroce =0;
	g_NpcId =-1;
	g_nCount = 0
end


function ChiGua_HD1_Close()
	KillTimer("ChiGua_HD1_TimerProc()")
	this:Hide()
end

function ChiGua_HD1_Frame_On_ResetPos()
  ChiGua_HD1_FrameNULL:SetProperty("UnifiedPosition", g_ChiGua_HD1_Frame_UnifiedPosition);
end

--=========================================================
--开始关心NPC
--=========================================================
function ChiGua_HD1_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "ChiGua_HD1");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "ChiGua_HD1")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ChiGua_HD1_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "ChiGua_HD1");
		objCared = -1;
	end
end

function ChiGua_HD1_Skill_Clicked(nIndex)
	local isCanDo = DataPool:IsCanDoAction()
	if isCanDo == true then
		ChiGua_HD1_Skill_BUTTONS[nIndex]:DoAction();
	end
end
