-- 争霸赛 组建战队UI

-- 服务器端回调脚本ID
local ZBS_CreateTeam_ServerScriptId = 998576
-- 战队名称最大长度
local ZBS_CreateTeam_NameLen_Max = 12
-- NPC id（缓存一下）
local ZBS_CreateTeam_TargetId = -1
-- 默认位置
local ZBS_CreateTeam_UnifiedPosition = nil
-- 控件表
local ZBS_CreateTeam_CtrlList = nil
-- 关注NPC
local ZBS_CreateTeam_CareObjId = -1
local ZBS_CreateTeam_CareObjSvrId = -1
local ZBS_CreateTeam_MAX_OBJ_DISTANCE = 5.0

-- 职位
local ZBS_CreateTeam_Post =
{
	Member = 0,		-- 队员
	Deputy = 1,		-- 副队长
	Leader = 2,		-- 队长
} -- end ZBS_CreateTeam_Post

-- 门派
local ZBS_CreateTeam_MenPaiName =
{
	[0] = "#{XQ_MP_1}",    	--少林
	[1] = "#{XQ_MP_2}",    	--明教
	[2] = "#{XQ_MP_3}",    	--丐帮
	[3] = "#{XQ_MP_4}",    	--武当
	[4] = "#{XQ_MP_5}",    	--峨眉
	[5] = "#{XQ_MP_6}",    	--星宿
	[6] = "#{XQ_MP_7}",    	--天龙
	[7] = "#{XQ_MP_8}",    	--天山
	[8] = "#{XQ_MP_9}",    	--逍遥
	[9] = "",         	--无门派
	[10] = "#{XQ_MP_10}",	--慕容
	[11] = "#{XQ_MP_13}",  	--唐门
	[12] = "#{XQ_MP_14}",  	--鬼谷
    [13] = "#{XQ_MP_15}",  	--桃花岛
	[14] = "#{XQ_MP_16}", 	--绝情谷
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}", 	--menpai15 mptodo
} -- end ZBS_CreateTeam_MenPaiName


function ZBS_CreateTeam_PreLoad()
	this:RegisterEvent("ZBS_OPENCREATETEAM", true)
	this:RegisterEvent("ZBS_CLOSEUI", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
end -- end func ZBS_CreateTeam_PreLoad()

function ZBS_CreateTeam_OnEvent(event)
	if (event == "ZBS_OPENCREATETEAM") then
		ZBS_CreateTeam_TargetId = tonumber(arg0)
		ZBS_CreateTeam_BeginCareObject(arg0, arg1)
		ZBS_CreateTeam_Show()
		ZBS_CreateTeam_UpdateTeamInfo()
	elseif (event == "ZBS_CLOSEUI") then
		ZBS_CreateTeam_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ZBS_CreateTeam_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZBS_CreateTeam_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		ZBS_CreateTeam_UnifiedPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(ZBS_CreateTeam_CareObjId < 0 or tonumber(arg0) ~= ZBS_CreateTeam_CareObjId) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2) > ZBS_CreateTeam_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			ZBS_CreateTeam_Hide()
		end
	end
end -- end func ZBS_CreateTeam_OnEvent()

function ZBS_CreateTeam_OnLoad()
	ZBS_CreateTeam_UnifiedPosition = ZBS_CreateTeam_Frame:GetProperty("UnifiedPosition")
	ZBS_CreateTeam_InitCtrlList()
end -- end func ZBS_CreateTeam_OnLoad()

-- 界面默认位置
function ZBS_CreateTeam_UnifiedPos()
	if (ZBS_CreateTeam_UnifiedPosition ~= nil) then
		ZBS_CreateTeam_Frame:SetProperty("UnifiedPosition", ZBS_CreateTeam_UnifiedPosition)
	end
end -- end func ZBS_CreateTeam_UnifiedPos()

function ZBS_CreateTeam_Show()
	this:Show()
end -- end func ZBS_CreateTeam_Show()

function ZBS_CreateTeam_Hide()
	ZBS_CreateTeam_StopCareObject()
	this:Hide()
end -- end func ZBS_CreateTeam_Hide()

-- 开启NPC关注
function ZBS_CreateTeam_BeginCareObject(objSvrId, objId)
	ZBS_CreateTeam_CareObjId = tonumber(objId)
	ZBS_CreateTeam_CareObjSvrId = tonumber(objSvrId)
	if (ZBS_CreateTeam_CareObjId >= 0) then
		this:CareObject(ZBS_CreateTeam_CareObjId, 1, "ZBS_CreateTeam")
	end
end -- end func ZBS_CreateTeam_BeginCareObject()

-- 取消NPC关注
function ZBS_CreateTeam_StopCareObject(objId)
	if (ZBS_CreateTeam_CareObjId >= 0) then
		this:CareObject(ZBS_CreateTeam_CareObjId, 0, "ZBS_CreateTeam")
		ZBS_CreateTeam_CareObjId = -1
		ZBS_CreateTeam_CareObjSvrId = -1
	end
end -- end func ZBS_CreateTeam_StopCareObject()

-- 初始化控件表
function ZBS_CreateTeam_InitCtrlList()
	ZBS_CreateTeam_CtrlList = {}

	ZBS_CreateTeam_CtrlList.member = {}
	ZBS_CreateTeam_CtrlList.member[1] = {}
	ZBS_CreateTeam_CtrlList.member[1].leaderflag = ZBS_CreateTeam_List1_Pic
	ZBS_CreateTeam_CtrlList.member[1].name = ZBS_CreateTeam_List1_1
	ZBS_CreateTeam_CtrlList.member[1].menpai = ZBS_CreateTeam_List1_2
	ZBS_CreateTeam_CtrlList.member[1].level = ZBS_CreateTeam_List1_3
	ZBS_CreateTeam_CtrlList.member[1].score = ZBS_CreateTeam_List1_4
	ZBS_CreateTeam_CtrlList.member[2] = {}
	ZBS_CreateTeam_CtrlList.member[2].leaderflag = ZBS_CreateTeam_List2_Pic
	ZBS_CreateTeam_CtrlList.member[2].name = ZBS_CreateTeam_List2_1
	ZBS_CreateTeam_CtrlList.member[2].menpai = ZBS_CreateTeam_List2_2
	ZBS_CreateTeam_CtrlList.member[2].level = ZBS_CreateTeam_List2_3
	ZBS_CreateTeam_CtrlList.member[2].score = ZBS_CreateTeam_List2_4
	ZBS_CreateTeam_CtrlList.member[3] = {}
	ZBS_CreateTeam_CtrlList.member[3].leaderflag = ZBS_CreateTeam_List3_Pic
	ZBS_CreateTeam_CtrlList.member[3].name = ZBS_CreateTeam_List3_1
	ZBS_CreateTeam_CtrlList.member[3].menpai = ZBS_CreateTeam_List3_2
	ZBS_CreateTeam_CtrlList.member[3].level = ZBS_CreateTeam_List3_3
	ZBS_CreateTeam_CtrlList.member[3].score = ZBS_CreateTeam_List3_4
	ZBS_CreateTeam_CtrlList.member[4] = {}
	ZBS_CreateTeam_CtrlList.member[4].leaderflag = ZBS_CreateTeam_List4_Pic
	ZBS_CreateTeam_CtrlList.member[4].name = ZBS_CreateTeam_List4_1
	ZBS_CreateTeam_CtrlList.member[4].menpai = ZBS_CreateTeam_List4_2
	ZBS_CreateTeam_CtrlList.member[4].level = ZBS_CreateTeam_List4_3
	ZBS_CreateTeam_CtrlList.member[4].score = ZBS_CreateTeam_List4_4
	ZBS_CreateTeam_CtrlList.member[5] = {}
	ZBS_CreateTeam_CtrlList.member[5].leaderflag = ZBS_CreateTeam_List5_Pic
	ZBS_CreateTeam_CtrlList.member[5].name = ZBS_CreateTeam_List5_1
	ZBS_CreateTeam_CtrlList.member[5].menpai = ZBS_CreateTeam_List5_2
	ZBS_CreateTeam_CtrlList.member[5].level = ZBS_CreateTeam_List5_3
	ZBS_CreateTeam_CtrlList.member[5].score = ZBS_CreateTeam_List5_4
	ZBS_CreateTeam_CtrlList.member[6] = {}
	ZBS_CreateTeam_CtrlList.member[6].leaderflag = ZBS_CreateTeam_List6_Pic
	ZBS_CreateTeam_CtrlList.member[6].name = ZBS_CreateTeam_List6_1
	ZBS_CreateTeam_CtrlList.member[6].menpai = ZBS_CreateTeam_List6_2
	ZBS_CreateTeam_CtrlList.member[6].level = ZBS_CreateTeam_List6_3
	ZBS_CreateTeam_CtrlList.member[6].score = ZBS_CreateTeam_List6_4
end -- end func ZBS_CreateTeam_InitCtrlList()

-- 关闭按钮事件
function ZBS_CreateTeam_CloseClicked()
	ZBS_CreateTeam_Hide()
end -- end func ZBS_CreateTeam_CloseClicked()

-- 创建战队按钮事件
function ZBS_CreateTeam_Accept_Clicked()
	local teamName = ZBS_CreateTeam_Top_NameInput:GetText()
	if (teamName == nil or teamName == "") then
		PushDebugMessage("#{WCBZ_180128_73}")
		return
	end
	if (string.len(teamName) > ZBS_CreateTeam_NameLen_Max) then
		PushDebugMessage("#{WCBZ_180128_74}")
		return
	end

	ZBS:CreateTeam(ZBS_CreateTeam_TargetId, teamName)

	ZBS_CreateTeam_Hide()
end -- end func ZBS_CreateTeam_Accept_Clicked()

function ZBS_CreateTeam_Top_NameInputNull_Clicked()
	-- ZBS_CreateTeam_Top_NameInputNull:Hide()
	-- ZBS_CreateTeam_Top_NameInput:SetText("")

	-- -- 设置焦点
	-- ZBS_CreateTeam_Top_NameInput:SetProperty("DefaultEditBox", "True")
end -- end func ZBS_CreateTeam_Top_NameInputNull_Clicked()

-- 重置UI显示
function ZBS_CreateTeam_ResetUIInfo()
	if (ZBS_CreateTeam_CtrlList == nil) then
		ZBS_CreateTeam_InitCtrlList()
	end

	-- 战队名称
	ZBS_CreateTeam_Top_NameInput:SetText("")
	-- 战队人数
	local numText = ScriptGlobal_Format("#{WCBZ_180128_50}", 0)
	ZBS_CreateTeam_Top_Text3:SetText(numText)
	-- 战队成员
	for i=0, 6, 1 do
		if (ZBS_CreateTeam_CtrlList.member[i] ~= nil) then
			ZBS_CreateTeam_CtrlList.member[i].leaderflag:Hide()
			ZBS_CreateTeam_CtrlList.member[i].name:Hide()
			ZBS_CreateTeam_CtrlList.member[i].menpai:Hide()
			ZBS_CreateTeam_CtrlList.member[i].level:Hide()
			ZBS_CreateTeam_CtrlList.member[i].score:Hide()
		end
	end -- end for
end -- end func ZBS_CreateTeam_ResetUIInfo()

-- 刷新战队信息
function ZBS_CreateTeam_UpdateTeamInfo()
	ZBS_CreateTeam_ResetUIInfo()

	ZBS_CreateTeam_Top_NameInput:SetText("")
	--ZBS_CreateTeam_Top_NameInputNull:Hide()

	local memCount = 0
	-- 刷新战队成员信息
	for i=1, 6, 1 do
		-- local memName, memMenPai, memLevel, memDeadFlag, memLinkFlag, memSex, memZoneWorld, memScore = DataPool:GetTeamMemInfoByIndex(i-1)
		-- local playerName, playerGUID, playerIcon, leaderFlag, isDead = DataPool:GetTeamMemInfoExByIndex(i-1)
		local isValid, guidH, guidL, menpai, level, post, consume, name = ZBS:GetTeamMemberInfo(i-1)
		if (ZBS_CreateTeam_CtrlList.member[i] ~= nil) then
			if (isValid > 0) then
				if (post == ZBS_CreateTeam_Post.Leader) then
					ZBS_CreateTeam_CtrlList.member[i].leaderflag:Show()
				else
					ZBS_CreateTeam_CtrlList.member[i].leaderflag:Hide()
				end
				ZBS_CreateTeam_CtrlList.member[i].name:Show()
				ZBS_CreateTeam_CtrlList.member[i].menpai:Show()
				ZBS_CreateTeam_CtrlList.member[i].level:Show()
				ZBS_CreateTeam_CtrlList.member[i].score:Show()

				ZBS_CreateTeam_CtrlList.member[i].name:SetText(name)
				if (ZBS_CreateTeam_MenPaiName[menpai] ~= nil) then
					ZBS_CreateTeam_CtrlList.member[i].menpai:SetText(ZBS_CreateTeam_MenPaiName[menpai])
				else
					ZBS_CreateTeam_CtrlList.member[i].menpai:SetText(ZBS_CreateTeam_MenPaiName[9])
				end
				ZBS_CreateTeam_CtrlList.member[i].level:SetText(tostring(level))
				ZBS_CreateTeam_CtrlList.member[i].score:SetText(tostring(consume))

				memCount = memCount + 1
			else
				ZBS_CreateTeam_CtrlList.member[i].leaderflag:Hide()
				ZBS_CreateTeam_CtrlList.member[i].name:Hide()
				ZBS_CreateTeam_CtrlList.member[i].menpai:Hide()
				ZBS_CreateTeam_CtrlList.member[i].level:Hide()
				ZBS_CreateTeam_CtrlList.member[i].score:Hide()
			end
		end
	end -- end for

	-- 战队人数
	local numText = ScriptGlobal_Format("#{WCBZ_180128_50}", memCount)
	ZBS_CreateTeam_Top_Text3:SetText(numText)

	-- 设置焦点
	ZBS_CreateTeam_Top_NameInput:SetProperty("DefaultEditBox", "True")
end -- end func ZBS_CreateTeam_UpdateTeamInfo()