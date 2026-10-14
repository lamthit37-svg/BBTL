local g_Frame_UnifiedPosition= ""
local g_BranchingScene  = {}

--=========
-- PreLoad()
--=========
function Fenxian_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_FEN_XIAN",true)
end

--=========
-- OnLoad()
--=========
function Fenxian_OnLoad()
	g_Frame_UnifiedPosition = Fenxian_Frame:GetProperty("UnifiedPosition")	
end

--=========
-- Event
--=========
function Fenxian_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 999090011) then
		local bShow = Get_XParam_INT(0)
	elseif event == "OPEN_FEN_XIAN" then
		Fenxian_Open()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Fenxian_Cancel_Clicked()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Fenxian_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Fenxian_On_ResetPos()
	end
	
end

--=========
-- 重置
--=========
function Fenxian_On_ResetPos()
	Fenxian_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 打开
--=========
function Fenxian_Open()
	Fenxian_DragTitle:SetText("#{DFFX_20240515_5}") --标题
	Fenxian_Info:SetText("#{DFFX_20240515_7}") --文字

	local scenename = GetCurrentSceneName()
	Fenxian_CurrentScene:SetText(ScriptGlobal_Format("#{DFFX_20240515_8}",scenename))
	
	Fenxian_TargetSceneList:ResetList()
	Fenxian_TargetSceneList:ResetLastSelectIndex()

	-- 当前所在场景id
	local nSceneId = GetSceneServerID()

	-- 所有分线信息
	g_BranchingScene = GetMultiLineInfo()
	if g_BranchingScene ~= nil then
		local nSceneCount = table.getn(g_BranchingScene)
		if nSceneCount > 0 then
			-- 判断当前场景是否包含在内，如果不包含在内，则
			local curIndex = 1
			for i = 1, nSceneCount do
				local curSceneName = GetSceneNameByID(g_BranchingScene[i])
				local strInfo = ScriptGlobal_Format("#{DFFX_20240515_10}",curSceneName)
				if g_BranchingScene[i] == nSceneId then
					curIndex = i
					strInfo = "#{DFFX_20240515_11}"..strInfo
				end
				Fenxian_TargetSceneList:AddTextItem(strInfo, i)
			end
			Fenxian_TargetScene:SetText("#{DFFX_20240515_9}")
			Fenxian_TargetSceneList:SetCurrentSelect(curIndex-1)
			Fenxian_TargetSceneList:Show()
		else
			Fenxian_TargetSceneList:Hide()
			Fenxian_TargetScene:SetText("#{DFFX_20240515_33}")
		end
	else
		Fenxian_TargetSceneList:Hide()
		Fenxian_TargetScene:SetText("#{DFFX_20240515_33}")
	end
	this:Show()
end

--=========
-- 问号帮助
--=========
function Fenxian_Help_Clicked()
	PushEvent("CCSHOP_HELP", 210)
end

--=========
-- Close
--=========
function Fenxian_Cancel_Clicked()
	this:Hide()
end

function Fenxian_TargetSceneList_Clicked()
	local str2, nIndex2 = Fenxian_TargetSceneList:GetCurrentSelect()
	if g_BranchingScene == nil then
		return
	end
	
	if nIndex2 < 1 or nIndex2 > table.getn(g_BranchingScene) then
		return
	end

	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnChangeBranchingScene")
	Set_XSCRIPT_ScriptID( 999114 )
	Set_XSCRIPT_Parameter( 0, g_BranchingScene[nIndex2]);	
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	--this:Hide()
end