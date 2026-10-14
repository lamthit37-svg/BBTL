-- 决战武林之巅 排行榜界面

-- 排行榜最大调试
local WuLin_List_New_RankList_MaxItem = 100

local WuLin_List_New_CareObjId = -1
local WuLin_List_New_CareObjSvrId = -1
local WuLin_List_New_MAX_OBJ_DISTANCE = 5

-- 保存UI默认位置
local WuLin_List_New_Frame_UnifiedPosition = nil

-- 排名第一队伍信息控件列表
local WuLin_List_New_TopCtrl = nil

local WuLin_List_New_RankInfo =
{
	-- 队伍
	[1] = {name="#{PTFB_191228_147}", menpai = -1},
	-- 少林
	[2] = {name="#{PTFB_191228_148}", menpai = 0},
	-- 明教
	[3] = {name="#{PTFB_191228_149}", menpai = 1},
	-- 丐帮
	[4] = {name="#{PTFB_191228_150}", menpai = 2},
	-- 武当
	[5] = {name="#{PTFB_191228_151}", menpai = 3},
	-- 峨嵋
	[6] = {name="#{PTFB_191228_152}", menpai = 4},
	-- 星宿
	[7] = {name="#{PTFB_191228_153}", menpai = 5},
	-- 天龙
	[8] = {name="#{PTFB_191228_154}", menpai = 6},
	-- 天山
	[9] = {name="#{PTFB_191228_155}", menpai = 7},
	-- 逍遥
	[10] = {name="#{PTFB_191228_156}", menpai = 8},
	-- 慕容
	[11] = {name="#{PTFB_191228_157}", menpai = 10},
	-- 唐门
	[12] = {name="#{PTFB_191228_158}", menpai = 11},
	-- 鬼谷
	[13] = {name="#{PTFB_191228_159}", menpai = 12},
	-- 桃花岛
	[14] = {name="#{PTFB_191228_160}", menpai = 13},
	-- 绝情谷
	[15] = {name="#{PTFB_210720_01}", menpai = 14},
	-- menpai15
	[16] = {name="#{PTFB_240726_01}", menpai = 15},
} -- end WuLin_List_New_RankInfo

function WuLin_List_New_PreLoad()
	this:RegisterEvent("JZWLZD_OPEN_RANKLIST", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end -- end func WuLin_List_New_PreLoad()

function WuLin_List_New_OnLoad()
	WuLin_List_New_InitCtrl()

	WuLin_List_New_Frame_UnifiedPosition = WuLin_List_New_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_List_New_OnLoad()

function WuLin_List_New_OnEvent(event)
	if (event == "JZWLZD_OPEN_RANKLIST") then
		local stage = tonumber(arg0)
		if (stage <= 0) then
			-- 应该是当前不在活动时间内 给提示
			PushDebugMessage("#{JZGSH_210222_259}")
			return
		else
			WuLin_List_New_Show()
			WuLin_List_New_UpdateRankList(stage)

			-- 设置NPC关注
			WuLin_List_New_BeginCareObject(arg1, arg2)
		end
	elseif (event == "OBJECT_CARED_EVENT") then
		-- 这个事件目前已经被干掉了
		-- 要调整关注距离直接去改代码吧 ObjectManager.cpp CObjectManager::Tick(VOID)
		if(tonumber(arg0) ~= WuLin_List_New_CareObjId) then
			return
		end

		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2)>WuLin_List_New_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			WuLin_List_New_Hide()
		end
	elseif(event == "ADJEST_UI_POS") then
		WuLin_List_New_UnifiedPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_List_New_UnifiedPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_List_New_Hide()
	end
end -- end func WuLin_List_New_OnEvent()

function WuLin_List_New_UnifiedPos()
	WuLin_List_New_Frame:SetProperty("UnifiedPosition", WuLin_List_New_Frame_UnifiedPosition)
end -- end func WuLin_List_New_UnifiedPos()

-- 开启NPC关注
function WuLin_List_New_BeginCareObject(objSvrId, objId)
	WuLin_List_New_CareObjId = tonumber(objId)
	WuLin_List_New_CareObjSvrId = tonumber(objSvrId)
	if (WuLin_List_New_CareObjId >= 0) then
		this:CareObject(WuLin_List_New_CareObjId, 1, "WuLin_List_New")
	end
end -- end func WuLin_List_New_BeginCareObject()

-- 取消NPC关注
function WuLin_List_New_StopCareObject()
	if (WuLin_List_New_CareObjId >= 0) then
		this:CareObject(WuLin_List_New_CareObjId, 0, "WuLin_List_New")
	end

	WuLin_List_New_CareObjId = -1
	WuLin_List_New_CareObjSvrId = -1
end -- end func WuLin_List_New_StopCareObject()

-- 显示UI
function WuLin_List_New_Show()
	this:Show()
end -- end func WuLin_List_New_Show()

-- 关闭UI
function WuLin_List_New_Hide()
	-- 关闭队伍信息界面
	PushEvent("CLOSE_WULIN_TEAMDET")

	WuLin_List_New_StopCareObject()
	this:Hide()
end -- end func WuLin_List_New_Hide()

-- UI关闭事件
function WuLin_List_NewClose()
	WuLin_List_New_Hide()
end -- end func WuLin_List_NewClose()

-- 初始化控件
function WuLin_List_New_InitCtrl()
	-- 排名第一的队伍信息控件列表
	WuLin_List_New_TopCtrl = {}
	-- 第一个玩家
	WuLin_List_New_TopCtrl[1] = {}
	WuLin_List_New_TopCtrl[1].ctrl = WuLin_List_New_NameBoard_Head1
	WuLin_List_New_TopCtrl[1].head = WuLin_List_New_NameBoard_Head1_2D
	WuLin_List_New_TopCtrl[1].name = WuLin_List_New_NameBoard_Head1_Name
	WuLin_List_New_TopCtrl[1].menpai = WuLin_List_New_NameBoard_Head1_Occu
	WuLin_List_New_TopCtrl[1].level = WuLin_List_New_NameBoard_Head1_Level
	-- 第二个玩家
	WuLin_List_New_TopCtrl[2] = {}
	WuLin_List_New_TopCtrl[2].ctrl = WuLin_List_New_NameBoard_Head2
	WuLin_List_New_TopCtrl[2].head = WuLin_List_New_NameBoard_Head2_2D
	WuLin_List_New_TopCtrl[2].name = WuLin_List_New_NameBoard_Head2_Name
	WuLin_List_New_TopCtrl[2].menpai = WuLin_List_New_NameBoard_Head2_Occu
	WuLin_List_New_TopCtrl[2].level = WuLin_List_New_NameBoard_Head2_Level
	-- 第三个玩家
	WuLin_List_New_TopCtrl[3] = {}
	WuLin_List_New_TopCtrl[3].ctrl = WuLin_List_New_NameBoard_Head3
	WuLin_List_New_TopCtrl[3].head = WuLin_List_New_NameBoard_Head3_2D
	WuLin_List_New_TopCtrl[3].name = WuLin_List_New_NameBoard_Head3_Name
	WuLin_List_New_TopCtrl[3].menpai = WuLin_List_New_NameBoard_Head3_Occu
	WuLin_List_New_TopCtrl[3].level = WuLin_List_New_NameBoard_Head3_Level
	-- 第四个玩家
	WuLin_List_New_TopCtrl[4] = {}
	WuLin_List_New_TopCtrl[4].ctrl = WuLin_List_New_NameBoard_Head4
	WuLin_List_New_TopCtrl[4].head = WuLin_List_New_NameBoard_Head4_2D
	WuLin_List_New_TopCtrl[4].name = WuLin_List_New_NameBoard_Head4_Name
	WuLin_List_New_TopCtrl[4].menpai = WuLin_List_New_NameBoard_Head4_Occu
	WuLin_List_New_TopCtrl[4].level = WuLin_List_New_NameBoard_Head4_Level
	-- 第五个玩家
	WuLin_List_New_TopCtrl[5] = {}
	WuLin_List_New_TopCtrl[5].ctrl = WuLin_List_New_NameBoard_Head5
	WuLin_List_New_TopCtrl[5].head = WuLin_List_New_NameBoard_Head5_2D
	WuLin_List_New_TopCtrl[5].name = WuLin_List_New_NameBoard_Head5_Name
	WuLin_List_New_TopCtrl[5].menpai = WuLin_List_New_NameBoard_Head5_Occu
	WuLin_List_New_TopCtrl[5].level = WuLin_List_New_NameBoard_Head5_Level
	-- 第六个玩家
	WuLin_List_New_TopCtrl[6] = {}
	WuLin_List_New_TopCtrl[6].ctrl = WuLin_List_New_NameBoard_Head6
	WuLin_List_New_TopCtrl[6].head = WuLin_List_New_NameBoard_Head6_2D
	WuLin_List_New_TopCtrl[6].name = WuLin_List_New_NameBoard_Head6_Name
	WuLin_List_New_TopCtrl[6].menpai = WuLin_List_New_NameBoard_Head6_Occu
	WuLin_List_New_TopCtrl[6].level = WuLin_List_New_NameBoard_Head6_Level
end -- end func WuLin_List_New_InitCtrl()

-- 排行榜点击事件
function WuLin_List_New_RankListClicked(rank)
	-- 获取排行榜上队伍信息
	local bossMenPai, useTime, memberCount, leaderName = JueZhanWuLinZhiDian:GetRankListInfo(rank)
	if (bossMenPai >= 0 and useTime > 0 and memberCount > 0) then
		PushEvent("JZWLZD_OPEN_TEAMDETAIL", rank)
	end
end -- end func WuLin_List_New_RankListClicked()

-- 刷新排行榜
function WuLin_List_New_UpdateRankList(stage)
	-- 左上难度显示
	local stageTip = nil
	if (stage == 1) then
		stageTip = "#{JZGSH_210222_167}"
	elseif (stage == 2) then
		stageTip = "#{JZGSH_210222_166}"
	elseif (stage == 3) then
		stageTip = "#{JZGSH_210222_165}"
	elseif (stage == 4) then
		stageTip = "#{JZGSH_210222_164}"
	end
	if (stageTip ~= nil) then
		WuLin_List_NewUp_Diff_Text:Show()
		WuLin_List_NewUp_Diff_Text:SetText(stageTip)
	else
		WuLin_List_NewUp_Diff_Text:Hide()
	end

	-- 排行榜第一名队伍信息
	if (WuLin_List_New_TopCtrl ~= nil) then
		for i=1, 6, 1 do
			if (WuLin_List_New_TopCtrl[i] ~= nil) then
				WuLin_List_New_TopCtrl[i].ctrl:Hide()
			end
		end -- end for
		-- 获取排名第一的队伍信息
		local bossMenPai, useTime, memberCount, leaderName = JueZhanWuLinZhiDian:GetRankListInfo(1)
		if (bossMenPai >= 0 and useTime > 0 and memberCount > 0) then
			for i=1, memberCount, 1 do
				-- 获取每个队员的信息
				local menpai, level, score, head, name = JueZhanWuLinZhiDian:GetRankListMemberInfo(1, i)
				if (WuLin_List_New_TopCtrl[i] ~= nil) then
					WuLin_List_New_TopCtrl[i].ctrl:Show()
					-- 头像
					WuLin_List_New_TopCtrl[i].head:SetProperty("Image", head)
					-- 名字
					WuLin_List_New_TopCtrl[i].name:SetText(name)
					-- 门派
					local menpaiName = WuLin_List_New_GetMenPaiName(menpai)
					if (menpaiName ~= nil) then
						WuLin_List_New_TopCtrl[i].menpai:Show()
						WuLin_List_New_TopCtrl[i].menpai:SetText(menpaiName)
					else
						WuLin_List_New_TopCtrl[i].menpai:Hide()
					end
					-- 等级
					WuLin_List_New_TopCtrl[i].level:SetText(tostring(level))
				end
			end -- end for
		end
	end

	-- 排行榜(从第二名开始)
	WuLin_List_NewDown_RightListFrame:Clear()
	for i=2, WuLin_List_New_RankList_MaxItem, 1 do
		-- 获取排行榜上队伍信息
		local bossMenPai, useTime, memberCount, leaderName = JueZhanWuLinZhiDian:GetRankListInfo(i)
		if (bossMenPai >= 0 and useTime > 0 and memberCount > 0) then
			local child = WuLin_List_NewDown_RightListFrame:AddChild("WuLin_List_New_AItem")
			if (child ~= nil) then
				-- 排名
				child:GetSubItem("WuLin_List_New_AItem_Rank"):SetText(tostring(i))
				-- 队长
				child:GetSubItem("WuLin_List_New_AItem_Name"):SetText(leaderName)
				-- boss门派
				local menpaiName = WuLin_List_New_GetMenPaiName(bossMenPai)
				child:GetSubItem("WuLin_List_New_AItem_Num"):SetText(menpaiName)
				-- 通关时间
				local min, sec = WuLin_List_New_GetTimeMinAndSec(useTime)
				local timeStr = string.format("%02d:%02d", min, sec)
				child:GetSubItem("WuLin_List_New_AItem_Time"):SetText(timeStr)

				-- 设置排行榜项点击事件
				child:SetEvent("MouseClick", string.format("WuLin_List_New_RankListClicked(%d)", i))
			end
		else
			-- 说明没有队伍了 因为排行榜是有序的 说明后面也没有队伍了 退出循环
			break
		end
	end -- end for

	-- 玩家自己的排名信息
	local myRank, myBossMenPai, myTime, myName = JueZhanWuLinZhiDian:GetMyselfRankInfo()
	if (myRank <= 0) then
		-- 未上榜
		-- 排名
		WuLin_List_New_AItem_MyRank:SetText("#{PTFB_191228_166}")
		-- 角色名
		WuLin_List_New_AItem_MyName:SetText(myName)
		-- boss门派
		WuLin_List_New_AItem_MyNum:SetText(" ")
		-- 通关时间
		WuLin_List_New_AItem_MyTime:SetText(" ")
	else
		-- 有排名
		-- 排名
		WuLin_List_New_AItem_MyRank:SetText(tostring(myRank))
		-- 角色名
		WuLin_List_New_AItem_MyName:SetText(myName)
		-- boss门派
		local menpaiName = WuLin_List_New_GetMenPaiName(myBossMenPai)
		WuLin_List_New_AItem_MyNum:SetText(menpaiName)
		-- 通关时间
		local min, sec = WuLin_List_New_GetTimeMinAndSec(myTime)
		local timeStr = string.format("%02d:%02d", min, sec)
		WuLin_List_New_AItem_MyTime:SetText(timeStr)
	end
end -- edn func WuLin_List_New_UpdateRankList()

-- 获取门派名字
function WuLin_List_New_GetMenPaiName(menpai)
	-- for i=1, 14, 1 do
	-- 	if (WuLin_List_New_RankInfo[i] ~= nil) then
	-- 		if (WuLin_List_New_RankInfo[i].menpai == menpai) then
	-- 			return WuLin_List_New_RankInfo[i].name
	-- 		end
	-- 	end
	-- end -- end for

	-- return nil
	return GetMenpaiByID(menpai)
end -- end func WuLin_List_New_GetMenPaiName()

-- 获取通关用时
-- 返回分 秒
function WuLin_List_New_GetTimeMinAndSec(useTime)
	if (useTime <= 0) then
		return -1, -1
	end

	local min = math.floor(useTime / 60)
	local sec = math.mod(useTime, 60)

	return min, sec
end -- end func WuLin_List_New_GetTimeMinAndSec()