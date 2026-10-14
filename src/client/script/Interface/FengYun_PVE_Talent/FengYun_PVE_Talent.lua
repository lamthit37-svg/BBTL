-- 风云联动 天赋技能展示UI
local FengYun_PVE_Talent_SvrScriptId = 335921
local FengYun_PVE_Talent_LevelLimit = 60
local FengYun_PVE_Talent_LastTalentOpTime = 0
local FengYun_PVE_Talent_MaxPage = 4
local FengYun_PVE_Talent_CurPage = 0
local FengYun_PVE_Talent_CurSelectTalentId = 0
-- 默认位置
local FengYun_PVE_Talent_UnifiedPosition = nil
-- 天赋展示控件列表
local FengYun_PVE_Talent_TalentCtrlList = nil
-- 当前页展示的天赋id列表
local FengYun_PVE_Talent_TalentIdList = nil



function FengYun_PVE_Talent_PreLoad()
	this:RegisterEvent("FYPVE_TRYTOOPENTALENT", true)
	this:RegisterEvent("FYPVE_TALENTOPEN", true)
	this:RegisterEvent("FYPVE_UPDATETALENT", true)
	this:RegisterEvent("FYPVE_UPDATEBASEDATA", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Talent_PreLoad()

function FengYun_PVE_Talent_OnEvent(event)
	if (event == "FYPVE_TRYTOOPENTALENT") then
		AskServerTimeAgain()
		FengYun_PVE_Talent_InitCtrl()
	elseif (event == "FYPVE_TALENTOPEN") then
		FengYun_PVE_Talent_InitCtrl()
		FengYun_PVE_Talent_InitPageInfo()
		FengYun_PVE_Talent_UpdateTalentInfo(0)
		FengYun_PVE_Talent_Show()
	elseif (event == "FYPVE_UPDATETALENT") then
		if (this:IsVisible()) then
			FengYun_PVE_Talent_InitCtrl()
			FengYun_PVE_Talent_InitPageInfo()
			FengYun_PVE_Talent_UpdateTalentInfo(0)
		end
	elseif (event == "FYPVE_UPDATEBASEDATA") then
		if (this:IsVisible()) then
			FengYun_PVE_Talent_InitCtrl()
			FengYun_PVE_Talent_InitPageInfo()
			FengYun_PVE_Talent_UpdateTalentInfo(0)
		end
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_PVE_Talent_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Talent_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Talent_UnifiedPos()
	end
end -- end func FengYun_PVE_Talent_OnEvent()

function FengYun_PVE_Talent_OnLoad()
	FengYun_PVE_Talent_UnifiedPosition = FengYun_PVE_Talent_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Talent_OnLoad()

-- 界面默认位置
function FengYun_PVE_Talent_UnifiedPos()
	if (FengYun_PVE_Talent_UnifiedPosition ~= nil) then
		FengYun_PVE_Talent_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Talent_UnifiedPosition)
	end
end -- end func FengYun_PVE_Talent_UnifiedPos()

function FengYun_PVE_Talent_Show()
	FengYun_PVE_Talent_LastTalentOpTime = 0
    this:Show()
end -- end func FengYun_PVE_Talent_Show()

function FengYun_PVE_Talent_Hide()
    this:Hide()
end -- end func FengYun_PVE_Talent_Hide()

--*************************************************************************************************
--
--*************************************************************************************************

-- 关闭按钮点击事件
function FengYun_PVE_Talent_OnHiden()
	FengYun_PVE_Talent_Hide()
end -- end func FengYun_PVE_Talent_OnHiden()

-- 上一页按钮点击事件
function FengYun_PVE_Talent_Item_PreClick()
	if (FengYun_PVE_Talent_CurPage <= 1) then
		return
	end

	FengYun_PVE_Talent_CurPage = FengYun_PVE_Talent_CurPage - 1
	if (FengYun_PVE_Talent_CurPage <= 0) then
		FengYun_PVE_Talent_CurPage = 1
	elseif (FengYun_PVE_Talent_CurPage > FengYun_PVE_Talent_MaxPage) then
		FengYun_PVE_Talent_CurPage = FengYun_PVE_Talent_MaxPage
	end

	FengYun_PVE_Talent_UpdateTalentInfo(1)
end -- end func FengYun_PVE_Talent_Item_PreClick()

-- 下一页按钮点击事件
function FengYun_PVE_Talent_Item_NextClick()
	if (FengYun_PVE_Talent_CurPage >= FengYun_PVE_Talent_MaxPage) then
		return
	end

	FengYun_PVE_Talent_CurPage = FengYun_PVE_Talent_CurPage + 1
	if (FengYun_PVE_Talent_CurPage <= 0) then
		FengYun_PVE_Talent_CurPage = 1
	elseif (FengYun_PVE_Talent_CurPage > FengYun_PVE_Talent_MaxPage) then
		FengYun_PVE_Talent_CurPage = FengYun_PVE_Talent_MaxPage
	end

	FengYun_PVE_Talent_UpdateTalentInfo(1)
end -- end func FengYun_PVE_Talent_Item_NextClick()

-- 激活按钮事件
function FengYun_PVE_Talent_Submit_OnClick()
	-- 是否选中要激活的天赋
	if (FengYun_PVE_Talent_CurSelectTalentId <= 0) then
		-- 未选择要激活的天赋
		PushDebugMessage("#{FYPVE_260108_123}")
		return
	end

	-- 操作CD
	local curTime = os.time()
	if (curTime <= FengYun_PVE_Talent_LastTalentOpTime) then
		return
	end
	FengYun_PVE_Talent_LastTalentOpTime = curTime

	-- 活动时间
	local isInAct, actStage = FengYun_PVE_Talent_GetActStage()
	if (isInAct < 0) then
		-- 不在活动时间
		PushDebugMessage("#{FYPVE_260108_16}")
		return
	end

	-- 等级
	local curLevel = Player:GetLevel()
	if (curLevel < FengYun_PVE_Talent_LevelLimit) then
		-- 等级不够
		PushDebugMessage("#{FYPVE_260108_17}")
		return
	end

	-- 选中的天赋是否已激活
	local curTalentId, curTalentType, curTalentState = FYPVE:GetTalentDataByIndex(FengYun_PVE_Talent_CurSelectTalentId-1)
	if (curTalentId == nil) then
		-- 没有这个天赋 按说不应该这样的
		PushDebugMessage("#{FYPVE_260108_121}")
		return
	end
	if (curTalentState > 0) then
		-- 该天赋已激活
		PushDebugMessage("#{FYPVE_260108_33}")
		return
	end

	local talentId, talentLevel, talentLine, talentPre, talentPoint, talentActStage, _ = FYPVE:GetTableTalentData(FengYun_PVE_Talent_CurSelectTalentId)
	if (talentId == nil or talentId < 0) then
		-- 天赋表里没有读到这个天赋的信息 按说不应该这样的
		PushDebugMessage("#{FYPVE_260108_121}")
		return
	end
	local preTalentId, preTalentType, preTalentStage = FYPVE:GetTalentDataByIndex(FengYun_PVE_Talent_CurSelectTalentId-1)
	if (preTalentId ~= nil and preTalentId > 0) then
		if (preTalentStage ~= nil and preTalentStage <= 0) then
			-- 有前置天赋 并且前置天赋未激活
			PushDebugMessage("#{FYPVE_260108_119}")
			return
		end
	end

	if (talentActStage >= 2 and talentActStage > actStage) then
		-- 当前活动阶段不可激活该技能
		PushDebugMessage("#{FYPVE_260108_35}")
		return
	end

	local availablePoint = FYPVE:GetAvailableActPoint()
	if (availablePoint < talentPoint) then
		-- 点数不够
		PushDebugMessage("#{FYPVE_260108_120}")
		return
	end

	-- 二次确认
	--PushEvent("UI_COMMAND", 33592101)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CCallBack_ActivateTalent")
		Set_XSCRIPT_ScriptID(FengYun_PVE_Talent_SvrScriptId)
		Set_XSCRIPT_Parameter(0, FengYun_PVE_Talent_CurSelectTalentId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func FengYun_PVE_Talent_Submit_OnClick()

-- 重置按钮事件
function FengYun_PVE_Talent_Reset_OnClick()
	-- 操作CD
	local curTime = os.time()
	if (curTime <= FengYun_PVE_Talent_LastTalentOpTime) then
		return
	end
	FengYun_PVE_Talent_LastTalentOpTime = curTime

	-- 活动时间
	local isInAct, actStage = FengYun_PVE_Talent_GetActStage()
	if (isInAct < 0) then
		-- 不在活动时间
		PushDebugMessage("#{FYPVE_260108_16}")
		return
	end

	-- 等级
	local curLevel = Player:GetLevel()
	if (curLevel < FengYun_PVE_Talent_LevelLimit) then
		-- 等级不够
		PushDebugMessage("#{FYPVE_260108_17}")
		return
	end

	-- 二次确认
	--PushEvent("UI_COMMAND", 33592102)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CCallBack_ResetTalent")
		Set_XSCRIPT_ScriptID(FengYun_PVE_Talent_SvrScriptId)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func FengYun_PVE_Talent_Reset_OnClick()

-- 第一列图标点击事件
function FengYun_PVE_Talent_Item_Clicked(idx)
	FengYun_PVE_Talent_TalentClickEvent(idx)
end -- end func FengYun_PVE_Talent_Item_Clicked()

-- 天赋图标点击事件逻辑
function FengYun_PVE_Talent_TalentClickEvent(ctrlIdx)
	local talentNum = FYPVE:GetTableTalentNum()
	if (ctrlIdx <= 0 or ctrlIdx > talentNum) then
		return
	end
	if (FengYun_PVE_Talent_TalentCtrlList == nil) then
		FengYun_PVE_Talent_InitCtrl()
	end

	FengYun_PVE_Talent_CurSelectTalentId = 0

	local frameUI = FengYun_PVE_Talent_TalentCtrlList[FengYun_PVE_Talent_CurPage]
	if frameUI == nil then
		return
	end

	-- 直接选中得了
	FengYun_PVE_Talent_CurSelectTalentId = ctrlIdx

	for index, talentCtrl in (frameUI.item or {}) do
		talentCtrl.ctrl:SetPushed(0)
		talentCtrl.checked:Hide()
	end

	local talentCtrl = frameUI.item[FengYun_PVE_Talent_CurSelectTalentId]
	if talentCtrl ~= nil then
		local curTalentId, curTalentType, curTalentState = FYPVE:GetTalentDataByIndex(FengYun_PVE_Talent_CurSelectTalentId-1)
		if (curTalentState ~= nil and curTalentState > 0) then
			talentCtrl.checked:Hide()
		else
			talentCtrl.checked:Show()
		end
	end
end -- end func FengYun_PVE_Talent_TalentClickEvent()

--*************************************************************************************************
--
--*************************************************************************************************

function FengYun_PVE_Talent_InitCtrl()
	local frame = "FengYun_PVE_Talent"
	local makeGroup = function(prefix,ctrl,activated,lock,checked,name,need,needbg,line,tail)
		return {
			["ctrl"] = _G[frame..prefix..ctrl],
			["activated"] = _G[frame..prefix..activated],
			["lock"] = _G[frame..prefix..lock],
			["checked"] = _G[frame..prefix..checked],
			["name"] = _G[frame..prefix..name],
			["need"] = _G[frame..prefix..need],
			["needbg"] = _G[frame..prefix..needbg],
			["line"] = line,
			["tail"] = tail,
		}
	end

	if (FengYun_PVE_Talent_TalentCtrlList == nil) then
		FengYun_PVE_Talent_TalentCtrlList = {}
		FengYun_PVE_Talent_TalentCtrlList[1] =
		{
			-- 各种UI
			item = 
			{
				[1]=makeGroup("_ItemPageFrame1_MainItemPage1","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",0,0),
				[2]=makeGroup("_ItemPageFrame1_MainItemPage2","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",1,0),
				[3]=makeGroup("_ItemPageFrame1_BranchItemPage1","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",2,0),
				[4]=makeGroup("_ItemPageFrame1_MainItemPage3","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",3,0),
				[5]=makeGroup("_ItemPageFrame1_BranchItemPage2","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",4,0),
				[6]=makeGroup("_ItemPageFrame1_MainItemPage4","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",5,0),
				[7]=makeGroup("_ItemPageFrame1_BranchItemPage3","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",6,0),
				[8]=makeGroup("_ItemPageFrame1_MainItemPage5","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",7,0),
				[9]=makeGroup("_ItemPageFrame1_BranchItemPage4","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",8,0),
				[10]=makeGroup("_ItemPageFrame1_MainItemPage6","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",9,13),
				[11]=makeGroup("_ItemPageFrame1_BranchItemPage5","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",10,0),
				[12]=makeGroup("_ItemPageFrame1_BranchItemPage5","_Item2","_ItemMask2","_ItemLock2","_ItemCheck2","_ItemText2","_ItemPoint2","_ItemPointIcon2",11,0),
			},
			-- 连线
			line = 
			{
				[1] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK1_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK1_3},
				[2] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK1_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK1_2},
				[3] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK2_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK2_3},
				[4] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK2_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK2_2},
				[5] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK3_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK3_3},
				[6] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK3_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK3_2},
				[7] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK4_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK4_3},
				[8] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK4_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK4_2},
				[9] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK5_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK5_4},
				[10] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK5_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK5_2},
				[11] = {FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK5_1,FengYun_PVE_Talent_ItemPageFrame1_BranchItemLineBK5_3},
			},
			-- 尾线,其中有一个控件是下个frame头部
			tailline = {FengYun_PVE_Talent_ItemPageFrame1_ProgressR,FengYun_PVE_Talent_ItemPageFrame2_ProgressL},
			-- 大框体
			frame = FengYun_PVE_Talent_ItemPageFrame1,
		}
		FengYun_PVE_Talent_TalentCtrlList[2] =
		{
			-- 各种UI
			item = 
			{
				[13]=makeGroup("_ItemPageFrame2_MainItemPage1","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",1,0),
				[14]=makeGroup("_ItemPageFrame2_MainItemPage2","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",2,0),
				[15]=makeGroup("_ItemPageFrame2_MainItemPage3","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",3,0),
				[16]=makeGroup("_ItemPageFrame2_BranchItemPage2","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",4,0),
				[17]=makeGroup("_ItemPageFrame2_MainItemPage4","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",5,0),
				[18]=makeGroup("_ItemPageFrame2_MainItemPage5","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",6,0),
				[19]=makeGroup("_ItemPageFrame2_BranchItemPage4","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",7,0),
				[20]=makeGroup("_ItemPageFrame2_MainItemPage6","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",8,21),
				-- 21来自第三分页
				[21]=makeGroup("_ItemPageFrame3_MainItemPage1","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",9,0),
				[22]=makeGroup("_ItemPageFrame2_BranchItemPage6","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",10,0),
			},
			-- 连线
			line = 
			{
				[1] = {FengYun_PVE_Talent_ItemPageFrame2_ProgressL},
				[2] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLineBK1_1},
				[3] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine2_1,FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine2_3},
				[4] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine2_1,FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine2_2},
				[5] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine3_1},
				[6] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine4_1,FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine4_3},
				[7] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine4_1,FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine4_2},
				[8] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine5_1},
				[9] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine6_1,FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine6_3},
				[10] = {FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine6_1,FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine6_2},
			},
			-- 尾线
			tailline = 
			{
				FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine6_1,
				FengYun_PVE_Talent_ItemPageFrame2_BranchItemLine6_3,
				FengYun_PVE_Talent_ItemPageFrame2_ProgressR,
				FengYun_PVE_Talent_ItemPageFrame3_ProgressL,
			},
			-- 大框体
			frame = FengYun_PVE_Talent_ItemPageFrame2,
		}
		FengYun_PVE_Talent_TalentCtrlList[3] =
		{
			-- 各种UI
			item = 
			{
				[21]=makeGroup("_ItemPageFrame3_MainItemPage1","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",1,0),
				[23]=makeGroup("_ItemPageFrame3_MainItemPage2","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",2,0),
				[24]=makeGroup("_ItemPageFrame3_MainItemPage3","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",3,0),
				[25]=makeGroup("_ItemPageFrame3_BranchItemPage2","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",4,0),
				[26]=makeGroup("_ItemPageFrame3_MainItemPage4","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",5,0),
				[27]=makeGroup("_ItemPageFrame3_MainItemPage5","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",6,0),
				[28]=makeGroup("_ItemPageFrame3_BranchItemPage4","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",7,0),
				[29]=makeGroup("_ItemPageFrame3_MainItemPage6","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",8,30),
			},
			-- 连线
			line = 
			{
				[1] = {FengYun_PVE_Talent_ItemPageFrame3_ProgressL},
				[2] = {FengYun_PVE_Talent_ItemPageFrame3_BranchItemLineBK1_1},
				[3] = {FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine2_1,FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine2_3},
				[4] = {FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine2_1,FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine2_2},
				[5] = {FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine3_1},
				[6] = {FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine4_1,FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine4_3},
				[7] = {FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine4_1,FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine4_2},
				[8] = {FengYun_PVE_Talent_ItemPageFrame3_BranchItemLine5_1},
			},
			-- 尾线
			tailline = 
			{
				FengYun_PVE_Talent_ItemPageFrame3_ProgressR,FengYun_PVE_Talent_ItemPageFrame4_ProgressL,
			},
			-- 大框体
			frame = FengYun_PVE_Talent_ItemPageFrame3,
		}
		FengYun_PVE_Talent_TalentCtrlList[4] =
		{
			-- 各种UI
			item = 
			{
				[30]=makeGroup("_ItemPageFrame4_MainItemPage1","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",1,0),
				[31]=makeGroup("_ItemPageFrame4_MainItemPage2","_Item1","_ItemMask1","_ItemLock1","_ItemCheck1","_ItemText1","_ItemPoint1","_ItemPointIcon1",2,0),
			},
			-- 连线
			line = 
			{
				[1] = {FengYun_PVE_Talent_ItemPageFrame4_ProgressL},
				[2] = {FengYun_PVE_Talent_ItemPageFrame4_BranchItemLineBK1_1},
			},
			-- 尾线
			tailline = {},
			-- 大框体
			frame = FengYun_PVE_Talent_ItemPageFrame4,
		}
	end
end -- end func FengYun_PVE_Talent_InitCtrl()

function FengYun_PVE_Talent_GetActStage()
	local beginDate1 = nil
	local endDate1 = nil
	local beginDate2 = nil
	local endDate2 = nil
	beginDate1, endDate1, beginDate2, endDate2 = FYPVE:GetActTime()
	if (beginDate1 == nil) then
		return -10, -10
	end

	local inAct = -1
	local curStage = -1
	local curDay = tonumber(DataPool:GetServerDayTime())
	if (curDay < beginDate1) then
		-- 活动未开始
		inAct = -1
		curStage = -1
	elseif (curDay >= beginDate1 and curDay <= endDate1) then
		-- 活动第一阶段
		inAct = 1
		curStage = 1
	elseif (curDay > endDate1 and curDay < beginDate2) then
		-- 第一阶段和第二阶段之间
		inAct = 1
		curStage = 0
	elseif (curDay >= beginDate2 and curDay <= endDate2) then
		-- 活动第二阶段
		inAct = 1
		curStage = 2
	else
		-- 活动已结束
		inAct = -2
		curStage = -1
	end

	return inAct, curStage
end -- end func FengYun_PVE_Talent_GetActStage()

function FengYun_PVE_Talent_InitPageInfo()
	if (FengYun_PVE_Talent_CurPage <= 0) then
		FengYun_PVE_Talent_CurPage = 1
	elseif (FengYun_PVE_Talent_CurPage > FengYun_PVE_Talent_MaxPage) then
		FengYun_PVE_Talent_CurPage = FengYun_PVE_Talent_MaxPage
	end
end -- end func FengYun_PVE_Talent_InitPageInfo()

-- 天赋信息
function FengYun_PVE_Talent_UpdateTalentInfo(pageChanged)
	if (FengYun_PVE_Talent_CurPage <= 0) then
		return
	end

	if (pageChanged ~= nil and pageChanged > 0) then
		FengYun_PVE_Talent_CurSelectTalentId = 0
	end

	-- 设置翻页按钮状态
	FengYun_PVE_Talent_Item_LeftArrow:Enable()
	FengYun_PVE_Talent_Item_RightArrow:Enable()
	if (FengYun_PVE_Talent_CurPage <= 1) then
		-- 当前是第一页
		FengYun_PVE_Talent_Item_LeftArrow:Disable()
	end
	if (FengYun_PVE_Talent_CurPage >= FengYun_PVE_Talent_MaxPage) then
		-- 当前是最后一页
		FengYun_PVE_Talent_Item_RightArrow:Disable()
	end

	-- 先将所有天赋展示控件隐藏
	for i=1, table.getn(FengYun_PVE_Talent_TalentCtrlList), 1 do
		if (FengYun_PVE_Talent_TalentCtrlList[i] ~= nil) then
			if FengYun_PVE_Talent_TalentCtrlList[i].frame ~= nil then
				FengYun_PVE_Talent_TalentCtrlList[i].frame:Hide()
				for _,lineList in (FengYun_PVE_Talent_TalentCtrlList[i].line or {}) do
					for _,line in (lineList) do
						line:Hide()
					end
				end
			end
		end
	end -- end for

	-- 当前可用物资点
	local availablePoint = FYPVE:GetAvailableActPoint()
	if (availablePoint < 0) then
		availablePoint = 0
	end
	local pointMsg = ScriptGlobal_Format("#{FYPVE_260108_39}", availablePoint)
	FengYun_PVE_Talent_PointText:SetText(pointMsg)

	-- 进行当前页的内容显示

	local frameUI = FengYun_PVE_Talent_TalentCtrlList[FengYun_PVE_Talent_CurPage]
	if frameUI == nil then
		return
	end

	-- 把当前主页显示出来
	if frameUI.frame ~= nil then
		frameUI.frame:Show()
	end

	-- 对各种UI进行显示
	for index, talentCtrl in (frameUI.item or {}) do
		local curTalentId, curTalentType, curTalentState = FYPVE:GetTalentDataByIndex(index-1)
		local talentId, talentLevel, talentLine, talentPre, talentPoint, talentActStage, talentTitle = FYPVE:GetTableTalentData(index)
		local preTalentId, preTalentType, preTalentState = FYPVE:GetTalentDataByIndex(talentPre-1)
		-- 物资点
		if talentCtrl.need ~= nil then
			if (talentId ~= nil and talentId > 0) then
				-- 是否激活
				if (curTalentState ~= nil and curTalentState > 0) then
					talentCtrl.need:SetText("#c00ff00"..talentPoint)
					talentCtrl.need:Hide()
					talentCtrl.needbg:Hide()
				else
					-- 选中的天赋未激活
					if availablePoint >= talentPoint then
						talentCtrl.need:SetText("#c00ff00"..talentPoint)
					else
						talentCtrl.need:SetText("#cff0000"..talentPoint)
					end
					talentCtrl.need:Show()
					talentCtrl.needbg:Show()
				end
			end
		end
		-- 名字
		if talentCtrl.name ~= nil then
			talentCtrl.name:SetText(talentTitle)
		end
		-- 图标
		if talentCtrl.ctrl ~= nil then
			if (talentId ~= nil and talentId > 0) then
				local theAction = FYPVE:CreateFYPVETalentAction(talentId)
				if (theAction ~= nil and theAction:GetID() ~= 0) then
					talentCtrl.ctrl:SetActionItem(theAction:GetID())
				else
					talentCtrl.ctrl:SetActionItem(-1)
				end
			else
				talentCtrl.ctrl:SetActionItem(-1)
			end

			talentCtrl.ctrl:SetPushed(0)
		end
		-- 锁定和激活状态
		if talentCtrl.activated ~= nil and talentCtrl.lock then
			if (curTalentId ~= nil and curTalentId > 0) then
				if (curTalentState > 0) then
					-- 已激活
					talentCtrl.activated:Show()
					talentCtrl.lock:Hide()
				else
					talentCtrl.activated:Hide()
					talentCtrl.lock:Show()
					-- if (preTalentId == nil) then
					-- 	-- 这应该是没有前置天赋 解除锁定吧
					-- 	talentCtrl.lock:Hide()
					-- else
					-- 	if (preTalentState > 0) then
					-- 		-- 前置天赋已激活 解除锁定
					-- 		talentCtrl.lock:Hide()
					-- 	else
					-- 		-- 前置天赋未激活
					-- 		talentCtrl.lock:Show()
					-- 	end
					-- end
				end
			else
				-- 按未激活处理吧
				talentCtrl.activated:Hide()
				talentCtrl.lock:Show()
				-- if (preTalentId == nil) then
				-- 	-- 这应该是没有前置天赋 解除锁定吧
				-- 	talentCtrl.lock:Hide()
				-- else
				-- 	if (preTalentState > 0) then
				-- 		-- 前置天赋已激活 解除锁定
				-- 		talentCtrl.lock:Hide()
				-- 	else
				-- 		-- 前置天赋未激活
				-- 		talentCtrl.lock:Show()
				-- 	end
				-- end
			end
		end
		-- 选择状态
		if talentCtrl.checked ~= nil then
			-- 资源说激活就不让选中了
			if (curTalentState ~= nil and curTalentState > 0) then
				talentCtrl.checked:Hide()
			else
				if (FengYun_PVE_Talent_CurSelectTalentId == talentId) then
					talentCtrl.checked:Show()
				else
					talentCtrl.checked:Hide()
				end
			end
		end
		-- 处理连线
		if talentCtrl.line ~= nil and talentCtrl.line > 0 then
			-- 当前有连线状态
			if frameUI.line ~= nil and frameUI.line[talentCtrl.line] ~= nil then
				-- 进行遍历
				local lineList = frameUI.line[talentCtrl.line]
				for _, lineUI in (lineList or {}) do
					if (curTalentState ~= nil and curTalentState > 0) then
						lineUI:Show()
					end
				end
			end
		end
		-- 处理尾部连线
		if talentCtrl.tail ~= nil and talentCtrl.tail > 0 then
			local nextTalentId, nextTalentType, nextTalentState = FYPVE:GetTalentDataByIndex(talentCtrl.tail-1)
			for _, tailUI in (frameUI.tailline or {}) do
				if (nextTalentState ~= nil and nextTalentState > 0) then
					tailUI:Show()
				else
					tailUI:Hide()
				end
			end
		end
	end
end -- end func FengYun_PVE_Talent_UpdateTalentInfo()