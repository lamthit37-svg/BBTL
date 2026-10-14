-- 新6v6 组建战队UI

-- 战队名称最大长度
local g_NameLen_Max = 12
local g_TeamMember_Max = 6
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



function BW_CreateTeam_PreLoad()
	this:RegisterEvent("XBW_OPENCREATETEAM", true)
	this:RegisterEvent("XBW_CLOSECREATETEAM", true)
	this:RegisterEvent("XBW_CLOSEUI", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
end -- end func BW_CreateTeam_PreLoad()

function BW_CreateTeam_OnEvent(event)
	if (event == "XBW_OPENCREATETEAM") then
		BW_CreateTeam_BeginCareObject(arg0, arg1)
		BW_CreateTeam_UpdateTeamInfo()
		BW_CreateTeam_Show()
	elseif (event == "XBW_CLOSECREATETEAM") then
		BW_CreateTeam_Hide()
	elseif (event == "XBW_CLOSEUI") then
		BW_CreateTeam_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BW_CreateTeam_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BW_CreateTeam_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		BW_CreateTeam_UnifiedPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(g_CareObjId < 0 or tonumber(arg0) ~= g_CareObjId) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2) > g_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			BW_CreateTeam_Hide()
		end
	end
end -- end func BW_CreateTeam_OnEvent()

function BW_CreateTeam_OnLoad()
	g_UnifiedPosition = BW_CreateTeam_Frame:GetProperty("UnifiedPosition")
	BW_CreateTeam_InitCtrlList()
end -- end func BW_CreateTeam_OnLoad()

-- 界面默认位置
function BW_CreateTeam_UnifiedPos()
	if (g_UnifiedPosition ~= nil) then
		BW_CreateTeam_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
	end
end -- end func BW_CreateTeam_UnifiedPos()

function BW_CreateTeam_Show()
	this:Show()

	PushEvent("XBW_CLOSETEAMMANAGE")
end -- end func BW_CreateTeam_Show()

function BW_CreateTeam_Hide()
	BW_CreateTeam_StopCareObject()
	this:Hide()
end -- end func BW_CreateTeam_Hide()

-- 开启NPC关注
function BW_CreateTeam_BeginCareObject(objSvrId, objId)
	g_CareObjId = tonumber(objId)
	g_CareObjSvrId = tonumber(objSvrId)
	if (g_CareObjId >= 0) then
		this:CareObject(g_CareObjId, 1, "BW_CreateTeam")
	end
end -- end func BW_CreateTeam_BeginCareObject()

-- 取消NPC关注
function BW_CreateTeam_StopCareObject(objId)
	if (g_CareObjId >= 0) then
		this:CareObject(g_CareObjId, 0, "BW_CreateTeam")
		g_CareObjId = -1
		g_CareObjSvrId = -1
	end
end -- end func BW_CreateTeam_StopCareObject()

-- 初始化控件表
function BW_CreateTeam_InitCtrlList()
	g_CtrlList = {}

	g_CtrlList.member = {}
	g_CtrlList.member[1] = {}
	g_CtrlList.member[1].leaderflag = BW_CreateTeam_List1_Pic
	g_CtrlList.member[1].name = BW_CreateTeam_List1_1
	g_CtrlList.member[1].menpai = BW_CreateTeam_List1_2
	g_CtrlList.member[1].level = BW_CreateTeam_List1_3
	g_CtrlList.member[1].duanwei = BW_CreateTeam_List1_4
	g_CtrlList.member[2] = {}
	g_CtrlList.member[2].leaderflag = BW_CreateTeam_List2_Pic
	g_CtrlList.member[2].name = BW_CreateTeam_List2_1
	g_CtrlList.member[2].menpai = BW_CreateTeam_List2_2
	g_CtrlList.member[2].level = BW_CreateTeam_List2_3
	g_CtrlList.member[2].duanwei = BW_CreateTeam_List2_4
	g_CtrlList.member[3] = {}
	g_CtrlList.member[3].leaderflag = BW_CreateTeam_List3_Pic
	g_CtrlList.member[3].name = BW_CreateTeam_List3_1
	g_CtrlList.member[3].menpai = BW_CreateTeam_List3_2
	g_CtrlList.member[3].level = BW_CreateTeam_List3_3
	g_CtrlList.member[3].duanwei = BW_CreateTeam_List3_4
	g_CtrlList.member[4] = {}
	g_CtrlList.member[4].leaderflag = BW_CreateTeam_List4_Pic
	g_CtrlList.member[4].name = BW_CreateTeam_List4_1
	g_CtrlList.member[4].menpai = BW_CreateTeam_List4_2
	g_CtrlList.member[4].level = BW_CreateTeam_List4_3
	g_CtrlList.member[4].duanwei = BW_CreateTeam_List4_4
	g_CtrlList.member[5] = {}
	g_CtrlList.member[5].leaderflag = BW_CreateTeam_List5_Pic
	g_CtrlList.member[5].name = BW_CreateTeam_List5_1
	g_CtrlList.member[5].menpai = BW_CreateTeam_List5_2
	g_CtrlList.member[5].level = BW_CreateTeam_List5_3
	g_CtrlList.member[5].duanwei = BW_CreateTeam_List5_4
	g_CtrlList.member[6] = {}
	g_CtrlList.member[6].leaderflag = BW_CreateTeam_List6_Pic
	g_CtrlList.member[6].name = BW_CreateTeam_List6_1
	g_CtrlList.member[6].menpai = BW_CreateTeam_List6_2
	g_CtrlList.member[6].level = BW_CreateTeam_List6_3
	g_CtrlList.member[6].duanwei = BW_CreateTeam_List6_4
end -- end func BW_CreateTeam_InitCtrlList()

-- 关闭按钮事件
function BW_CreateTeam_CloseClicked()
	BW_CreateTeam_Hide()
end -- end func BW_CreateTeam_CloseClicked()

-- 创建战队按钮事件
function BW_CreateTeam_Accept_Clicked()
	local teamName = BW_CreateTeam_Top_NameInput:GetText()
	if (teamName == nil or teamName == "") then
		PushDebugMessage("#{BWDH_241114_50}")
		return
	end
	if (string.len(teamName) > g_NameLen_Max) then
		PushDebugMessage("#{BWDH_241114_51}")
		return
	end

	NewXBW:CreateTeam(g_CareObjSvrId, teamName)

	BW_CreateTeam_Hide()
end -- end func BW_CreateTeam_Accept_Clicked()

function BW_CreateTeam_Top_NameInputNull_Clicked()
	-- BW_CreateTeam_Top_NameInputNull:Hide()
	-- BW_CreateTeam_Top_NameInput:SetText("")

	-- -- 设置焦点
	-- BW_CreateTeam_Top_NameInput:SetProperty("DefaultEditBox", "True")
end -- end func BW_CreateTeam_Top_NameInputNull_Clicked()

-- 重置UI显示
function BW_CreateTeam_ResetUIInfo()
	if (g_CtrlList == nil) then
		BW_CreateTeam_InitCtrlList()
	end

	-- 战队名称
	--BW_CreateTeam_Top_NameInputNull:Hide()
	BW_CreateTeam_Top_NameInput:SetText("")

	-- 设置焦点
	BW_CreateTeam_Top_NameInput:SetProperty("DefaultEditBox", "True")

	-- 战队人数
	local numText = ScriptGlobal_Format("#{BWDH_241114_40}", 0)
	BW_CreateTeam_Top_Text2:SetText(numText)
	-- 战队成员
	for i=0, 6, 1 do
		if (g_CtrlList.member[i] ~= nil) then
			g_CtrlList.member[i].leaderflag:Hide()
			g_CtrlList.member[i].name:Hide()
			g_CtrlList.member[i].menpai:Hide()
			g_CtrlList.member[i].level:Hide()
			g_CtrlList.member[i].duanwei:Hide()
		end
	end -- end for
end -- end func BW_CreateTeam_ResetUIInfo()

-- 刷新战队信息
function BW_CreateTeam_UpdateTeamInfo()
	BW_CreateTeam_ResetUIInfo()

	local memCount = 0
	-- 刷新战队成员信息
	for i=1, g_TeamMember_Max, 1 do
		--local memName, memMenPai, memLevel, memDeadFlag, memLinkFlag, memSex, memZoneWorld = DataPool:GetTeamMemInfoByIndex(i-1)
		--local playerName, playerGUID, playerIcon, leaderFlag, isDead = DataPool:GetTeamMemInfoExByIndex(i-1)
		local guid, memMenPai, memLevel, post, consume, duanwei1, duanwei2, dunawei3, memName = NewXBW:GetMyTeamMemberInfo(i-1)
		if (g_CtrlList.member[i] ~= nil) then
			if (memLevel > 0) then
				if (i <= 1) then
					g_CtrlList.member[i].leaderflag:Show()
				else
					g_CtrlList.member[i].leaderflag:Hide()
				end
				g_CtrlList.member[i].name:Show()
				g_CtrlList.member[i].menpai:Show()
				g_CtrlList.member[i].level:Show()
				g_CtrlList.member[i].duanwei:Show()

				g_CtrlList.member[i].name:SetText("#cfff263" .. memName)
				local menpaiName = GetMenpaiByID(memMenPai)
				if (menpaiName ~= "") then
					g_CtrlList.member[i].menpai:SetText("#cfff263" .. menpaiName)
				else
					g_CtrlList.member[i].menpai:SetText("")
				end
				g_CtrlList.member[i].level:SetText("#cfff263" .. tostring(memLevel))

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

				memCount = memCount + 1
			else
				g_CtrlList.member[i].leaderflag:Hide()
				g_CtrlList.member[i].name:Hide()
				g_CtrlList.member[i].menpai:Hide()
				g_CtrlList.member[i].level:Hide()
				g_CtrlList.member[i].duanwei:Hide()
			end
		end
	end -- end for

	-- 战队人数
	local numText = ScriptGlobal_Format("#{BWDH_241114_40}", memCount)
	BW_CreateTeam_Top_Text2:SetText(numText)
end -- end func BW_CreateTeam_UpdateTeamInfo()