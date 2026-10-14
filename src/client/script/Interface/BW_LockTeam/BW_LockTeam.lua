-- 新6v6 战队锁定确认UI
-- 战队成员数量
local g_TeamMember_Max = 6
-- 神剑段位id
local g_ShenJianDuanWei = 6
-- 脚本id
local g_SvrScriptId = 999554
-- 关闭标记
local g_CloseFlag = 0
-- 关注NPC
local g_CareObjId = -1
local g_CareObjSvrId = -1
local g_MAX_OBJ_DISTANCE = 5.0
-- 默认位置
local g_UnifiedPosition = nil
-- 控件表
local g_CtrlList = nil

-- 段位1显示
local g_DuanWei1Str =
{
	[1] = "#{BWDH_180804_131}",
	[2] = "#{BWDH_180804_132}",
	[3] = "#{BWDH_180804_133}",
	[4] = "#{BWDH_180804_134}",
	[5] = "#{BWDH_180804_135}",
	[6] = "#{BWDH_180804_136}",
} -- end g_DuanWei1Str

-- 段位2显示
local g_DuanWei2Str =
{
	[1] = "#{BWDH_180804_153}",
	[2] = "#{BWDH_180804_152}",
	[3] = "#{BWDH_180804_151}",
	[4] = "#{BWDH_180804_150}",
	[5] = "#{BWDH_180804_149}",
} -- end g_DuanWei2Str



function BW_LockTeam_PreLoad()
	this:RegisterEvent("XBW_OPENLOCKCONFIRM", true)
	this:RegisterEvent("XBW_UPDATELOCKCONFIRM", true)
	this:RegisterEvent("XBW_CLOSELOCKCONFIRM", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
end -- end func BW_LockTeam_PreLoad()

function BW_LockTeam_OnEvent(event)
	if (event == "XBW_OPENLOCKCONFIRM") then
		BW_LockTeam_Show(tonumber(arg0), tonumber(arg1))
		BW_LockTeam_UpdateTeamInfo()
	elseif (event == "XBW_UPDATELOCKCONFIRM") then
		BW_LockTeam_UpdateLockConfirm(tostring(arg0))
	elseif (event == "XBW_CLOSELOCKCONFIRM") then
		BW_LockTeam_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BW_LockTeam_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BW_LockTeam_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		BW_LockTeam_UnifiedPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		-- 这个事件目前已经被干掉了
		-- 要调整关注距离直接去改代码吧 ObjectManager.cpp CObjectManager::Tick(VOID)
		if(g_CareObjId < 0 or tonumber(arg0) ~= g_CareObjId) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2) > g_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			BW_LockTeam_Hide()
		end
	end
end -- end func BW_LockTeam_OnEvent()

function BW_LockTeam_OnLoad()
	g_UnifiedPosition = BW_LockTeam_Frame:GetProperty("UnifiedPosition")
	BW_LockTeam_InitCtrlList()
end -- end func BW_LockTeam_OnLoad()

-- 界面默认位置
function BW_LockTeam_UnifiedPos()
	if (g_UnifiedPosition ~= nil) then
		BW_LockTeam_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
	end
end -- end func BW_LockTeam_UnifiedPos()

function BW_LockTeam_Show(careObjSvrId, careObjId)
    if (careObjSvrId ~= nil and careObjId ~= nil) then
        if (g_CareObjId < 0) then
            BW_LockTeam_BeginCareObject(careObjSvrId, careObjId)
        end
    end

	g_CloseFlag = 0
	this:Show()
end -- end func BW_LockTeam_Show()

function BW_LockTeam_Hide()
    BW_LockTeam_StopCareObject()
	
	g_CloseFlag = 1
	this:Hide()
end -- end func BW_LockTeam_Hide()

-- 开启NPC关注
function BW_LockTeam_BeginCareObject(objSvrId, objId)
    if (objSvrId >= 0 and objId >= 0) then
        g_CareObjId = objId
        g_CareObjSvrId = objSvrId
        this:CareObject(g_CareObjId, 1, "BW_LockTeam")
    end
end -- end func BW_LockTeam_BeginCareObject()

-- 取消NPC关注
function BW_LockTeam_StopCareObject(objId)
	if (g_CareObjId >= 0) then
		this:CareObject(g_CareObjId, 0, "BW_LockTeam")
		g_CareObjId = -1
		g_CareObjSvrId = -1
	end
end -- end func BW_LockTeam_StopCareObject()

function BW_LockTeam_OnHidden()
	if (g_CloseFlag <= 0) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CCallBack_LockCancel")
			Set_XSCRIPT_ScriptID(g_SvrScriptId)
			Set_XSCRIPT_Parameter(0, g_CareObjSvrId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end -- end func BW_LockTeam_OnHidden()

function BW_LockTeam_List_BtnOK(arg)
end -- end func BW_LockTeam_List_BtnOK()

-- 关闭按钮事件
function BW_LockTeam_CloseClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CCallBack_LockCancel")
		Set_XSCRIPT_ScriptID(g_SvrScriptId)
		Set_XSCRIPT_Parameter(0, g_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	BW_LockTeam_Hide()
end -- end func BW_LockTeam_CloseClicked()

-- 我要锁定按钮事件
function BW_LockTeam_Invite_Clicked(arg)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Team_CCallBack_LockConfirmed")
		Set_XSCRIPT_ScriptID(g_SvrScriptId)
		Set_XSCRIPT_Parameter(0, g_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func BW_LockTeam_Invite_Clicked()

function BW_LockTeam_InitCtrlList()
	g_CtrlList = {}

	g_CtrlList.member = {}
	g_CtrlList.member[1] = {}
	g_CtrlList.member[1].leaderflag = BW_LockTeam_List1_Pic
	g_CtrlList.member[1].name = BW_LockTeam_List1_1
	g_CtrlList.member[1].menpai = BW_LockTeam_List1_2
	g_CtrlList.member[1].level = BW_LockTeam_List1_3
	g_CtrlList.member[1].duanwei = BW_LockTeam_List1_4
	g_CtrlList.member[1].confirmflag = BW_LockTeam_List1_BtnOK
	g_CtrlList.member[2] = {}
	g_CtrlList.member[2].leaderflag = BW_LockTeam_List2_Pic
	g_CtrlList.member[2].name = BW_LockTeam_List2_1
	g_CtrlList.member[2].menpai = BW_LockTeam_List2_2
	g_CtrlList.member[2].level = BW_LockTeam_List2_3
	g_CtrlList.member[2].duanwei = BW_LockTeam_List2_4
	g_CtrlList.member[2].confirmflag = BW_LockTeam_List2_BtnOK
	g_CtrlList.member[3] = {}
	g_CtrlList.member[3].leaderflag = BW_LockTeam_List3_Pic
	g_CtrlList.member[3].name = BW_LockTeam_List3_1
	g_CtrlList.member[3].menpai = BW_LockTeam_List3_2
	g_CtrlList.member[3].level = BW_LockTeam_List3_3
	g_CtrlList.member[3].duanwei = BW_LockTeam_List3_4
	g_CtrlList.member[3].confirmflag = BW_LockTeam_List3_BtnOK
	g_CtrlList.member[4] = {}
	g_CtrlList.member[4].leaderflag = BW_LockTeam_List4_Pic
	g_CtrlList.member[4].name = BW_LockTeam_List4_1
	g_CtrlList.member[4].menpai = BW_LockTeam_List4_2
	g_CtrlList.member[4].level = BW_LockTeam_List4_3
	g_CtrlList.member[4].duanwei = BW_LockTeam_List4_4
	g_CtrlList.member[4].confirmflag = BW_LockTeam_List4_BtnOK
	g_CtrlList.member[5] = {}
	g_CtrlList.member[5].leaderflag = BW_LockTeam_List5_Pic
	g_CtrlList.member[5].name = BW_LockTeam_List5_1
	g_CtrlList.member[5].menpai = BW_LockTeam_List5_2
	g_CtrlList.member[5].level = BW_LockTeam_List5_3
	g_CtrlList.member[5].duanwei = BW_LockTeam_List5_4
	g_CtrlList.member[5].confirmflag = BW_LockTeam_List5_BtnOK
	g_CtrlList.member[6] = {}
	g_CtrlList.member[6].leaderflag = BW_LockTeam_List6_Pic
	g_CtrlList.member[6].name = BW_LockTeam_List6_1
	g_CtrlList.member[6].menpai = BW_LockTeam_List6_2
	g_CtrlList.member[6].level = BW_LockTeam_List6_3
	g_CtrlList.member[6].duanwei = BW_LockTeam_List6_4
	g_CtrlList.member[6].confirmflag = BW_LockTeam_List6_BtnOK
end -- end func BW_LockTeam_InitCtrlList()

-- 重置UI显示
function BW_LockTeam_ResetUITeamInfo()
	if (g_CtrlList == nil) then
		BW_LockTeam_InitCtrlList()
	end

	-- 战队成员
	for i=1, 6, 1 do
		if (g_CtrlList.member[i] ~= nil) then
			g_CtrlList.member[i].leaderflag:Hide()
			g_CtrlList.member[i].name:Hide()
			g_CtrlList.member[i].menpai:Hide()
			g_CtrlList.member[i].level:Hide()
			g_CtrlList.member[i].duanwei:Hide()
			g_CtrlList.member[i].confirmflag:Hide()
		end
	end -- end for
end -- end func BW_LockTeam_ResetUITeamInfo()

function BW_LockTeam_GetYMDByDate(timeDate)
	local timeYear = 0
    local timeMon = 0
    local timeDay = 0
    if (timeDate > 0) then
        timeYear = math.floor(timeDate / 10000)
        timeMon = math.floor((timeDate - timeYear*10000) / 100)
        timeDay = math.mod(timeDate, 100)
    end

    return timeYear, timeMon, timeDay
end -- end func BW_LockTeam_GetYMDByDate

function BW_LockTeam_UpdateTeamInfo()
	BW_LockTeam_ResetUITeamInfo()

	local curDay = tonumber(DataPool:GetServerDayTime())
	local seasonIndex, lockBegin, lockEnd = BWDH2018:GetXbwGetCurSeasonLockInfo(curDay)
	local beginYear, beginMonth, beginDay = BW_LockTeam_GetYMDByDate(lockBegin)
	local endYear, endMonth, endDay = BW_LockTeam_GetYMDByDate(lockEnd)
	local msg = ScriptGlobal_Format("#{BWDH_241114_66}", beginYear, beginMonth, beginDay, endMonth, endDay)
	BW_LockTeam_TopText:SetText(msg)

	-- 刷新战队成员信息
	for i=1, g_TeamMember_Max, 1 do
		local guid, memMenPai, memLevel, pos, consume, duanwei1, duanwei2, dunawei3, memName = NewXBW:GetMyTeamMemberInfo(i-1)
		if (g_CtrlList.member[i] ~= nil) then
			if (memLevel > 0) then
				if (pos == 2) then
					g_CtrlList.member[i].leaderflag:Show()
				else
					g_CtrlList.member[i].leaderflag:Hide()
				end
				g_CtrlList.member[i].name:Show()
				g_CtrlList.member[i].menpai:Show()
				g_CtrlList.member[i].level:Show()
				g_CtrlList.member[i].duanwei:Show()
				g_CtrlList.member[i].confirmflag:Show()
				g_CtrlList.member[i].confirmflag:SetCheck(0)
				g_CtrlList.member[i].confirmflag:Disable()

				-- 角色名
				g_CtrlList.member[i].name:SetText("#cfff263" .. memName)
				-- 门派
				local menpaiName = GetMenpaiByID(memMenPai)
				if (menpaiName ~= "") then
					g_CtrlList.member[i].menpai:SetText("#cfff263" .. menpaiName)
				else
					g_CtrlList.member[i].menpai:SetText("")
				end
				-- 等级
				g_CtrlList.member[i].level:SetText("#cfff263" .. tostring(memLevel))
				-- 段位
				g_CtrlList.member[i].duanwei:SetText("")
				if (duanwei1 > 0) then
					if (duanwei1 >= g_ShenJianDuanWei) then
						-- 神剑段位 显示神剑·星数	
						local duanweiStr = g_DuanWei1Str[duanwei1]
						if (duanweiStr ~= nil) then
							local xingjieStr = ScriptGlobal_Format("#{BWDH_241114_200}", dunawei3)
							local str = "#cfff263" .. duanweiStr .. xingjieStr
							g_CtrlList.member[i].duanwei:SetText(str)
						end
					else
						-- 非神剑段位 显示段位·阶数
						local duanweiStr = g_DuanWei1Str[duanwei1]
						local jieshuStr = g_DuanWei2Str[duanwei2]
						if (duanweiStr ~= nil and jieshuStr ~= nil) then
							local dwText = ScriptGlobal_Format("#{BWDH_241114_201}", duanweiStr, jieshuStr)
							g_CtrlList.member[i].duanwei:SetText(dwText)
						end
					end
				end
				-- 确认状态
				-- 这里应该都是默认未确认状态 所以不需要处理
			end
		end
	end -- end for
end -- end func BW_LockTeam_UpdateTeamInfo()

function BW_LockTeam_UpdateLockConfirm(playerGUID)
	if (g_CtrlList == nil) then
		return
	end

	for i=1, g_TeamMember_Max, 1 do
		local guid, memMenPai, memLevel, pos, consume, duanwei1, duanwei2, dunawei3, memName = NewXBW:GetMyTeamMemberInfo(i-1)
		if (guid == playerGUID) then
			if (g_CtrlList.member[i] ~= nil) then
				g_CtrlList.member[i].confirmflag:Show()
				g_CtrlList.member[i].confirmflag:SetCheck(1)
				g_CtrlList.member[i].confirmflag:Disable()

				break
			end
		end
	end -- end for
end -- end func BW_LockTeam_UpdateLockConfirm()