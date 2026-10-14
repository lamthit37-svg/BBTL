-- 2019Q1周年庆-任务总界面

local g_Frame_UnifiedPosition
--活动按钮小红点
local g_RedPointInfo = {}
--活动页签
local g_PageButton = {}

function ZhouNian12_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end


function ZhouNian12_Guide_OnLoad()

	g_Frame_UnifiedPosition = ZhouNian12_Guide_Frame:GetProperty("UnifiedPosition")

	g_RedPointInfo =
	{
		{ btn = ZhouNian12_Guide_TongziBtn, 		tips = ZhouNian12_Guide_TongziBtn_Tips, 		nScriptID = 790003, 	nUICommandID = 920190319, bShow = 0, },			--童子
		{ btn = ZhouNian12_Guide_HuarongdaoBtn, 	tips = ZhouNian12_Guide_HuarongdaoBtn_Tips, 	nScriptID = 893067, 	nUICommandID = 89306788, bShow = 0, },			--华容道
		{ btn = ZhouNian12_Guide_TanbaoBtn, 		tips = ZhouNian12_Guide_TanbaoBtn_Tips, 		nScriptID = 893065, 	nUICommandID = 89306504, bShow = 0, },			--探宝
		{ btn = ZhouNian12_Guide_XuanchuanBtn, 		tips = ZhouNian12_Guide_XuanchuanBtn_Tips, 		nScriptID = 893075, 	nUICommandID = 89307501, bShow = 0, },			--H5
	}

	ZhouNian12_Guide_InitRedPoint()

end


function ZhouNian12_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89306601 then

		ZhouNian12_Guide_Update()

	elseif event == "UI_COMMAND" and tonumber(arg0) == 89306506 then

		ZhouNian12_Guide_FuBen()

	elseif event == "UI_COMMAND" then

		for i = 1, table.getn(g_RedPointInfo) do
			if tonumber( arg0 ) == tonumber(g_RedPointInfo[i].nUICommandID) then
				local nScriptID = Get_XParam_INT(0)
				local bShow = Get_XParam_INT(1)
				if tonumber( nScriptID ) ~= nil and tonumber( nScriptID ) > 0 and tonumber( nScriptID ) == tonumber(g_RedPointInfo[i].nScriptID) then
					g_RedPointInfo[i].bShow = bShow

					--刷新界面
					if this:IsVisible() then
						--更新活动小红点
						ZhouNian12_Guide_UpdateRedPoint()
						--更新主界面快捷按钮小红点
						ZhouNian12_Guide_UpdateQuickEnter()
					else
						--更新主界面快捷按钮小红点
						ZhouNian12_Guide_UpdateQuickEnter()
					end
				end
				--跳出
				break
			end
		end

	elseif event == "VIEW_RESOLUTION_CHANGED" then

		ZhouNian12_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ZhouNian12_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		ZhouNian12_Guide_On_ResetPos()

	end

end

--=========
-- 初始化活动小红点
--=========
function ZhouNian12_Guide_InitRedPoint()

	-- 清空小红点
	for i = 1, table.getn(g_RedPointInfo) do
		g_RedPointInfo[i].bShow = 0
	end

	-- 请求全部活动小红点
	if (IsInTServer() == 1) then
		--PushDebugMessage("#{BHKF_140909_327}")
		return
	end	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateAllRedPoint" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()

	-- 更新主界面快捷按钮小红点
	ZhouNian12_Guide_UpdateQuickEnter()

end

--=========
-- 更新主界面快捷按钮小红点
--=========
function ZhouNian12_Guide_UpdateQuickEnter()

	local bShow = 0

	for i = 1, table.getn(g_RedPointInfo) do
		if 1 == g_RedPointInfo[i].bShow then
			bShow = 1
			break
		end
	end

	PushEvent("2019Q1ZHOUNIANQING_QUICKENTER", bShow)

end

--=========
-- 打开
--=========
function ZhouNian12_Guide_Update()

	-- 显示
	this:Show()

	--更新活动小红点
	ZhouNian12_Guide_UpdateRedPoint()

	--更新主界面快捷按钮小红点
	ZhouNian12_Guide_UpdateQuickEnter()

end

--=========
-- 更新活动小红点
--=========
function ZhouNian12_Guide_UpdateRedPoint()

	--活动小红点
	for i = 1, table.getn(g_RedPointInfo) do
		if g_RedPointInfo[i].tips ~= nil then
			g_RedPointInfo[i].tips:Hide()
			if g_RedPointInfo[i].bShow == 1 then
				g_RedPointInfo[i].tips:Show()
			end
		end
	end

end

--=========
-- 关闭
--=========
function ZhouNian12_Guide_Close()


	this:Hide()

end

--=========
-- 华容道
--=========
function ZhouNian12_Guide_HuarongdaoClicked()

	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay < 20190418 or curDay > 20190425 then
		PushDebugMessage("#{ZNYR_190316_09}")
		return
	end

	local nLevel = Player:GetLevel();
	if nLevel < 30 then
		PushDebugMessage("#{ZNYR_190316_10}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, 893067)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenUI" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, 893066)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	PushDebugMessage("#{ZNYR_190316_11}")

end

--=========
-- 秘境
--=========
function ZhouNian12_Guide_TanbaoClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, 893065)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenUI" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, 893065)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()


end

--=========
-- 童子
--=========
function ZhouNian12_Guide_TongziClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, 790003)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenUI" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, 790003)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

--=========
-- H5抽奖
--=========
function ZhouNian12_Guide_XuanchuanClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, 893075)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenUI" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, 893075)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

--=========
-- 重置
--=========
function ZhouNian12_Guide_On_ResetPos()

	ZhouNian12_Guide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 帮助
--=========
function ZhouNian12_Guide_Client_HelpClicked()

end

--=========
-- 关闭
--=========
function ZhouNian12_Guide_OnHiden()
	ZhouNian12_Guide_Close()
end

--=========
-- 副本回调 寻路
--=========
function ZhouNian12_Guide_FuBen()

    local Posvec = {242,269,0,"鹤舞"}

    curSceneID = GetSceneID()
    if g_SameSceneId[ tonumber(Posvec[3]) ] and g_SameSceneId[ tonumber(Posvec[3]) ]  == curSceneID then
    	AutoRunToTarget(tonumber(Posvec[1]),tonumber(Posvec[2]))
    else
    	AutoRunToTargetEx(tonumber(Posvec[1]),tonumber(Posvec[2]),tonumber(Posvec[3]))
    end

    SetAutoRunTargetNPCName(tostring(Posvec[4]))

end
