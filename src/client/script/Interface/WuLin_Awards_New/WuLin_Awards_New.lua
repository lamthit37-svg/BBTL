-- 武林之巅 首通奖励

-- 保存UI默认位置
local WuLin_Awards_New_UnifiedPosition = nil

-- 关注NPC
local WuLin_Awards_New_CareObjId = -1
local WuLin_Awards_New_CareObjSvrId = -1
local WuLin_Awards_New_MAX_OBJ_DISTANCE = 5.0

local WuLin_Awards_New_AwardItemList = {}

-- 奖励数量
local WuLin_Awards_New_Max_AwardNum = 4
-- 奖励最大物品数量
local WuLin_Awards_New_Max_ItemNumPerAward = 5
-- 奖励类型
local WuLin_Awards_New_AwardType =
{
	RankList_Stage1 = 1,			-- 上榜 难度1
	RankList_Stage2 = 2,			-- 上榜 难度2
	RankList_Stage3 = 3,			-- 上榜 难度3
	RankList_Stage4 = 4,			-- 上榜 难度4

	NotInRankList_Stage1 = 11,		-- 未上榜 难度1
	NotInRankList_Stage2 = 12,		-- 未上榜 难度2
	NotInRankList_Stage3 = 13,		-- 未上榜 难度3
	NotInRankList_Stage4 = 14,		-- 未上榜 难度4
} -- end WuLin_Awards_New_AwardType
-- 奖励物品类型
local WuLin_Awards_New_AwardItemType =
{
	item = 1,	-- 道具
	mat = 2,	-- 材料
} -- end WuLin_Awards_New_AwardItemType

function WuLin_Awards_New_PreLoad()
	this:RegisterEvent("JZWLZD_OPEN_SHOWAWARD", true)
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_Awards_New_PreLoad()

function WuLin_Awards_New_OnLoad()
	WuLin_Awards_New_UnifiedPosition = WuLin_Awards_New_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_Awards_New_OnLoad()

function WuLin_Awards_New_OnEvent(event)
	if (event == "JZWLZD_OPEN_SHOWAWARD") then
		WuLin_Awards_New_Show()
		WuLin_Awards_New_ShowAward()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_Awards_New_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_Awards_New_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_Awards_New_UnifiedPos()
	end
end -- end func WuLin_Awards_New_OnEvent()

-- 界面默认位置
function WuLin_Awards_New_UnifiedPos()
	if (WuLin_Awards_New_UnifiedPosition ~= nil) then
		WuLin_Awards_New_Frame:SetProperty("UnifiedPosition", WuLin_Awards_New_UnifiedPosition)
	end
end -- end func WuLin_Awards_New_UnifiedPos()

-- 开启UI
function WuLin_Awards_New_Show()
	this:Show()
end -- end func WuLin_Awards_New_Show()

-- 关闭UI
function WuLin_Awards_New_Hide()
	this:Hide()
end -- end func WuLin_Awards_New_Hide()

-- 关闭按钮事件
function WuLin_Awards_New_Close()
	WuLin_Awards_New_Hide()
end -- end func WuLin_Awards_New_Close()()

-- 刷新奖励展示
function WuLin_Awards_New_ShowAward()
	WuLin_Awards_New_List:Clear()

	for i=1, WuLin_Awards_New_Max_AwardNum, 1 do
		local child = WuLin_Awards_New_List:AddChild("WuLin_Awards_New_AItem")
		if (child == nil) then
			break
		end

		-- 奖励层数
		local awardTip = ""
		if (i == 1) then
			awardTip = "#{JZGSH_210222_167}"
		elseif (i == 2) then
			awardTip = "#{JZGSH_210222_166}"
		elseif (i == 3) then
			awardTip = "#{JZGSH_210222_165}"
		elseif (i == 4) then
			awardTip = "#{JZGSH_210222_164}"
		end
		child:GetSubItem("WuLin_Awards_New_Text"):SetText(awardTip)

		-- 先隐藏所有奖励展示框 后面有奖励的再一个个加回来
		child:GetSubItem("WuLin_Awards_New_Item1"):Hide()
		child:GetSubItem("WuLin_Awards_New_Item2"):Hide()
		child:GetSubItem("WuLin_Awards_New_Item3"):Hide()
		child:GetSubItem("WuLin_Awards_New_Item4"):Hide()
		child:GetSubItem("WuLin_Awards_New_Item5"):Hide()

		child:GetSubItem("WuLin_Awards_New_Item1_Mask"):Hide()
		child:GetSubItem("WuLin_Awards_New_Item2_Mask"):Hide()
		child:GetSubItem("WuLin_Awards_New_Item3_Mask"):Hide()
		child:GetSubItem("WuLin_Awards_New_Item4_Mask"):Hide()
		child:GetSubItem("WuLin_Awards_New_Item5_Mask"):Hide()

		for j=WuLin_Awards_New_AwardType.NotInRankList_Stage1, WuLin_Awards_New_AwardType.NotInRankList_Stage4, 1 do
			local item, showItem, num, type, needPos = JueZhanWuLinZhiDian:GetAwardInfo(i, 1, j)
			if (item < 0) then
				break
			end

			-- 创建展示道具
			local theAction = DataPool:CreateActionItemForShow(showItem, num)

			if (j == 1) then
				child:GetSubItem("WuLin_Awards_New_Item1"):SetActionItem(theAction:GetID())
				child:GetSubItem("WuLin_Awards_New_Item1"):Show()
			elseif (j == 2) then
				child:GetSubItem("WuLin_Awards_New_Item2"):SetActionItem(theAction:GetID())
				child:GetSubItem("WuLin_Awards_New_Item2"):Show()
			elseif (j == 3) then
				child:GetSubItem("WuLin_Awards_New_Item3"):SetActionItem(theAction:GetID())
				child:GetSubItem("WuLin_Awards_New_Item3"):Show()
			elseif (j == 4) then
				child:GetSubItem("WuLin_Awards_New_Item4"):SetActionItem(theAction:GetID())
				child:GetSubItem("WuLin_Awards_New_Item4"):Show()
			elseif (j == 5) then
				child:GetSubItem("WuLin_Awards_New_Item5"):SetActionItem(theAction:GetID())
				child:GetSubItem("WuLin_Awards_New_Item5"):Show()
			end
		end -- end for
	end -- end for
end -- end func WuLin_Awards_New_ShowAward()