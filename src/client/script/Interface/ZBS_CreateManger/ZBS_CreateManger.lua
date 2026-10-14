-- 争霸赛 战队管理UI

-- 服务器端回调脚本ID
local ZBS_CreateManger_ServerScriptId = 998576
-- 战队最大人数
local ZBS_CreateManger_TeamMember_Max = 6
-- 目标NPCID
local ZBS_CreateManger_TargetNPC = -1
-- 当前选中的队员列表索引
local ZBS_CreateManger_SelectedIndex = -1
-- 默认位置
local ZBS_CreateManger_UnifiedPosition = nil
-- 控件表
local ZBS_CreateManger_CtrlList = nil
-- 关注NPC
local ZBS_CreateManger_CareObjId = -1
local ZBS_CreateManger_CareObjSvrId = -1
local ZBS_CreateManger_MAX_OBJ_DISTANCE = 5.0

-- 职位
local ZBS_CreateManger_Post =
{
	Member = 0,		-- 队员
	Deputy = 1,		-- 副队长
	Leader = 2,		-- 队长
} -- end ZBS_CreateManger_Post

-- 门派
local ZBS_CreateManger_MenPaiName =
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
} -- end ZBS_CreateManger_MenPaiName


function ZBS_CreateManger_PreLoad()
	this:RegisterEvent("ZBS_OPENTEAMMANAGER", true)
	this:RegisterEvent("ZBS_CLOSEUI", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
end -- end func ZBS_CreateManger_PreLoad()

function ZBS_CreateManger_OnEvent(event)
	if (event == "ZBS_OPENTEAMMANAGER") then
		ZBS_CreateManger_BeginCareObject(arg0, arg1)
		
		ZBS_CreateManger_Show()
		ZBS_CreateManger_UpdateTeamInfo()

		ZBS_CreateManger_TargetNPC = tonumber(arg0)
	elseif (event == "ZBS_CLOSEUI") then
		ZBS_CreateManger_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ZBS_CreateManger_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZBS_CreateManger_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		ZBS_CreateManger_UnifiedPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(ZBS_CreateManger_CareObjId < 0 or tonumber(arg0) ~= ZBS_CreateManger_CareObjId) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2) > ZBS_CreateManger_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			ZBS_CreateManger_Hide()
		end
	end
end -- end func ZBS_CreateManger_OnEvent()

function ZBS_CreateManger_OnLoad()
	ZBS_CreateManger_UnifiedPosition = ZBS_CreateManger_Frame:GetProperty("UnifiedPosition")
	ZBS_CreateManger_InitCtrlList()
end -- end func ZBS_CreateManger_OnLoad()

-- 界面默认位置
function ZBS_CreateManger_UnifiedPos()
	if (ZBS_CreateManger_UnifiedPosition ~= nil) then
		ZBS_CreateManger_Frame:SetProperty("UnifiedPosition", ZBS_CreateManger_UnifiedPosition)
	end
end -- end func ZBS_CreateManger_UnifiedPos()

function ZBS_CreateManger_Show()
	this:Show()
end -- end func ZBS_CreateManger_Show()

function ZBS_CreateManger_Hide()
	ZBS_CreateManger_StopCareObject()
	this:Hide()
end -- end func ZBS_CreateManger_Hide()

-- 开启NPC关注
function ZBS_CreateManger_BeginCareObject(objSvrId, objId)
	ZBS_CreateManger_CareObjId = tonumber(objId)
	ZBS_CreateManger_CareObjSvrId = tonumber(objSvrId)
	if (ZBS_CreateManger_CareObjId >= 0) then
		this:CareObject(ZBS_CreateManger_CareObjId, 1, "ZBS_CreateManger")
	end
end -- end func ZBS_CreateManger_BeginCareObject()

-- 取消NPC关注
function ZBS_CreateManger_StopCareObject()
	if (ZBS_CreateManger_CareObjId >= 0) then
		this:CareObject(ZBS_CreateManger_CareObjId, 0, "ZBS_CreateManger")
		ZBS_CreateManger_CareObjId = -1
		ZBS_CreateManger_CareObjSvrId = -1
	end
end -- end func ZBS_CreateManger_StopCareObject()

-- 关闭按钮事件
function ZBS_CreateManger_CloseClicked()
	ZBS_CreateManger_Hide()
end -- end func ZBS_CreateManger_CloseClicked()

-- 邀请加入按钮事件
function ZBS_CreateManger_Invite_Clicked()
	-- 判断自己是不是队长或副队长
	local isValid, guidH, guidL, menpai, level, post, consume, name = ZBS:GetMyTeamInfo()
	if (post ~= ZBS_CreateManger_Post.Leader and post ~= ZBS_CreateManger_Post.Deputy) then
		-- 自己不是队长或副队长
		PushDebugMessage("#{WCBZ_180128_115}")
		return -1
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CallBack_TryInvite")
		Set_XSCRIPT_ScriptID(ZBS_CreateManger_ServerScriptId)
		Set_XSCRIPT_Parameter(0, ZBS_CreateManger_TargetNPC)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	ZBS_CreateManger_Hide()
end -- end func ZBS_CreateManger_Invite_Clicked()

-- 任命副队长按钮事件
function ZBS_CreateManger_Leader_Clicked()
	-- 判断自己是不是队长
	if (ZBS:IsLeader() <= 0) then
		-- 自己不是队长
		PushDebugMessage("#{WCBZ_180128_148}")
		return -1
	end

	if (ZBS:IsHasDeputy() > 0) then
		-- 战队中已有副队长
		PushDebugMessage("#{WCBZ_180128_149}")
		return -2
	end

	if (ZBS_CreateManger_SelectedIndex <= 0 or ZBS_CreateManger_SelectedIndex > ZBS_CreateManger_TeamMember_Max) then
		PushDebugMessage("#{WCBZ_180128_150}")
		return -3
	end

	-- 获取选中的队员信息
	local memberName = ZBS_CreateManger_CtrlList[ZBS_CreateManger_SelectedIndex].name:GetText()
	local isValid, guidH, guidL, menpai, level, post, consume, name = ZBS:GetTeamMemberInfoByName(memberName)
	if (isValid <= 0) then
		PushDebugMessage("#{WCBZ_180128_150}")
		return -4
	end
	if (post == ZBS_CreateManger_Post.Leader or post == ZBS_CreateManger_Post.Deputy) then
		PushDebugMessage("#{WCBZ_180128_151}")
		return -5
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CallBack_TryAppointToDeputy")
		Set_XSCRIPT_ScriptID(ZBS_CreateManger_ServerScriptId)
		Set_XSCRIPT_Parameter(0, ZBS_CreateManger_TargetNPC)
		Set_XSCRIPT_Parameter(1, guidH)
		Set_XSCRIPT_Parameter(2, guidL)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	ZBS_CreateManger_Hide()
	return 1
end -- end func ZBS_CreateManger_Leader_Clicked()

-- 解除副队长职务按钮事件
function ZBS_CreateManger_NoLeader_Clicked()
	-- 判断自己是不是队长
	if (ZBS:IsLeader() <= 0) then
		-- 自己不是队长
		PushDebugMessage("#{WCBZ_180128_148}")
		return -1
	end

	if (ZBS:IsHasDeputy() <= 0) then
		-- 战队中没有副队长
		PushDebugMessage("#{WCBZ_180128_153}")
		return -2
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CallBack_TryRemovalDeputy")
		Set_XSCRIPT_ScriptID(ZBS_CreateManger_ServerScriptId)
		Set_XSCRIPT_Parameter(0, ZBS_CreateManger_TargetNPC)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	ZBS_CreateManger_Hide()
	return 1
end -- end func ZBS_CreateManger_NoLeader_Clicked()

-- 解散战队按钮事件
function ZBS_CreateManger_Dismiss_Clicked()
	-- 判断自己是不是队长
	if (ZBS:IsLeader() <= 0) then
		-- 自己不是队长
		PushDebugMessage("#{WCBZ_180128_148}")
		return -1
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CallBack_TryDismiss")
		Set_XSCRIPT_ScriptID(ZBS_CreateManger_ServerScriptId)
		Set_XSCRIPT_Parameter(0, ZBS_CreateManger_TargetNPC)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	ZBS_CreateManger_Hide()
end -- end func ZBS_CreateManger_Dismiss_Clicked()

-- 请离战队按钮事件
function ZBS_CreateManger_PickOut_Clicked()
	-- 判断自己是不是队长
	if (ZBS:IsLeader() <= 0) then
		-- 自己不是队长
		PushDebugMessage("#{WCBZ_180128_148}")
		return -1
	end

	if (ZBS_CreateManger_SelectedIndex <= 0 or ZBS_CreateManger_SelectedIndex > ZBS_CreateManger_TeamMember_Max) then
		PushDebugMessage("#{WCBZ_180128_150}")
		return -2
	end

	-- 获取选中的队员信息
	local memberName = ZBS_CreateManger_CtrlList[ZBS_CreateManger_SelectedIndex].name:GetText()
	local isValid, guidH, guidL, menpai, level, post, consume, name = ZBS:GetTeamMemberInfoByName(memberName)
	if (isValid <= 0) then
		PushDebugMessage("#{WCBZ_180128_150}")
		return -3
	end
	if (post == ZBS_CreateManger_Post.Leader) then
		PushDebugMessage("#{WCBZ_180128_156}")
		return -4
	end
	if (post == ZBS_CreateManger_Post.Deputy) then
		PushDebugMessage("#{WCBZ_180128_160}")
		return -5
	end

	-- 通知server删除队员
	ZBS:DeleteMember(ZBS_CreateManger_TargetNPC, guidH, guidL, memberName)

	ZBS_CreateManger_Hide()
	return 1
end -- end func ZBS_CreateManger_PickOut_Clicked()

-- 退出战队按钮事件
function ZBS_CreateManger_OutTeam_Clicked()
	-- 判断自己是不是队长
	if (ZBS:IsLeader() > 0) then
		-- 自己是队长
		PushDebugMessage("#{WCBZ_180128_169}")
		return -1
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CallBack_TryQuit")
		Set_XSCRIPT_ScriptID(ZBS_CreateManger_ServerScriptId)
		Set_XSCRIPT_Parameter(0, ZBS_CreateManger_TargetNPC)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	ZBS_CreateManger_Hide()
end -- end func ZBS_CreateManger_OutTeam_Clicked()

-- 战队成员列表点击事件
function ZBS_CreateManger_ToggleMemberMenu(arg)
end -- end func ZBS_CreateManger_ToggleMemberMenu()

-- 战队成员列表点击事件
function ZBS_CreateManger_Clicked(arg)
	local index = tonumber(arg)
	if (index <= 0 or index > ZBS_CreateManger_TeamMember_Max) then
		return -1
	end

	ZBS_CreateManger_SelectedIndex = index

	ZBS_CreateManger_UpdateSelect(ZBS_CreateManger_SelectedIndex)

	return index
end -- end func ZBS_CreateManger_Clicked()

-- 战队成员列表点击事件
function ZBS_CreateManger_DragStarted()
end -- end func ZBS_CreateManger_DragStarted()

-- 初始化控件表
function ZBS_CreateManger_InitCtrlList()
	ZBS_CreateManger_CtrlList = {}
	ZBS_CreateManger_CtrlList[1] = {}
	ZBS_CreateManger_CtrlList[1].leaderflag = ZBS_CreateManger_List1_Pic
	ZBS_CreateManger_CtrlList[1].name = ZBS_CreateManger_List1_1
	ZBS_CreateManger_CtrlList[1].menpai = ZBS_CreateManger_List1_2
	ZBS_CreateManger_CtrlList[1].level = ZBS_CreateManger_List1_3
	ZBS_CreateManger_CtrlList[1].score = ZBS_CreateManger_List1_4
	ZBS_CreateManger_CtrlList[1].gaoliang = ZBS_CreateManger_List1_Bk_Gaoliang
	ZBS_CreateManger_CtrlList[2] = {}
	ZBS_CreateManger_CtrlList[2].leaderflag = ZBS_CreateManger_List2_Pic
	ZBS_CreateManger_CtrlList[2].name = ZBS_CreateManger_List2_1
	ZBS_CreateManger_CtrlList[2].menpai = ZBS_CreateManger_List2_2
	ZBS_CreateManger_CtrlList[2].level = ZBS_CreateManger_List2_3
	ZBS_CreateManger_CtrlList[2].score = ZBS_CreateManger_List2_4
	ZBS_CreateManger_CtrlList[2].gaoliang = ZBS_CreateManger_List2_Bk_Gaoliang
	ZBS_CreateManger_CtrlList[3] = {}
	ZBS_CreateManger_CtrlList[3].leaderflag = ZBS_CreateManger_List3_Pic
	ZBS_CreateManger_CtrlList[3].name = ZBS_CreateManger_List3_1
	ZBS_CreateManger_CtrlList[3].menpai = ZBS_CreateManger_List3_2
	ZBS_CreateManger_CtrlList[3].level = ZBS_CreateManger_List3_3
	ZBS_CreateManger_CtrlList[3].score = ZBS_CreateManger_List3_4
	ZBS_CreateManger_CtrlList[3].gaoliang = ZBS_CreateManger_List3_Bk_Gaoliang
	ZBS_CreateManger_CtrlList[4] = {}
	ZBS_CreateManger_CtrlList[4].leaderflag = ZBS_CreateManger_List4_Pic
	ZBS_CreateManger_CtrlList[4].name = ZBS_CreateManger_List4_1
	ZBS_CreateManger_CtrlList[4].menpai = ZBS_CreateManger_List4_2
	ZBS_CreateManger_CtrlList[4].level = ZBS_CreateManger_List4_3
	ZBS_CreateManger_CtrlList[4].score = ZBS_CreateManger_List4_4
	ZBS_CreateManger_CtrlList[4].gaoliang = ZBS_CreateManger_List4_Bk_Gaoliang
	ZBS_CreateManger_CtrlList[5] = {}
	ZBS_CreateManger_CtrlList[5].leaderflag = ZBS_CreateManger_List5_Pic
	ZBS_CreateManger_CtrlList[5].name = ZBS_CreateManger_List5_1
	ZBS_CreateManger_CtrlList[5].menpai = ZBS_CreateManger_List5_2
	ZBS_CreateManger_CtrlList[5].level = ZBS_CreateManger_List5_3
	ZBS_CreateManger_CtrlList[5].score = ZBS_CreateManger_List5_4
	ZBS_CreateManger_CtrlList[5].gaoliang = ZBS_CreateManger_List5_Bk_Gaoliang
	ZBS_CreateManger_CtrlList[6] = {}
	ZBS_CreateManger_CtrlList[6].leaderflag = ZBS_CreateManger_List6_Pic
	ZBS_CreateManger_CtrlList[6].name = ZBS_CreateManger_List6_1
	ZBS_CreateManger_CtrlList[6].menpai = ZBS_CreateManger_List6_2
	ZBS_CreateManger_CtrlList[6].level = ZBS_CreateManger_List6_3
	ZBS_CreateManger_CtrlList[6].score = ZBS_CreateManger_List6_4
	ZBS_CreateManger_CtrlList[6].gaoliang = ZBS_CreateManger_List6_Bk_Gaoliang
	-- ZBS_CreateManger_CtrlList[7] = {}
	-- ZBS_CreateManger_CtrlList[7].leaderflag = ZBS_CreateManger_List7_Pic
	-- ZBS_CreateManger_CtrlList[7].name = ZBS_CreateManger_List7_1
	-- ZBS_CreateManger_CtrlList[7].menpai = ZBS_CreateManger_List7_2
	-- ZBS_CreateManger_CtrlList[7].level = ZBS_CreateManger_List7_3
	-- ZBS_CreateManger_CtrlList[7].gaoliang = ZBS_CreateManger_List7_Bk_Gaoliang
	-- ZBS_CreateManger_CtrlList[8] = {}
	-- ZBS_CreateManger_CtrlList[8].leaderflag = ZBS_CreateManger_List8_Pic
	-- ZBS_CreateManger_CtrlList[8].name = ZBS_CreateManger_List8_1
	-- ZBS_CreateManger_CtrlList[8].menpai = ZBS_CreateManger_List8_2
	-- ZBS_CreateManger_CtrlList[8].level = ZBS_CreateManger_List8_3
	-- ZBS_CreateManger_CtrlList[8].gaoliang = ZBS_CreateManger_List8_Bk_Gaoliang
end -- end func ZBS_CreateManger_InitCtrlList()

-- 刷新选择高亮显示
function ZBS_CreateManger_UpdateSelect(selectIndex)
	for i=1, ZBS_CreateManger_TeamMember_Max, 1 do
		local memberCtrl = ZBS_CreateManger_CtrlList[i]
		if (memberCtrl ~= nil and memberCtrl.gaoliang ~= nil) then
			memberCtrl.gaoliang:Hide()
		end
	end -- end for

	if (selectIndex > 0) then
		local ctrl = ZBS_CreateManger_CtrlList[selectIndex]
		if (ctrl ~= nil and ctrl.gaoliang ~= nil) then
			ctrl.gaoliang:Show()
		end
	end
end -- end func ZBS_CreateManger_UpdateSelect()

-- 刷新战队数据
function ZBS_CreateManger_UpdateTeamInfo()
	if (ZBS_CreateManger_CtrlList == nil) then
		ZBS_CreateManger_InitCtrlList()
	end

	ZBS_CreateManger_UpdateSelect(-1)

	ZBS_CreateManger_SelectedIndex = -1

	if (ZBS:IsLeader() > 0) then
		-- 自己是队长
		ZBS_CreateManger_AddMember:Enable()			-- 邀请按钮
		if (ZBS:IsHasDeputy() > 0) then
			-- 已有副队长 屏蔽任命副队长按钮
			ZBS_CreateManger_ViceLeader:Disable()	-- 任命副队长按钮
			ZBS_CreateManger_NoLeader:Enable()		-- 解除副队长任命按钮
		else
			-- 没有副队长 屏蔽解除副队长按钮
			ZBS_CreateManger_NoLeader:Disable()		-- 解除副队长任命按钮
			ZBS_CreateManger_ViceLeader:Enable()	-- 任命副队长按钮
		end
		ZBS_CreateManger_Dissolve:Enable()			-- 解散战队按钮
		ZBS_CreateManger_Fire:Enable()				-- 请离战队按钮
		ZBS_CreateManger_Leave:Enable()				-- 退出战队按钮
	elseif (ZBS:IsDeputy() > 0) then
		-- 自己是副队长
		ZBS_CreateManger_AddMember:Enable()			-- 邀请按钮
		ZBS_CreateManger_ViceLeader:Disable()		-- 任命副队长按钮
		ZBS_CreateManger_NoLeader:Disable()			-- 解除副队长任命按钮
		ZBS_CreateManger_Dissolve:Disable()			-- 解散战队按钮
		ZBS_CreateManger_Fire:Disable()				-- 请离战队按钮
		ZBS_CreateManger_Leave:Enable()				-- 退出战队按钮
	else
		-- 自己是队员
		ZBS_CreateManger_AddMember:Disable()		-- 邀请按钮
		ZBS_CreateManger_ViceLeader:Disable()		-- 任命副队长按钮
		ZBS_CreateManger_NoLeader:Disable()			-- 解除副队长任命按钮
		ZBS_CreateManger_Dissolve:Disable()			-- 解散战队按钮
		ZBS_CreateManger_Fire:Disable()				-- 请离战队按钮
		ZBS_CreateManger_Leave:Enable()				-- 退出战队按钮
	end

	for i=1, ZBS_CreateManger_TeamMember_Max, 1 do
		local memberCtrl = ZBS_CreateManger_CtrlList[i]
		memberCtrl.leaderflag:Hide()
		memberCtrl.name:Hide()
		memberCtrl.menpai:Hide()
		memberCtrl.level:Hide()
		memberCtrl.score:Hide()
	end -- end for

	local totalConsume = 0
	local ctrlIndex = 1
	for i=1, ZBS_CreateManger_TeamMember_Max, 1 do
		local memberCtrl = ZBS_CreateManger_CtrlList[ctrlIndex]
		local isValid, guidH, guidL, menpai, level, post, consume, name = ZBS:GetTeamMemberInfo(i-1)
		if (isValid > 0) then
			ctrlIndex = ctrlIndex + 1
			local menpaiName = ZBS_CreateManger_MenPaiName[menpai]
			if (post == ZBS_CreateManger_Post.Leader) then
				memberCtrl.leaderflag:Show()
			elseif (post == ZBS_CreateManger_Post.Deputy) then
				memberCtrl.leaderflag:Show()
			else
				memberCtrl.leaderflag:Hide()
			end

			memberCtrl.name:Show()
			memberCtrl.name:SetText(name)

			memberCtrl.menpai:Show()
			memberCtrl.menpai:SetText(menpaiName)
			
			memberCtrl.level:Show()
			memberCtrl.level:SetText(tostring(level))

			memberCtrl.score:Show()
			memberCtrl.score:SetText(tostring(consume))

			totalConsume = totalConsume + consume
		end
	end -- end for

	--local totalScore = ScriptGlobal_Format("#{WCBZ_180128_616}", totalConsume)
	--ZBS_CreateManger_TeamScore:SetText(totalScore)

	local teamName = ZBS:GetTeamName()
	local teamNameStr = ScriptGlobal_Format("#{WCBZ_180128_87}", teamName)
	ZBS_CreateManger_DragTitle:SetText(teamNameStr)
end -- end func ZBS_CreateManger_UpdateTeamInfo()