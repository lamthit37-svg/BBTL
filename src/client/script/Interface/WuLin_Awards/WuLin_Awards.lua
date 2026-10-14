-- 武林之巅 首通奖励

-- 保存UI默认位置
local WuLin_Awards_UnifiedPosition = nil

-- 关注NPC
local WuLin_Awards_CareObjId = -1
local WuLin_Awards_CareObjSvrId = -1
local WuLin_Awards_MAX_OBJ_DISTANCE = 5.0

local WuLin_Awards_AwardItemList = {}

-- 最大层数
local WuLin_Awards_MaxStage = 100

-- 20200724 首通奖励调整 巾帼集录物品显示ID
local WuLin_Awards_JinGuoJiLu = 39922433

-- 首通奖励信息
local WuLin_Awards_AwardInfo =
{
	-- 5层奖励
	[1] =
	{
		[1] = {id = -1, num = 1},
	},
	-- 10层奖励
	[2] =
	{
		[1] = {id = 39922153, num = 1},
	},
	-- 15层奖励
	[3] =
	{
		[1] = {id = 39920181, num = 2},
	},
	-- 20层奖励
	[4] =
	{
		[1] = {id = 39922222, num = 1},
		[2] = {id = 39921313, num = 3},
	},
	-- 25层奖励
	[5] =
	{
		[1] = {id = 39922428, num = 1},
		[2] = {id = 39920397, num = 1},
		[3] = {id = 39920396, num = 1},
	},
	-- 30层奖励
	[6] =
	{
		[1] = {id = 39922152, num = 1},
		[2] = {id = 39922174, num = 1},
	},
	-- 35层奖励
	[7] =
	{
		[1] = {id = 39922433, num = 1},
		[2] = {id = 39920397, num = 2},
		[3] = {id = 39920396, num = 2},
	},
	-- 40层奖励
	[8] =
	{
		[1] = {id = 39920329, num = 10},
		[2] = {id = 39920537, num = 5},
	},
	-- 45层奖励
	[9] =
	{
		[1] = {id = 39922218, num = 1},
		[2] = {id = 39922174, num = 2},
	},
	-- 50层奖励
	[10] =
	{
		[1] = {id = 39922719, num = 10},
		[2] = {id = 39922438, num = 1},
		[3] = {id = 39920397, num = 1},
		[4] = {id = 39920396, num = 1},
	},
	-- 55层奖励
	[11] =
	{
		[1] = {id = 39922429, num = 1},
		[2] = {id = 39920566, num = 1},
		[3] = {id = 39920565, num = 1},
	},
	-- 60层奖励
	[12] =
	{
		[1] = {id = 39921847, num = 1},
	},
	-- 65层奖励
	[13] =
	{
		[1] = {id = 39922434, num = 1},
		[2] = {id = 39922438, num = 2},
		[3] = {id = 39922174, num = 1},
	},
	-- 70层奖励
	[14] =
	{
		[1] = {id = 39920566, num = 2},
		[2] = {id = 39920565, num = 2},
	},
	-- 75层奖励
	[15] =
	{
		[1] = {id = 39922436, num = 1},
		[2] = {id = 39921845, num = 1},
	},
	-- 80层奖励
	[16] =
	{
		[1] = {id = 39922435, num = 1},
		[2] = {id = 39922438, num = 2},
		[3] = {id = 39922174, num = 3},
	},
	-- 85层奖励
	[17] =
	{
		[1] = {id = 39922430, num = 1},
		[2] = {id = 39921549, num = 2},
		[3] = {id = 39921547, num = 2},
	},
	-- 90层奖励
	[18] =
	{
		[1] = {id = 39922437, num = 1},
		[2] = {id = 39921549, num = 4},
		[3] = {id = 39921547, num = 4},
	},
	-- 95层奖励
	[19] =
	{
		[1] = {id = 39922228, num = 1},
		[2] = {id = 39922438, num = 2},
		[3] = {id = 39922174, num = 3},
	},
	-- 100层奖励
	[20] =
	{
		[1] = {id = 39922432, num = 1},
		[2] = {id = 39922439, num = 1},
		[3] = {id = 39922440, num = 1},
		[4] = {id = 39921549, num = 6},
		[5] = {id = 39921547, num = 6},
	},
} -- end WuLin_Awards_AwardInfo

function WuLin_Awards_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("WLZD_OPEN_STAGEAWARD", true)
	this:RegisterEvent("WLZD_UPDATE_STAGEAWARD", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_Awards_PreLoad()

function WuLin_Awards_OnLoad()
	WuLin_Awards_UnifiedPosition = WuLin_Awards_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_Awards_OnLoad()

function WuLin_Awards_OnEvent(event)
	if (event == "WLZD_OPEN_STAGEAWARD") then
		WuLin_Awards_BeginCareObject(arg0, arg1)
		WuLin_Awards_Show(arg2)
	elseif (event == "WLZD_UPDATE_STAGEAWARD") then
		WuLin_Awards_UpdateStageAwardState(arg0, arg1)
	elseif (event == "WLZD_CLOSE_ALL") then
		WuLin_Awards_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_Awards_Hide()
	elseif (event == "OBJECT_CARED_EVENT") then
		if (tonumber(arg0) ~= WuLin_Awards_CareObjId) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if ((arg1 == "distance" and tonumber(arg2) > WuLin_Awards_MAX_OBJ_DISTANCE) or arg1 == "destroy") then
			--取消关心
			WuLin_Awards_Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_Awards_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_Awards_UnifiedPos()
	end
end -- end func WuLin_Awards_OnEvent()

-- 界面默认位置
function WuLin_Awards_UnifiedPos()
	if (WuLin_Awards_UnifiedPosition ~= nil) then
		WuLin_Awards_Frame:SetProperty("UnifiedPosition", WuLin_Awards_UnifiedPosition)
	end
end -- end func WuLin_Awards_UnifiedPos()

-- 开启UI
function WuLin_Awards_Show(compensationState)
	if (this:IsVisible()) then
		this:Hide()
	end
	this:Show()
	WuLin_Awards_UpdateStageList(compensationState)
end -- end func WuLin_Awards_Show()

-- 关闭UI
function WuLin_Awards_Hide()
	WuLin_Awards_StopCareObject(WuLin_Awards_CareObjId)
	this:Hide()
end -- end func WuLin_Awards_Hide()

-- 刷新领奖层数列表
function WuLin_Awards_UpdateStageList(compensationState)
	WuLin_Awards_ClearStageList()
	local isShowRedTip = -1
	-- 每5层一个首通奖励
	for i = 9, WuLin_Awards_MaxStage - 1, 5 do
		isShowRedTip = -1
		-- 获取各个层数的状态
		-- 0：未通关， 1：已通关未领奖， 2：已通关已领奖
		local stageState = WuLinZhiDian:GetStageState(i)
		local child = WuLin_Awards_List:AddChild("WuLin_Awards_AItem")

		WuLin_Awards_AwardItemList[i+1] = {}
		WuLin_Awards_AwardItemList[i+1].stage = i + 1
		WuLin_Awards_AwardItemList[i+1].child = child

		-- 隐藏所有奖励物品展示位
		child:GetSubItem("WuLin_Awards_Item1"):Hide()
		child:GetSubItem("WuLin_Awards_Item2"):Hide()
		child:GetSubItem("WuLin_Awards_Item3"):Hide()
		child:GetSubItem("WuLin_Awards_Item4"):Hide()
		child:GetSubItem("WuLin_Awards_Item5"):Hide()
		child:GetSubItem("WuLin_Awards_Item6"):Hide()

		child:GetSubItem("WuLin_Awards_Item1_Mask"):Hide()
		child:GetSubItem("WuLin_Awards_Item2_Mask"):Hide()
		child:GetSubItem("WuLin_Awards_Item3_Mask"):Hide()
		child:GetSubItem("WuLin_Awards_Item4_Mask"):Hide()
		child:GetSubItem("WuLin_Awards_Item5_Mask"):Hide()

		-- 文字提示
		local tips = nil
		if (stageState == 1) then
			-- 已通关 未领奖
			tips = ScriptGlobal_Format("#{PTFB_191228_134}", (i + 1))
			-- 优化需求 这个判断不要了
			-- 检查本层之前的层数是否已同光并且首通奖励已领取
			--isShowRedTip = WuLin_Awards_IsAlreadyGetLowStageAward(i)
			isShowRedTip = 1
		elseif (stageState == 2) then
			-- 已通关 已领奖
			tips = ScriptGlobal_Format("#{PTFB_191228_134}", (i + 1))
		else
			-- 未通关
			tips = ScriptGlobal_Format("#{PTFB_191228_133}", (i + 1))
		end
		child:GetSubItem("WuLin_Awards_Text"):SetText(tips)

		-- 奖励物品 （测试）
		local showMask = 0
		local awardIndex = math.floor((i + 1) / 5)
		local awardInfo = WuLin_Awards_AwardInfo[awardIndex]
		if (awardInfo ~= nil) then
			for k, v in awardInfo do
				if (v ~= nil and v.id > 0) then
					showMask = 0
					local theAction = DataPool:CreateActionItemForShow(v.id, v.num)
					-- 20200724 首通奖励调整特殊处理
					-- 若玩家已领取过50层首通奖励 则35层首通奖励中巾帼集录需要蒙红
					if (compensationState ~= nil and tonumber(compensationState) > 1 and i+1 == 35 and stageState == 1 and v.id == WuLin_Awards_JinGuoJiLu) then
						-- 玩家有补偿奖励（说明玩家之前领过35层或50层的奖励）
						-- 35层奖励可以领取（这里说明玩家之前领取的是50层的奖励）
						-- 当前物品是巾帼集录
						-- 35层奖励总巾帼集录需要蒙红
						showMask = 1
					end

					if (k == 1) then
						child:GetSubItem("WuLin_Awards_Item1"):SetActionItem(theAction:GetID())
						child:GetSubItem("WuLin_Awards_Item1"):Show()
						if (showMask > 0) then
							child:GetSubItem("WuLin_Awards_Item1_Mask"):Show()
						else
							child:GetSubItem("WuLin_Awards_Item1_Mask"):Hide()
						end
					elseif (k == 2) then
						child:GetSubItem("WuLin_Awards_Item2"):SetActionItem(theAction:GetID())
						child:GetSubItem("WuLin_Awards_Item2"):Show()
						if (showMask > 0) then
							child:GetSubItem("WuLin_Awards_Item2_Mask"):Show()
						else
							child:GetSubItem("WuLin_Awards_Item2_Mask"):Hide()
						end
					elseif (k == 3) then
						child:GetSubItem("WuLin_Awards_Item3"):SetActionItem(theAction:GetID())
						child:GetSubItem("WuLin_Awards_Item3"):Show()
						if (showMask > 0) then
							child:GetSubItem("WuLin_Awards_Item3_Mask"):Show()
						else
							child:GetSubItem("WuLin_Awards_Item3_Mask"):Hide()
						end
					elseif (k == 4) then
						child:GetSubItem("WuLin_Awards_Item4"):SetActionItem(theAction:GetID())
						child:GetSubItem("WuLin_Awards_Item4"):Show()
						if (showMask > 0) then
							child:GetSubItem("WuLin_Awards_Item4_Mask"):Show()
						else
							child:GetSubItem("WuLin_Awards_Item4_Mask"):Hide()
						end
					elseif (k == 5) then
						child:GetSubItem("WuLin_Awards_Item5"):SetActionItem(theAction:GetID())
						child:GetSubItem("WuLin_Awards_Item5"):Show()
						if (showMask > 0) then
							child:GetSubItem("WuLin_Awards_Item5_Mask"):Show()
						else
							child:GetSubItem("WuLin_Awards_Item5_Mask"):Hide()
						end
					elseif (k == 6) then
						child:GetSubItem("WuLin_Awards_Item6"):SetActionItem(theAction:GetID())
						child:GetSubItem("WuLin_Awards_Item6"):Show()
					end
				end
			end -- end for
		end

		-- 领奖按钮及红点
		if (stageState == 1) then
			-- 已通关 未领奖
			-- 显示完成标记
			child:GetSubItem("WuLin_Awards_Num"):SetProperty("Image", "set:GuanShanHai16 image:Q1_AwardsBK6")
			child:GetSubItem("WuLin_Awards_Num"):Show()

			-- 隐藏已领取/未达成标记
			child:GetSubItem("WuLin_Awards_YiLing"):Hide()

			-- 注册按钮事件 显示领奖按钮
			child:GetSubItem("WuLin_Awards_Btn"):Enable()
			child:GetSubItem("WuLin_Awards_Btn"):SetText("#{PTFB_191228_135}")
			child:GetSubItem("WuLin_Awards_Btn"):SetEvent("Clicked", string.format("WuLin_Awards_GetAward(%d)", (i + 1)), 10)
			child:GetSubItem("WuLin_Awards_Btn"):Show()

			-- 红点
			if (isShowRedTip > 0) then
				child:GetSubItem("WuLin_Awards_Tips"):Show()
			else
				child:GetSubItem("WuLin_Awards_Tips"):Hide()
			end
		elseif (stageState == 2) then
			-- 已通关 已领奖
			-- 显示完成标记
			child:GetSubItem("WuLin_Awards_Num"):SetProperty("Image", "set:GuanShanHai16 image:Q1_AwardsBK6")
			child:GetSubItem("WuLin_Awards_Num"):Show()

			-- 显示已领取标记
			child:GetSubItem("WuLin_Awards_YiLing"):SetProperty("Image", "set:GuanShanHai16 image:Q1_YiLingQu")
			child:GetSubItem("WuLin_Awards_YiLing"):Show()

			-- 隐藏领奖按钮
			child:GetSubItem("WuLin_Awards_Btn"):Hide()

			-- 红点
			child:GetSubItem("WuLin_Awards_Tips"):Hide()
		else
			-- 未通关
			child:GetSubItem("WuLin_Awards_Num"):SetProperty("Image", "set:GuanShanHai16 image:Q1_AwardsBK5")
			child:GetSubItem("WuLin_Awards_Num"):Show()

			-- 显示未通关标记
			child:GetSubItem("WuLin_Awards_YiLing"):SetProperty("Image", "set:GuanShanHai16 image:Q1_WeiDaCheng")
			child:GetSubItem("WuLin_Awards_YiLing"):Show()

			-- 隐藏领奖按钮
			child:GetSubItem("WuLin_Awards_Btn"):Hide()

			-- 红点
			child:GetSubItem("WuLin_Awards_Tips"):Hide()
		end
	end -- end for
end -- end func WuLin_Awards_UpdateStageList()

function WuLin_Awards_ClearStageList()
	if (WuLin_Awards_List == nil) then
		return
	end

	-- 测试、调试用 用于清除替代奖励物品的
	--DataPool:ClearActionItemForShow()
	for k, v in WuLin_Awards_AwardItemList do
		if (v ~= nil) then
			local child = v.child
			if (child ~= nil) then
				child:GetSubItem("WuLin_Awards_Item1"):SetActionItem(-1)
				child:GetSubItem("WuLin_Awards_Item2"):SetActionItem(-1)
				child:GetSubItem("WuLin_Awards_Item3"):SetActionItem(-1)
			end
		end 
	end -- end for
	
	WuLin_Awards_List:Clear()
	WuLin_Awards_AwardItemList = {}
end -- end fun WuLin_Awards_ClearStageList()

-- 更新领奖状态
-- state: 0：未通关， 1：已通关未领奖， 2：已通关已领奖
function WuLin_Awards_UpdateStageAwardState(stage, state)
	for k, v in WuLin_Awards_AwardItemList do
		if (v ~= nil) then
			if (v.stage == tonumber(stage)) then
				local child = v.child
				if (child ~= nil) then
					if (tonumber(state) == 1) then
						-- 已通关 未领奖
						-- 显示完成标记
						child:GetSubItem("WuLin_Awards_Num"):SetProperty("Image", "set:GuanShanHai16 image:Q1_AwardsBK6")
						child:GetSubItem("WuLin_Awards_Num"):Show()

						-- 隐藏已领取/未达成标记
						child:GetSubItem("WuLin_Awards_YiLing"):Hide()

						-- 注册按钮事件 显示领奖按钮
						child:GetSubItem("WuLin_Awards_Btn"):Enable()
						child:GetSubItem("WuLin_Awards_Btn"):SetText("#{PTFB_191228_135}")
						--child:GetSubItem("WuLin_Awards_Btn"):SetEvent("Clicked", string.format("WuLin_Awards_GetAward(%d)", (i + 1)), 10)
						child:GetSubItem("WuLin_Awards_Btn"):Show()

						-- 红点
						child:GetSubItem("WuLin_Awards_Tips"):Show()
					elseif (tonumber(state) == 2) then
						-- 已通关 已领奖
						-- 显示完成标记
						child:GetSubItem("WuLin_Awards_Num"):SetProperty("Image", "set:GuanShanHai16 image:Q1_AwardsBK6")
						child:GetSubItem("WuLin_Awards_Num"):Show()

						-- 显示已领取标记
						child:GetSubItem("WuLin_Awards_YiLing"):SetProperty("Image", "set:GuanShanHai16 image:Q1_YiLingQu")
						child:GetSubItem("WuLin_Awards_YiLing"):Show()

						-- 隐藏领奖按钮
						child:GetSubItem("WuLin_Awards_Btn"):Hide()

						-- 红点
						child:GetSubItem("WuLin_Awards_Tips"):Hide()

						-- 20200724 首通奖励调整特殊处理
						-- 35层首通奖励领取后 取消巾帼集录蒙红
						if (tonumber(stage) == 35) then
							child:GetSubItem("WuLin_Awards_Item1_Mask"):Hide()
							child:GetSubItem("WuLin_Awards_Item2_Mask"):Hide()
							child:GetSubItem("WuLin_Awards_Item3_Mask"):Hide()
							child:GetSubItem("WuLin_Awards_Item4_Mask"):Hide()
							child:GetSubItem("WuLin_Awards_Item5_Mask"):Hide()
						end
					else
						-- 未通关
						child:GetSubItem("WuLin_Awards_Num"):SetProperty("Image", "set:GuanShanHai16 image:Q1_AwardsBK6")
						child:GetSubItem("WuLin_Awards_Num"):Show()

						-- 显示未通关标记
						child:GetSubItem("WuLin_Awards_YiLing"):SetProperty("Image", "set:GuanShanHai16 image:Q1_WeiDaCheng")
						child:GetSubItem("WuLin_Awards_YiLing"):Show()

						-- 隐藏领奖按钮
						child:GetSubItem("WuLin_Awards_Btn"):Hide()

						-- 红点
						child:GetSubItem("WuLin_Awards_Tips"):Hide()
					end
				end
			end
		end
	end -- end for
end -- end func WuLin_Awards_UpdateStageAwardState()

-- 检查当前可领奖层数之前的层数是否已通关并且已领奖
function WuLin_Awards_IsAlreadyGetLowStageAward(stage)
	if (stage < 4) then
		return 1
	elseif (stage == 4) then
		local state = WuLinZhiDian:GetStageState(stage)
		if (state == 1) then
			return 1
		elseif (state == 0) then
			return -1
		end
	else
		for i=4, stage-1, 5 do
			-- 获取状态
			-- 0：未通关， 1：已通关未领奖， 2：已通关已领奖
			local state = WuLinZhiDian:GetStageState(i)
			if (state == 0) then
				return -1
			end
		end -- end for
	end

	return 1
end -- end func WuLin_Awards_IsAlreadyGetLowStageAward

-- 领奖按钮事件
function WuLin_Awards_GetAward(stage)
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("GetStageCompleteAward")
	Set_XSCRIPT_ScriptID(893398)
	Set_XSCRIPT_Parameter(0, stage)
	Set_XSCRIPT_Parameter(1, WuLin_Awards_CareObjSvrId)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end -- end func WuLin_Awards_GetAward()

-- 关闭按钮事件
function WuLin_Awards_Close()
	WuLin_Awards_Hide()
end -- end func WuLin_Awards_Close()

-- 开启NPC关注
function WuLin_Awards_BeginCareObject(objSvrId, objId)
	WuLin_Awards_CareObjId = tonumber(objId)
	WuLin_Awards_CareObjSvrId = tonumber(objSvrId)
	if (WuLin_Awards_CareObjId >= 0) then
		this:CareObject(WuLin_Awards_CareObjId, 1, "WuLin_Awards")
	end
end -- end func WuLin_Team_BeginCareObject()

-- 取消NPC关注
function WuLin_Awards_StopCareObject(objId)
	if (tonumber(objId) >= 0) then
		this:CareObject(tonumber(objId), 0, "WuLin_Awards")
		WuLin_Awards_CareObjId = -1
		WuLin_Awards_CareObjSvrId = -1
	end
end -- end func WuLin_Team_StopCareObject()
