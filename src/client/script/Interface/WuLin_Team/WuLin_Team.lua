-- 武林之巅 队员确认界面(因为功能修改，此UI目前已废弃，合并到WuLin中了)

-- 界面控件
local WuLinTeam_ctrlTextTeamStageRange = nil
local WuLinTeam_ctrlTextTeamStageChoose = nil
local WuLinTeam_ctrlTextTeamConfirm = nil
local WuLinTeam_ctrlBtnTeamConfirm = nil
local WuLinTeam_ctrlBtnTeamCancel = nil

-- 关注NPC
local WuLin_Team_CareObjId = -1
local WuLin_Team_CareObjSvrId = -1
local WuLin_Team_MAX_OBJ_DISTANCE = 5.0

function WuLin_Team_PreLoad()
	-- this:RegisterEvent("UI_COMMAND", true)
	-- this:RegisterEvent("WLZD_OPEN_CONFIRMSTAGE", true)
	-- this:RegisterEvent("WLZD_CLOSE_ALL", true)
	-- this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	-- this:RegisterEvent("WLZD_CONFIRMCOUNT", true)
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false)
end -- end func WuLin_Team_PreLoad()

function WuLin_Team_OnLoad()
	--WuLin_Team_Initctrl()
end -- end func WuLin_Team_OnLoad()

function WuLin_Team_OnEvent(event)
	-- if (event == "WLZD_OPEN_CONFIRMSTAGE") then
	-- 	--WuLin_Team_BeginCareObject(arg0, arg1)
	-- 	WuLin_Team_CareObjSvrId = tonumber(arg0)
	-- 	WuLin_Team_Show()
	-- elseif (event == "WLZD_CLOSE_ALL") then
	-- 	WuLin_Team_Hide()
	-- 	--SetTimer("WuLin_Team", "WuLin_Team_Hide()", 500)
	-- elseif (event == "WLZD_CONFIRMCOUNT") then
	-- 	WuLin_Team_UpdateConfirmCount(arg0, arg1)
	-- elseif (event == "HIDE_ON_SCENE_TRANSED") then
	-- 	WuLin_Team_Hide()
	-- elseif (event == "OBJECT_CARED_EVENT") then
	-- 	-- if(tonumber(arg0) ~= WuLin_Team_CareObjId) then
	-- 	-- 	return;
	-- 	-- end

	-- 	-- --如果和NPC的距离大于一定距离或者被删除，自动关闭
	-- 	-- if((arg1 == "distance" and tonumber(arg2)>WuLin_Team_MAX_OBJ_DISTANCE) or arg1=="destroy") then
	-- 	-- 	--取消关心
	-- 	-- 	WuLin_Team_Hide()
	-- 	-- end
	-- end
end -- end func WuLin_Team_OnEvent()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_Team_Initctrl()
	WuLinTeam_ctrlTextTeamStageRange = WuLin_Team_Text2
	WuLinTeam_ctrlTextTeamStageChoose = WuLin_Team_Text4
	WuLinTeam_ctrlTextTeamConfirm = WuLin_Team_Text5
	WuLinTeam_ctrlBtnTeamConfirm = WuLin_Team_Choose
	WuLinTeam_ctrlBtnTeamCancel = WuLin_Team_Waive

	-- 设置按钮事件
	WuLinTeam_ctrlBtnTeamConfirm:SetEvent("Clicked", "WuLin_Team_Confirm()")
	WuLinTeam_ctrlBtnTeamCancel:SetEvent("Clicked", "WuLin_Team_Cancel()")

	WuLinTeam_ctrlBtnTeamConfirm:SetCheck(0)
	WuLinTeam_ctrlBtnTeamCancel:SetCheck(0)
end -- end func WuLin_Team_Initctrl()

-- 打开队员确认界面
function WuLin_Team_Show()
	this:Show()

	-- 获取可挑战的最大层数
	local maxStage = tonumber(WuLinZhiDian:GetMaxStage())
	local text = ""
	if (maxStage <= 1) then
		text = "#{PTFB_191228_40}"
		maxStage = 1
	elseif (maxStage > 100) then
		text = "#{PTFB_191228_42}"
		maxStage = 100
	else
		text = ScriptGlobal_Format("#{PTFB_191228_39}", maxStage)
	end
	if (WuLinTeam_ctrlTextTeamStageRange ~= nil) then
		WuLinTeam_ctrlTextTeamStageRange:SetText(text)
	end

	-- 获取选择的挑战层数
	local curChooseStage = WuLinZhiDian:GetChooseStage()
	if (WuLinTeam_ctrlTextTeamStageChoose ~= nil) then
		WuLinTeam_ctrlTextTeamStageChoose:SetText(tostring(curChooseStage))
	end

	if (WuLinTeam_ctrlBtnTeamConfirm ~= nil) then
		WuLinTeam_ctrlBtnTeamConfirm:Enable()
	end

	WuLinTeam_ctrlBtnTeamConfirm:SetCheck(0)
	WuLinTeam_ctrlBtnTeamCancel:SetCheck(0)
end -- end func WuLin_Team_Show()

-- 关闭队员确认界面
function WuLin_Team_Hide()
	--WuLin_Team_StopCareObject(WuLin_Team_CareObjId)
	WuLin_Team_CareObjSvrId = -1
	CloseMessageBoxCommon()
	this:Hide()
end -- end func WuLin_Team_Hide()

-- 选择确认按钮事件
function WuLin_Team_Confirm()
	if (WuLinTeam_ctrlBtnTeamConfirm ~= nil) then
		WuLinTeam_ctrlBtnTeamConfirm:Disable()
	end

	local curChooseStage = tonumber(WuLinZhiDian:GetChooseStage())
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MemberChooseConfirmCheck")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_Parameter(0, curChooseStage)
		Set_XSCRIPT_Parameter(1, WuLin_Team_CareObjSvrId)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end -- end func WuLin_Team_Confirm()

-- 放弃按钮事件
function WuLin_Team_Cancel()
	MessageBoxCommon("", "#{PTFB_191228_195}", "WuLin_Team", "CancelConfirm()", "CancelAbort()")
end -- end func WuLin_Team_Cancel()

-- 确认放弃
function WuLin_Team_CancelConfirm()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MemberAbort")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

	WuLin_Team_Hide()
end -- end func WuLin_Team_CancelConfirm()

-- 取消放弃
function WuLin_Team_CancelAbort()
	WuLinTeam_ctrlBtnTeamConfirm:SetCheck(0)
	WuLinTeam_ctrlBtnTeamCancel:SetCheck(0)
end -- end func WuLin_Team_CancelAbort()

-- 关闭
function WuLin_Team_Close()
	MessageBoxCommon("", "#{PTFB_191228_195}", "WuLin_Team", "CancelConfirm()", "CancelAbort()")
end -- end func WuLin_Team_Close()

-- 更新成员确认人数
function WuLin_Team_UpdateConfirmCount(totalCount, confirmCount)
	local msg = nil
	if (tonumber(totalCount) == tonumber(confirmCount)) then
		-- 所有成员均已确认
		msg = ScriptGlobal_Format("#{PTFB_191228_60}", confirmCount, totalCount)
	else
		-- 还有人未确认
		msg = ScriptGlobal_Format("#{PTFB_191228_59}", confirmCount, totalCount)
	end

	if (WuLinTeam_ctrlTextTeamConfirm ~= nil) then
		WuLinTeam_ctrlTextTeamConfirm:SetText(msg)
	end
end -- end func WuLin_Team_UpdateConfirmCount()

-- 开启NPC关注
function WuLin_Team_BeginCareObject(objSvrId, objId)
	WuLin_Team_CareObjId = tonumber(objId)
	WuLin_Team_CareObjSvrId = tonumber(objSvrId)
	if (WuLin_Team_CareObjId >= 0) then
		this:CareObject(WuLin_Team_CareObjId, 1, "WuLin_Team")
	end
end -- end func WuLin_Team_BeginCareObject()

-- 取消NPC关注
function WuLin_Team_StopCareObject(objId)
	if (tonumber(objId) >= 0) then
		this:CareObject(objId, 0, "WuLin_Team")
		WuLin_Team_CareObjId = -1
		WuLin_Team_CareObjSvrId = -1
	end
end -- end func WuLin_Team_StopCareObject()