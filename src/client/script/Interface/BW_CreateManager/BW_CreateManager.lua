-- 新6v6 战队管理UI

-- 服务器端回调脚本ID
local g_ServerScriptId = 999554
-- 战队最大人数
local g_TeamMember_Max = 6
-- 当前选中的队员列表索引
local g_SelectedIndex = -1
-- 神剑段位id
local g_ShenJianDuanWei = 6
-- 关注NPC
local g_CareObjId = -1
local g_CareObjSvrId = -1
local g_MAX_OBJ_DISTANCE = 5.0
-- 默认位置
local g_UnifiedPosition = nil
-- 控件表
local g_CtrlList = nil

-- 职位
local g_Post =
{
	Member = 0,		-- 队员
	Deputy = 1,		-- 副队长
	Leader = 2,		-- 队长
} -- end g_Post

local g_DuanWei1Str =
{
	[1] = "#{BWDH_180804_131}",
	[2] = "#{BWDH_180804_132}",
	[3] = "#{BWDH_180804_133}",
	[4] = "#{BWDH_180804_134}",
	[5] = "#{BWDH_180804_135}",
	[6] = "#{BWDH_180804_136}",
} -- end g_DuanWei1Str

local g_DuanWei2Str =
{
	[1] = "#{BWDH_180804_153}",
	[2] = "#{BWDH_180804_152}",
	[3] = "#{BWDH_180804_151}",
	[4] = "#{BWDH_180804_150}",
	[5] = "#{BWDH_180804_149}",
} -- end g_DuanWei2Str



function BW_CreateManager_PreLoad()
	this:RegisterEvent("XBW_OPENTEAMMANAGE", true)
	this:RegisterEvent("XBW_UPDATEAMMANAGE", false)
	this:RegisterEvent("XBW_CLOSETEAMMANAGE", true)
	this:RegisterEvent("XBW_CLOSEUI", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
end -- end func BW_CreateManager_PreLoad()

function BW_CreateManager_OnEvent(event)
	if (event == "XBW_OPENTEAMMANAGE") then
		BW_CreateManager_BeginCareObject(arg0, arg1)
		
		BW_CreateManager_Show()
		BW_CreateManager_UpdateTeamInfo()
	elseif (event == "XBW_UPDATEAMMANAGE") then
		BW_CreateManager_UpdateTeamInfo()
	elseif (event == "XBW_CLOSETEAMMANAGE") then
		BW_CreateManager_Hide()
	elseif (event == "XBW_CLOSEUI") then
		BW_CreateManager_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BW_CreateManager_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BW_CreateManager_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		BW_CreateManager_UnifiedPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(g_CareObjId < 0 or tonumber(arg0) ~= g_CareObjId) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2) > g_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			BW_CreateManager_Hide()
		end
	end
end -- end func BW_CreateManager_OnEvent()

function BW_CreateManager_OnLoad()
	g_UnifiedPosition = BW_CreateManager_Frame:GetProperty("UnifiedPosition")
	BW_CreateManager_InitCtrlList()
end -- end func BW_CreateManager_OnLoad()

-- 界面默认位置
function BW_CreateManager_UnifiedPos()
	if (g_UnifiedPosition ~= nil) then
		BW_CreateManager_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
	end
end -- end func BW_CreateManager_UnifiedPos()

function BW_CreateManager_Show()
	this:Show()

	PushEvent("XBW_CLOSECREATETEAM")
end -- end func BW_CreateManager_Show()

function BW_CreateManager_Hide()
	BW_CreateManager_StopCareObject()
	this:Hide()
end -- end func BW_CreateManager_Hide()

-- 开启NPC关注
function BW_CreateManager_BeginCareObject(objSvrId, objId)
	g_CareObjId = tonumber(objId)
	g_CareObjSvrId = tonumber(objSvrId)
	if (g_CareObjId >= 0) then
		this:CareObject(g_CareObjId, 1, "BW_CreateManager")
	end
end -- end func BW_CreateManager_BeginCareObject()

-- 取消NPC关注
function BW_CreateManager_StopCareObject()
	if (g_CareObjId >= 0) then
		this:CareObject(g_CareObjId, 0, "BW_CreateManager")
		g_CareObjId = -1
		g_CareObjSvrId = -1
	end
end -- end func BW_CreateManager_StopCareObject()

-- 关闭按钮事件
function BW_CreateManager_CloseClicked()
	BW_CreateManager_Hide()
end -- end func BW_CreateManager_CloseClicked()

-- 邀请加入按钮事件
function BW_CreateManager_Invite_Clicked()
	-- 判断自己是不是队长或副队长
	local guid, menpai, level, post, score, name = NewXBW:GetMyTeamInfo()
	if (post ~= g_Post.Leader and post ~= g_Post.Deputy) then
		-- 自己不是队长或副队长
		PushDebugMessage("#{BWDH_241114_132}")
		return -1
	end

	local memcount = BW_CreateManager_GetTeamMemCount()
	if memcount >= g_TeamMember_Max then
		PushDebugMessage("#{BWDH_241114_125}")
		return -1
	end	

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CCallBack_TryInvite")
		Set_XSCRIPT_ScriptID(g_ServerScriptId)
		Set_XSCRIPT_Parameter(0, g_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	--BW_CreateManager_Hide()
end -- end func BW_CreateManager_Invite_Clicked()

-- 任命副队长按钮事件
function BW_CreateManager_Leader_Clicked()
	-- 判断自己是不是队长
	if (NewXBW:IsLeader() <= 0) then
		-- 自己不是队长
		PushDebugMessage("#{BWDH_241114_132}")
		return -1
	end

	if (NewXBW:IsHasDeputy() > 0) then
		-- 战队中已有副队长
		PushDebugMessage("#{BWDH_241114_134}")
		return -2
	end

	if (g_SelectedIndex <= 0 or g_SelectedIndex > g_TeamMember_Max) then
		PushDebugMessage("#{BWDH_241114_135}")
		return -3
	end

	-- 获取选中的队员信息
	-- local memberName = g_CtrlList[g_SelectedIndex].name:GetText()
	-- local guid, menpai, level, post, consume, duanwei1, duanwei2, dunawei3, name = NewXBW:GetMyTeamMemberInfoByName(memberName)
	local guid, menpai, level, post, consume, duanwei1, duanwei2, dunawei3, name = NewXBW:GetMyTeamMemberInfo(g_SelectedIndex-1)
	if (guid == "") then
		PushDebugMessage("#{BWDH_241114_135}")
		return -4
	end
	if (post == g_Post.Leader or post == g_Post.Deputy) then
		PushDebugMessage("#{BWDH_241114_136}")
		return -5
	end
	
	local guidH, guidL = SplitGUID64(guid);
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CCallBack_TryAppointToDeputy")
		Set_XSCRIPT_ScriptID(g_ServerScriptId)
		Set_XSCRIPT_Parameter(0, g_CareObjSvrId)
		Set_XSCRIPT_Parameter(1, guidH)
		Set_XSCRIPT_Parameter(2, guidL)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	--BW_CreateManager_Hide()
	return 1
end -- end func BW_CreateManager_Leader_Clicked()

-- 解除副队长职务按钮事件
function BW_CreateManager_NoLeader_Clicked()
	-- 判断自己是不是队长
	if (NewXBW:IsLeader() <= 0) then
		-- 自己不是队长
		PushDebugMessage("#{BWDH_241114_132}")
		return -1
	end

	if (NewXBW:IsHasDeputy() <= 0) then
		-- 战队中没有副队长
		PushDebugMessage("#{BWDH_241114_141}")
		return -2
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CCallBack_TryRemovalDeputy")
		Set_XSCRIPT_ScriptID(g_ServerScriptId)
		Set_XSCRIPT_Parameter(0, g_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	--BW_CreateManager_Hide()
	return 1
end -- end func BW_CreateManager_NoLeader_Clicked()

-- 解散战队按钮事件
function BW_CreateManager_Dismiss_Clicked()
	-- 判断自己是不是队长
	if (NewXBW:IsLeader() <= 0) then
		-- 自己不是队长
		PushDebugMessage("#{BWDH_241114_132}")
		return -1
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CCallBack_TryDismiss")
		Set_XSCRIPT_ScriptID(g_ServerScriptId)
		Set_XSCRIPT_Parameter(0, g_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	BW_CreateManager_Hide()
end -- end func BW_CreateManager_Dismiss_Clicked()

-- 请离战队按钮事件
function BW_CreateManager_PickOut_Clicked()
	-- 判断自己是不是队长
	if (NewXBW:IsLeader() <= 0) then
		-- 自己不是队长
		PushDebugMessage("#{BWDH_241114_132}")
		return -1
	end

	if (g_SelectedIndex <= 0 or g_SelectedIndex > g_TeamMember_Max) then
		PushDebugMessage("#{BWDH_241114_135}")
		return -2
	end

	-- 获取选中的队员信息
	-- local memberName = g_CtrlList[g_SelectedIndex].name:GetText()
	-- local guid, menpai, level, post, consume, duanwei1, duanwei2, dunawei3, name = NewXBW:GetMyTeamMemberInfoByName(memberName)
	local guid, menpai, level, post, consume, duanwei1, duanwei2, dunawei3, name = NewXBW:GetMyTeamMemberInfo(g_SelectedIndex-1)
	if (guid == "") then
		PushDebugMessage("#{BWDH_241114_135}")
		return -3
	end
	if (post == g_Post.Leader) then
		PushDebugMessage("#{BWDH_241114_149}")
		return -4
	end
	if (post == g_Post.Deputy) then
		PushDebugMessage("#{BWDH_241114_150}")
		return -5
	end

	-- 通知server删除队员
	NewXBW:DeleteMember(g_CareObjSvrId, guid, name)

	--BW_CreateManager_Hide()
	return 1
end -- end func BW_CreateManager_PickOut_Clicked()

-- 退出战队按钮事件
function BW_CreateManager_OutTeam_Clicked()
	-- 判断自己是不是队长
	if (NewXBW:IsLeader() > 0) then
		-- 自己是队长
		PushDebugMessage("#{BWDH_241114_159}")
		return -1
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CCallBack_TryQuit")
		Set_XSCRIPT_ScriptID(g_ServerScriptId)
		Set_XSCRIPT_Parameter(0, g_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	BW_CreateManager_Hide()
end -- end func BW_CreateManager_OutTeam_Clicked()

-- 战队成员列表点击事件
function BW_CreateManager_ToggleMemberMenu(arg)
end -- end func BW_CreateManager_ToggleMemberMenu()

-- 战队成员列表点击事件
function BW_CreateManager_Clicked(arg)
	local index = tonumber(arg)
	if (index <= 0 or index > g_TeamMember_Max) then
		return -1
	end

	g_SelectedIndex = index

	BW_CreateManager_UpdateSelect(g_SelectedIndex)

	return index
end -- end func BW_CreateManager_Clicked()

-- 战队成员列表点击事件
function BW_CreateManager_DragStarted()
end -- end func BW_CreateManager_DragStarted()

-- 初始化控件表
function BW_CreateManager_InitCtrlList()
	g_CtrlList = {}
	g_CtrlList[1] = {}
	g_CtrlList[1].leaderflag = BW_CreateManager_List1_Pic
	g_CtrlList[1].name = BW_CreateManager_List1_1
	g_CtrlList[1].menpai = BW_CreateManager_List1_2
	g_CtrlList[1].level = BW_CreateManager_List1_3
	g_CtrlList[1].duanwei = BW_CreateManager_List1_4
	g_CtrlList[1].gaoliang = BW_CreateManager_List1_Bk --高亮
	g_CtrlList[1].drag = BW_CreateManager_List1_Btn
	g_CtrlList[2] = {}
	g_CtrlList[2].leaderflag = BW_CreateManager_List2_Pic
	g_CtrlList[2].name = BW_CreateManager_List2_1
	g_CtrlList[2].menpai = BW_CreateManager_List2_2
	g_CtrlList[2].level = BW_CreateManager_List2_3
	g_CtrlList[2].duanwei = BW_CreateManager_List2_4
	g_CtrlList[2].gaoliang = BW_CreateManager_List2_Bk
	g_CtrlList[2].drag = BW_CreateManager_List2_Btn
	g_CtrlList[3] = {}
	g_CtrlList[3].leaderflag = BW_CreateManager_List3_Pic
	g_CtrlList[3].name = BW_CreateManager_List3_1
	g_CtrlList[3].menpai = BW_CreateManager_List3_2
	g_CtrlList[3].level = BW_CreateManager_List3_3
	g_CtrlList[3].duanwei = BW_CreateManager_List3_4
	g_CtrlList[3].gaoliang = BW_CreateManager_List3_Bk
	g_CtrlList[3].drag = BW_CreateManager_List3_Btn
	g_CtrlList[4] = {}
	g_CtrlList[4].leaderflag = BW_CreateManager_List4_Pic
	g_CtrlList[4].name = BW_CreateManager_List4_1
	g_CtrlList[4].menpai = BW_CreateManager_List4_2
	g_CtrlList[4].level = BW_CreateManager_List4_3
	g_CtrlList[4].duanwei = BW_CreateManager_List4_4
	g_CtrlList[4].gaoliang = BW_CreateManager_List4_Bk
	g_CtrlList[4].drag = BW_CreateManager_List4_Btn
	g_CtrlList[5] = {}
	g_CtrlList[5].leaderflag = BW_CreateManager_List5_Pic
	g_CtrlList[5].name = BW_CreateManager_List5_1
	g_CtrlList[5].menpai = BW_CreateManager_List5_2
	g_CtrlList[5].level = BW_CreateManager_List5_3
	g_CtrlList[5].duanwei = BW_CreateManager_List5_4
	g_CtrlList[5].gaoliang = BW_CreateManager_List5_Bk
	g_CtrlList[5].drag = BW_CreateManager_List5_Btn
	g_CtrlList[6] = {}
	g_CtrlList[6].leaderflag = BW_CreateManager_List6_Pic
	g_CtrlList[6].name = BW_CreateManager_List6_1
	g_CtrlList[6].menpai = BW_CreateManager_List6_2
	g_CtrlList[6].level = BW_CreateManager_List6_3
	g_CtrlList[6].duanwei = BW_CreateManager_List6_4
	g_CtrlList[6].gaoliang = BW_CreateManager_List6_Bk
	g_CtrlList[6].drag = BW_CreateManager_List6_Btn
end -- end func BW_CreateManager_InitCtrlList()

-- 刷新选择高亮显示
function BW_CreateManager_UpdateSelect(selectIndex)
	for i=1, g_TeamMember_Max, 1 do
		local memberCtrl = g_CtrlList[i]
		if (memberCtrl ~= nil) then
			memberCtrl.gaoliang:SetProperty("HoverState", "False")
		end
	end -- end for

	if (selectIndex > 0) then
		local ctrl = g_CtrlList[selectIndex]
		if (ctrl ~= nil) then
			ctrl.gaoliang:SetProperty("HoverState", "True")
		end
	end
end -- end func BW_CreateManager_UpdateSelect()

-- 刷新战队数据
function BW_CreateManager_UpdateTeamInfo()
	if (g_CtrlList == nil) then
		BW_CreateManager_InitCtrlList()
	end

	BW_CreateManager_UpdateSelect(-1)

	g_SelectedIndex = -1

	for i=1, g_TeamMember_Max, 1 do
		local memberCtrl = g_CtrlList[i]
		memberCtrl.leaderflag:Hide()
		memberCtrl.name:Hide()
		memberCtrl.menpai:Hide()
		memberCtrl.level:Hide()
		memberCtrl.duanwei:Hide()
		memberCtrl.drag:SetProperty("DraggingEnabled", "False")
	end -- end for

	-- 是否显示战队锁定标记
	local teamlockedFlag = NewXBW:GetMyTeamLockedFlag()
	if (teamlockedFlag > 0) then
		BW_CreateManager_Lock:Show()

		if (NewXBW:IsLeader() > 0) then
			-- 自己是队长
			BW_CreateManager_AddMember:Disable()			-- 邀请按钮
			if (NewXBW:IsHasDeputy() > 0) then
				-- 已有副队长 屏蔽任命副队长按钮
				BW_CreateManager_ViceLeader:Disable()	-- 任命副队长按钮
				BW_CreateManager_NoLeader:Enable()		-- 解除副队长任命按钮
			else
				-- 没有副队长 屏蔽解除副队长按钮
				BW_CreateManager_NoLeader:Disable()		-- 解除副队长任命按钮
				BW_CreateManager_ViceLeader:Enable()		-- 任命副队长按钮
			end
			BW_CreateManager_Dissolve:Disable()			-- 解散战队按钮
			BW_CreateManager_Fire:Disable()				-- 请离战队按钮
			BW_CreateManager_Leave:Disable()				-- 退出战队按钮
		elseif (NewXBW:IsDeputy() > 0) then
			-- 自己是副队长
			BW_CreateManager_AddMember:Disable()			-- 邀请按钮
			BW_CreateManager_ViceLeader:Disable()		-- 任命副队长按钮
			BW_CreateManager_NoLeader:Disable()			-- 解除副队长任命按钮
			BW_CreateManager_Dissolve:Disable()			-- 解散战队按钮
			BW_CreateManager_Fire:Disable()				-- 请离战队按钮
			BW_CreateManager_Leave:Disable()				-- 退出战队按钮
		else
			-- 自己是队员
			BW_CreateManager_AddMember:Disable()			-- 邀请按钮
			BW_CreateManager_ViceLeader:Disable()		-- 任命副队长按钮
			BW_CreateManager_NoLeader:Disable()			-- 解除副队长任命按钮
			BW_CreateManager_Dissolve:Disable()			-- 解散战队按钮
			BW_CreateManager_Fire:Disable()				-- 请离战队按钮
			BW_CreateManager_Leave:Disable()				-- 退出战队按钮
		end

	else
		BW_CreateManager_Lock:Hide()

		if (NewXBW:IsLeader() > 0) then
			-- 自己是队长
			BW_CreateManager_AddMember:Enable()			-- 邀请按钮
			if (NewXBW:IsHasDeputy() > 0) then
				-- 已有副队长 屏蔽任命副队长按钮
				BW_CreateManager_ViceLeader:Disable()	-- 任命副队长按钮
				BW_CreateManager_NoLeader:Enable()		-- 解除副队长任命按钮
			else
				-- 没有副队长 屏蔽解除副队长按钮
				BW_CreateManager_NoLeader:Disable()		-- 解除副队长任命按钮
				BW_CreateManager_ViceLeader:Enable()		-- 任命副队长按钮
			end
			BW_CreateManager_Dissolve:Enable()			-- 解散战队按钮
			BW_CreateManager_Fire:Enable()				-- 请离战队按钮
			BW_CreateManager_Leave:Enable()				-- 退出战队按钮
		elseif (NewXBW:IsDeputy() > 0) then
			-- 自己是副队长
			BW_CreateManager_AddMember:Enable()			-- 邀请按钮
			BW_CreateManager_ViceLeader:Disable()		-- 任命副队长按钮
			BW_CreateManager_NoLeader:Disable()			-- 解除副队长任命按钮
			BW_CreateManager_Dissolve:Disable()			-- 解散战队按钮
			BW_CreateManager_Fire:Disable()				-- 请离战队按钮
			BW_CreateManager_Leave:Enable()				-- 退出战队按钮
		else
			-- 自己是队员
			BW_CreateManager_AddMember:Disable()			-- 邀请按钮
			BW_CreateManager_ViceLeader:Disable()		-- 任命副队长按钮
			BW_CreateManager_NoLeader:Disable()			-- 解除副队长任命按钮
			BW_CreateManager_Dissolve:Disable()			-- 解散战队按钮
			BW_CreateManager_Fire:Disable()				-- 请离战队按钮
			BW_CreateManager_Leave:Enable()				-- 退出战队按钮
		end
	end

	local totalConsume = 0
	local ctrlIndex = 1
	for i=1, g_TeamMember_Max, 1 do
		local memberCtrl = g_CtrlList[ctrlIndex]
		local guid, menpai, level, post, consume, duanwei1, duanwei2, dunawei3, name = NewXBW:GetMyTeamMemberInfo(i-1)
		if (guid ~= "") then
			ctrlIndex = ctrlIndex + 1
			if (post == g_Post.Leader) then
				memberCtrl.leaderflag:Show()
			elseif (post == g_Post.Deputy) then
				memberCtrl.leaderflag:Show()
			else
				memberCtrl.leaderflag:Hide()
			end

			memberCtrl.name:Show()
			memberCtrl.name:SetText("#cfff263" .. name)

			local menpaiName = GetMenpaiByID(menpai)
			memberCtrl.menpai:Show()
			if (menpaiName ~= "") then
				memberCtrl.menpai:SetText("#cfff263" .. menpaiName)
			else
				memberCtrl.menpai:SetText("")
			end
			
			memberCtrl.level:Show()
			memberCtrl.level:SetText("#cfff263" .. tostring(level))

			memberCtrl.duanwei:Show()
			memberCtrl.duanwei:SetText("")
			if (duanwei1 > 0) then
				if (duanwei1 >= g_ShenJianDuanWei) then
					-- 神剑段位 显示神剑·星数	
					local duanweiStr = g_DuanWei1Str[duanwei1]
					if (duanweiStr ~= nil) then
						local xingjieStr = ScriptGlobal_Format("#{BWDH_241114_200}", dunawei3)
						local str = "#cfff263" .. duanweiStr .. xingjieStr
						memberCtrl.duanwei:SetText(str)
					end
				else
					-- 非神剑段位 显示段位·阶数
					local duanweiStr = g_DuanWei1Str[duanwei1]
					local jieshuStr = g_DuanWei2Str[duanwei2]
					if (duanweiStr ~= nil and jieshuStr ~= nil) then
						local dwText = ScriptGlobal_Format("#{BWDH_241114_201}", duanweiStr, jieshuStr)
						memberCtrl.duanwei:SetText(dwText)
					end
				end
			end

			totalConsume = totalConsume + consume
		end
	end -- end for

	--local totalScore = ScriptGlobal_Format("#{JZGN_20230710_50}", totalConsume)
	--BW_CreateManager_TeamScore:SetText(totalScore)

	local teamName = NewXBW:GetMyTeamName()
	local teamNameStr = ScriptGlobal_Format("#{BWDH_241114_95}", teamName)
	BW_CreateManager_PageHeader_Name:SetText(teamNameStr)
end -- end func BW_CreateManager_UpdateTeamInfo()

-- 获得战队成员数量
function BW_CreateManager_GetTeamMemCount()
	local memcount = 0
	for i=1, g_TeamMember_Max, 1 do
		local guid, menpai, level, post, consume, duanwei1, duanwei2, dunawei3, name = NewXBW:GetMyTeamMemberInfo(i-1)
		if (guid ~= "") then
			memcount = memcount + 1
		end
	end	

	return memcount
end
