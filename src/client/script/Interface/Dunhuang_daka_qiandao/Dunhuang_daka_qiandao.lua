-- 敦煌打卡签到界面

local g_Dunhuang_daka_qiandao_Frame_UnifiedPosition

local g_MDDay = -1
local g_MDCount = -1
local g_MFReward = {} --1 3 5 7 10
local g_RewardDayCount = {1,3,5,7,10}

local g_RewardTextCtrl={}
local g_RewardButtonCtrl={}
local g_RewardBtnImgCtrl={}
local g_RewardRedtipCtrl={}
local g_RewardActionBtnCtrl={}

local g_QianDaoImgCtrl = {}
local g_RewardDummyItemList = {
{id=39920162,num=10},
{id=39921051,num=3},
{id=39922156,num=1},
{id=39920396,num=1},
{id=39920397,num=1},
{id=39922842,num=1}
}

function Dunhuang_daka_qiandao_PreLoad()
  this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function Dunhuang_daka_qiandao_OnLoad()
  g_Dunhuang_daka_qiandao_Frame_UnifiedPosition = Dunhuang_daka_qiandao_Frame:GetProperty("UnifiedPosition")
  g_RewardTextCtrl = {
  	Dunhuang_daka_qiandao_LeijiText1,
  	Dunhuang_daka_qiandao_LeijiText2,
  	Dunhuang_daka_qiandao_LeijiText3,
  	Dunhuang_daka_qiandao_LeijiText4,
  	Dunhuang_daka_qiandao_LeijiText5
  }
  g_RewardButtonCtrl = {
  	Dunhuang_daka_qiandao_qiandaoButton1,
  	Dunhuang_daka_qiandao_qiandaoButton2,
  	Dunhuang_daka_qiandao_qiandaoButton3,
  	Dunhuang_daka_qiandao_qiandaoButton4,
  	Dunhuang_daka_qiandao_qiandaoButton5
  }
  g_RewardBtnImgCtrl = {
  	Dunhuang_daka_qiandao_BasicItemReceived1,
  	Dunhuang_daka_qiandao_BasicItemReceived2,
  	Dunhuang_daka_qiandao_BasicItemReceived3,
  	Dunhuang_daka_qiandao_BasicItemReceived4,
  	Dunhuang_daka_qiandao_BasicItemReceived5
  }
  g_RewardRedtipCtrl = {
  	Dunhuang_daka_qiandao_Icon1_Tips,Dunhuang_daka_qiandao_Icon2_Tips,Dunhuang_daka_qiandao_Icon3_Tips,Dunhuang_daka_qiandao_Icon4_Tips,Dunhuang_daka_qiandao_Icon5_Tips
  }
  g_QianDaoImgCtrl = {
  	Dunhuang_daka_qiandao_Jindu1Image,Dunhuang_daka_qiandao_Jindu2Image,Dunhuang_daka_qiandao_Jindu3Image,
  	Dunhuang_daka_qiandao_Jindu4Image,Dunhuang_daka_qiandao_Jindu5Image,Dunhuang_daka_qiandao_Jindu6Image,
  	Dunhuang_daka_qiandao_Jindu7Image,Dunhuang_daka_qiandao_Jindu8Image,Dunhuang_daka_qiandao_Jindu9Image,
  	Dunhuang_daka_qiandao_Jindu10Image
  }
  g_RewardActionBtnCtrl = {
  	Dunhuang_daka_qiandao_Daoju1,Dunhuang_daka_qiandao_Daoju2,Dunhuang_daka_qiandao_Daoju3,Dunhuang_daka_qiandao_Daoju4,Dunhuang_daka_qiandao_Daoju5,Dunhuang_daka_qiandao_Daoju6
  }
end

function Dunhuang_daka_qiandao_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		Dunhuang_daka_qiandao_OnClosed()

	elseif (event == "ADJEST_UI_POS" ) then
		Dunhuang_daka_qiandao_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Dunhuang_daka_qiandao_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 19000001) then
		local showflag = Get_XParam_INT( 0 )
		if showflag == 1 then		--初始
			local MDData = Get_XParam_INT( 1 )
			local MFData = Get_XParam_INT( 2 )
			Dunhuan_daka_qiandao_SetMDMF(MDData, MFData)
			Dunhuang_daka_qiandao_Init()
		elseif showflag == 2 then
			local MDData = Get_XParam_INT( 1 )
			local MFData = Get_XParam_INT( 2 )
			Dunhuan_daka_qiandao_SetMDMF(MDData, MFData)
			Dunhuang_daka_qiandao_Update()
		elseif showflag == 0 then --关闭
			Dunhuang_daka_qiandao_OnClosed()
		end
	end
end

function Dunhuan_daka_qiandao_SetMDMF(MDData, MFData)
	g_MDDay = math.mod(MDData,100000000)
	g_MDCount = math.floor(MDData/100000000)

	g_MFReward[1] = math.mod(MFData,10)
	MFData = math.floor(MFData/10)
	g_MFReward[2] = math.mod(MFData,10)
	MFData = math.floor(MFData/10)
	g_MFReward[3] = math.mod(MFData,10)
	MFData = math.floor(MFData/10)
	g_MFReward[4] = math.mod(MFData,10)
	g_MFReward[5] = math.floor(MFData/10)
end

function Dunhuang_daka_qiandao_Init()
	Dunhuang_daka_qiandao_Update()
	local itemShowCount=table.getn(g_RewardActionBtnCtrl)
	for i = 1, itemShowCount do
		local theAction = DataPool:CreateActionItemForShow(g_RewardDummyItemList[i].id, g_RewardDummyItemList[i].num)
		if theAction:GetID() ~= 0 then
			g_RewardActionBtnCtrl[i]:SetActionItem(theAction:GetID());
		end
	end
	this:Show()
end

function Dunhuang_daka_qiandao_Update()
	local nServerTime = DataPool:GetServerDayTime()
	Dunhuang_daka_qiandao_numberText:SetText( ScriptGlobal_Format("#{DHDK_200723_85}", g_MDCount) )
	--按钮灰度和文字
	for i=1,5 do
		if g_MFReward[i] == 1 then
			--已领奖
			--按钮状态和文字
--			g_RewardButtonCtrl[i]:SetText("#{DHDK_200723_87}")
			g_RewardBtnImgCtrl[i]:Show()
			g_RewardButtonCtrl[i]:Hide()
			--红点隐藏
			g_RewardRedtipCtrl[i]:Hide()
			--进度文字
			g_RewardTextCtrl[i]:Hide()--SetText( ScriptGlobal_Format("#{DHDK_200723_88}", g_RewardDayCount[i]) )
		else
			--未领奖
			if g_MDCount >= g_RewardDayCount[i] then
				--可领奖
				--按钮状态和文字
--				g_RewardButtonCtrl[i]:SetText("#{DHDK_200723_86}")
				g_RewardBtnImgCtrl[i]:Hide()
				g_RewardButtonCtrl[i]:Show()
				--g_RewardButtonCtrl[i]:Enable()
				--红点显示
				g_RewardRedtipCtrl[i]:Show()
				--进度文字
				g_RewardTextCtrl[i]:Hide()--SetText( ScriptGlobal_Format("#{DHDK_200723_88}", g_RewardDayCount[i]) )
			else
				--不可领奖
				--按钮状态和文字
--				g_RewardButtonCtrl[i]:SetText("#{DHDK_200723_86}")
				g_RewardBtnImgCtrl[i]:Hide()
				g_RewardButtonCtrl[i]:Hide()
				--g_RewardButtonCtrl[i]:Disable()
				--红点隐藏
				g_RewardRedtipCtrl[i]:Hide()
				--进度文字
				g_RewardTextCtrl[i]:Show()
				g_RewardTextCtrl[i]:SetText( ScriptGlobal_Format("#{DHDK_200723_89}", g_RewardDayCount[i]) )
			end
		end
	end
	if g_MDCount>10 then
		for i=1,9 do
			g_QianDaoImgCtrl[i]:Hide()
		end
		g_QianDaoImgCtrl[10]:Show()
	else
		for i=1,10 do
			if g_MDCount==i then
				g_QianDaoImgCtrl[i]:Show()
			else
				g_QianDaoImgCtrl[i]:Hide()
			end
		end
	end

	if g_MDCount >= 14 then
		Dunhuang_daka_qiandao_dibuText:SetText("#{DHDK_200723_79}")
	else
		if g_MDDay == nServerTime then
			Dunhuang_daka_qiandao_dibuText:SetText("#{DHDK_200723_81}")
		else
			Dunhuang_daka_qiandao_dibuText:SetText("#{DHDK_200723_80}")
		end
	end
	
end

function Dunhuang_daka_qiandao_Start_Clicked()
	Dunhuang_daka_qiandao_OnClosed()
	AutoRuntoTargetExWithName(161, 280, 0, "龙丝语")
	PushDebugMessage("#{DHDK_200723_101}")
end

--领奖
function Dunhuang_daka_Reward_Clicked(nIdx)
	if nIdx>=1 and nIdx<=5 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetDaKaReward" )
			Set_XSCRIPT_ScriptID( 190000 )
			Set_XSCRIPT_Parameter( 0, nIdx )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end

end

function Dunhuang_daka_qiandao_OnClosed()
	g_MDDay = -1
	g_MDCount = -1
	g_MFReward = {} --1 3 5 7 10
	CloseWindow("Dunhuang_Preview", true)
	this:Hide()
end

function Dunhuang_daka_qiandao_On_ResetPos()
   Dunhuang_daka_qiandao_Frame:SetProperty("UnifiedPosition", g_Dunhuang_daka_qiandao_Frame_UnifiedPosition)
end

function Dunhuang_daka_qiandao_Help_Clicked()
	PushEvent("QUEST_HELP_MSG","#{DHDK_200723_78}")
end

function Dunhuang_daka_qiandao_PreviewClk()
	OpenWindow( "Dunhuang_Preview" );
end
