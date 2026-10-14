--T3WarmUp_Guide.lua
--2020 新天外预热整合界面
local g_Frame_UnifiedPosition
local g_HuoDongInfo = {}
local g_BaJingInfo = {}
local g_InfoByIndex = {}
local g_1127Award_Flag = 0
local g_Bajing_JiHuo_StartIndex = 0
local g_Bajing_JiHuo_EndIndex = 0
local g_Bajing_HuiZhi_StartIndex = 0
local g_Bajing_HuiZhi_EndIndex = 0
local g_Bajing_RedPoint = {}
--===============================================
-- OnLoad()
--===============================================
function T3WarmUp_Guide_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
end
function T3WarmUp_Guide_OnLoad()
	g_Frame_UnifiedPosition = T3WarmUp_Guide_Frame:GetProperty("UnifiedPosition")
	g_HuoDongInfo = {
		{nIndex = 1, begtime = 20201127, endtime=20201202, tips_unbeg="#{TWYR_200908_09}", tips_doing="#{TWYR_200908_10}", tips_end="#{TWYR_200908_09}", uiName=T3WarmUp_Guide_FinalGift_Img, szName="1127奖励"},
		{nIndex = 2, begtime = 20201105, endtime=20201126, tips_unbeg="#{TWYR_200908_08}", tips_doing="#{TWYR_200908_07}", tips_end="#{TWYR_200908_08}", uiName=T3WarmUp_Guide_Action_Btn1, uiTips=T3WarmUp_Guide_Action_Tips1, szName="笔墨纸砚"},
		{nIndex = 3, begtime = 20201105, endtime=20201126, tips_unbeg="#{BHHY_200907_10}", tips_doing="#{BHHY_200907_9}", tips_end="#{BHHY_200907_10}", uiName=T3WarmUp_Guide_Action_Btn2, uiTips=T3WarmUp_Guide_Action_Tips2, szName="帮会活跃"},
		-- {nIndex = 4, begtime = 20201123, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Action_Btn3, uiTips=T3WarmUp_Guide_Action_Tips3, szName="帮会BOSS"},
		{nIndex = 5, begtime = 20201105, endtime=20201202, tips_unbeg="#{PTLS_200902_1}", tips_doing="#{PTLS_200902_1}", tips_end="#{PTLS_200902_1}", uiName=T3WarmUp_Guide_Action_Btn4, uiTips=T3WarmUp_Guide_Action_Tips4, szName="汴京美食城"},
		{nIndex = 6, begtime = 20201105, endtime=20201202, tips_unbeg="#{SJFL_200623_22}", tips_doing="#{SJFL_200623_22}", tips_end="#{SJFL_150608_4}", uiName=T3WarmUp_Guide_Action_Btn5, uiTips=T3WarmUp_Guide_Action_Tips5, szName="盛宴狂欢"},
		{nIndex = 7, begtime = 20201105, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Landscape_Btn1, uiTips=T3WarmUp_Guide_Landscape_Tips1, szName="#{TWYR_200908_154}"},
		{nIndex = 8, begtime = 20201105, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Landscape_Btn2, uiTips=T3WarmUp_Guide_Landscape_Tips2, szName="#{TWYR_200908_155}"},
		{nIndex = 9, begtime = 20201105, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Landscape_Btn3, uiTips=T3WarmUp_Guide_Landscape_Tips3, szName="#{TWYR_200908_156}"},
		{nIndex = 10, begtime = 20201105, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Landscape_Btn4, uiTips=T3WarmUp_Guide_Landscape_Tips4, szName="#{TWYR_200908_157}"},
		{nIndex = 11, begtime = 20201105, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Landscape_Btn5, uiTips=T3WarmUp_Guide_Landscape_Tips5, szName="#{TWYR_200908_158}"},
		{nIndex = 12, begtime = 20201105, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Landscape_Btn6, uiTips=T3WarmUp_Guide_Landscape_Tips6, szName="#{TWYR_200908_159}"},
		{nIndex = 13, begtime = 20201105, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Landscape_Btn7, uiTips=T3WarmUp_Guide_Landscape_Tips7, szName="#{TWYR_200908_160}"},
		{nIndex = 14, begtime = 20201105, endtime=20201126, tips_unbeg="", tips_doing="", tips_end="", uiName=T3WarmUp_Guide_Landscape_Btn8, uiTips=T3WarmUp_Guide_Landscape_Tips8, szName="#{TWYR_200908_161}"},
	}
	for i, v in pairs(g_HuoDongInfo) do 
		g_InfoByIndex[v.nIndex] = i
	end

	g_BaJingInfo = {
		{uiJiHuo=T3WarmUp_Guide_Landscape_Cloud1, uiHuiZhi=T3WarmUp_Guide_Landscape_Status1Tips, uiHuiZhiAnim=T3WarmUp_Guide_Landscape_Status1Anim},
		{uiJiHuo=T3WarmUp_Guide_Landscape_Cloud2, uiHuiZhi=T3WarmUp_Guide_Landscape_Status2Tips, uiHuiZhiAnim=T3WarmUp_Guide_Landscape_Status2Anim},
		{uiJiHuo=T3WarmUp_Guide_Landscape_Cloud3, uiHuiZhi=T3WarmUp_Guide_Landscape_Status3Tips, uiHuiZhiAnim=T3WarmUp_Guide_Landscape_Status3Anim},
		{uiJiHuo=T3WarmUp_Guide_Landscape_Cloud4, uiHuiZhi=T3WarmUp_Guide_Landscape_Status4Tips, uiHuiZhiAnim=T3WarmUp_Guide_Landscape_Status4Anim},
		{uiJiHuo=T3WarmUp_Guide_Landscape_Cloud5, uiHuiZhi=T3WarmUp_Guide_Landscape_Status5Tips, uiHuiZhiAnim=T3WarmUp_Guide_Landscape_Status5Anim},
		{uiJiHuo=T3WarmUp_Guide_Landscape_Cloud6, uiHuiZhi=T3WarmUp_Guide_Landscape_Status6Tips, uiHuiZhiAnim=T3WarmUp_Guide_Landscape_Status6Anim},
		{uiJiHuo=T3WarmUp_Guide_Landscape_Cloud7, uiHuiZhi=T3WarmUp_Guide_Landscape_Status7Tips, uiHuiZhiAnim=T3WarmUp_Guide_Landscape_Status7Anim},
		{uiJiHuo=T3WarmUp_Guide_Landscape_Cloud8, uiHuiZhi=T3WarmUp_Guide_Landscape_Status8Tips, uiHuiZhiAnim=T3WarmUp_Guide_Landscape_Status8Anim},
	}
	local from_to_info = string.format("curve:Liner mode:Once duration:%s startx:0 starty:0 endx:80 endy:0", 2.0)
	local alpha_to_info = string.format("curve:Liner mode:Once duration:%s startx:1 starty:0 endx:0 endy:0", 1.5)
	for i, v in pairs(g_BaJingInfo) do 
		v.uiJiHuo:Tween_SetInfo("Position", from_to_info)
		v.uiJiHuo:Tween_SetInfo("Alpha", alpha_to_info)
		v.uiJiHuo:Hide()
		v.uiHuiZhiAnim:Play(false)
		v.uiHuiZhi:Hide()
	end
end

--===============================================
-- OnEvent()
--===============================================
function T3WarmUp_Guide_OnEvent(event)
if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		T3WarmUp_Guide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		T3WarmUp_Guides_Close()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15490001 ) then
		if Get_XParam_INT( 0 ) == 0 then 
			T3WarmUp_Guides_Close()
			return
		end
		g_1127Award_Flag = Get_XParam_INT( 1 )
		g_Bajing_JiHuo_StartIndex = Get_XParam_INT( 2 )
		g_Bajing_JiHuo_EndIndex = Get_XParam_INT( 3 )
		g_Bajing_HuiZhi_StartIndex = Get_XParam_INT( 4 )
		g_Bajing_HuiZhi_EndIndex = Get_XParam_INT( 5 )
		-- 汴京八景红点
		for i=1,8 do 
			local nValue = Get_XParam_INT( 5+i )==1
			local info = T3WarmUp_Guide_GetInfo(6+i)
			Lua_RedPoint_SetActive(info.uiTips:GetName(), nValue)
		end
		T3WarmUp_Guide_UpdateInfo()
		this:Show()
		-- 激活动画表现
		for i, v in ipairs(g_BaJingInfo) do 
			if i<=g_Bajing_JiHuo_StartIndex then 
				v.uiJiHuo:Hide()
			elseif i<=g_Bajing_JiHuo_EndIndex then 
				v.uiJiHuo:Show()
				v.uiJiHuo:Tween_Play("Position", true, true)
				v.uiJiHuo:Tween_Play("Alpha", true, true)
			else
				v.uiJiHuo:Show()
			end
		end
		-- 绘制动画表现
		for i, v in ipairs(g_BaJingInfo) do 
			if i<=g_Bajing_HuiZhi_StartIndex then 
				v.uiHuiZhi:Show()
			elseif i<=g_Bajing_HuiZhi_EndIndex then 
				v.uiHuiZhi:Hide()
				v.uiHuiZhiAnim:Play(true)
			else
				v.uiHuiZhi:Hide()
			end
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15490002 ) then
		-- 服务器红点单独设置 可以自己管理发送UICommand设置  也可以查看2020T300YuRe_Main.lua的 x888226_g_FuncScript 脚本回调"GetButtonState"
		local strIdx = Get_XParam_STR( 0 )
		local nIndex = Get_XParam_INT( 0 )
		local nValue = Get_XParam_INT( 1 )==1
		local nGroup = Get_XParam_INT( 2 )
		if nGroup == 0 then nGroup = 1 end
		-- PushDebugMessage( string.format("15490002:%d(%s)%s", nIndex, strIdx, tostring(nValue)) )
		if nIndex == 0 then
			if strIdx == "" then return end
			Lua_RedPoint_SetActive(strIdx, nValue, nGroup)
		elseif nIndex==1 then 
			-- 每天第一次-红点
			Lua_RedPoint_SetActive("PlayerQuicklyEnter_Image69_Tips", nValue, nGroup)
		elseif nIndex==2 then 
			-- 个人活跃-活动红点
			Lua_RedPoint_SetActive("T3WarmUp_Guide_Action_Tips1", nValue, nGroup)
		elseif nIndex==3 then 
			-- 帮会活跃-活动红点
			Lua_RedPoint_SetActive("T3WarmUp_Guide_Action_Tips2", nValue, nGroup)
		elseif nIndex==4 then 
			-- 帮会BOSS-活动红点
			Lua_RedPoint_SetActive("T3WarmUp_Guide_Action_Tips3", nValue, nGroup)
		elseif nIndex==5 then 
			-- 汴京美食城-活动红点
			Lua_RedPoint_SetActive("T3WarmUp_Guide_Action_Tips4", nValue, nGroup)
		elseif nIndex==6 then 
			-- 盛宴狂欢-活动红点
			Lua_RedPoint_SetActive("T3WarmUp_Guide_Action_Tips5", nValue, nGroup)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15490003 ) then
		-- 服务器红点批量设置
		local nAddNum = 0
		local nIndex,nShow,nValue = 0,0,0
		while true do
			nIndex = Get_XParam_INT( nAddNum )
			nShow = Get_XParam_INT( nAddNum+1 )
			nValue = Get_XParam_INT( nAddNum+2 )==1
			-- PushDebugMessage( string.format("15490003:%d%s", nIndex, tostring(nValue)) )
			if nIndex <= 0 then return end
			local info = T3WarmUp_Guide_GetInfo(nIndex)
			if not info then return end
			--设置显隐
			if nShow == 1 then 
				info.uiName:Show()
			else
				info.uiName:Hide()
			end
			--设置红点
			Lua_RedPoint_SetActive(info.uiTips:GetName(), nValue, nGroup)
			nAddNum = nAddNum + 3
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15490004 ) then
		local targetSceneID = Get_XParam_INT(0)
		local targetPosX = Get_XParam_INT(1)
		local targetPosZ = Get_XParam_INT(2)
		local targetNPCName = Get_XParam_STR(0)
		if "" ~= targetNPCName then
			AutoRuntoTargetExWithName(targetPosX, targetPosZ, targetSceneID, targetNPCName)
		else
			AutoRunToTargetEx(targetPosX, targetPosZ, targetSceneID)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15490005 ) then
		T3WarmUp_Guide_FinalGift_Anim:Hide()
		T3WarmUp_Guide_FinalGift_Mark:Show()
	end
end
function T3WarmUp_Guides_Close()
	this:Hide()
end
--===============================================
--===============================================
function T3WarmUp_Guide_GetInfo(nIndex)
	if not g_InfoByIndex[nIndex] then 
		PushDebugMessage("T3WarmUp_Guide_GetInfo nil: nIndex="..(nIndex or "nil"))
		return
	end
	return g_HuoDongInfo[g_InfoByIndex[nIndex]]
end
function T3WarmUp_Guide_UpdateInfo()
	local curDay = tonumber(DataPool:GetServerDayTime())
	-- 公共部分
	for i, v in ipairs(g_HuoDongInfo) do
		if curDay < v.begtime then
			v.uiName:SetToolTip(v.tips_unbeg)
		elseif curDay <= v.endtime then
			v.uiName:SetToolTip(v.tips_doing)
		else
			v.uiName:SetToolTip(v.tips_end)
		end
	end

	local info = nil
	-- 汴京八景
	for i=1,8 do 
		info = T3WarmUp_Guide_GetInfo(6+i)
		info.uiName:SetToolTip(ScriptGlobal_Format("#{TWYR_200908_06}", info.szName))
	end
	-- 20201127奖励
	T3WarmUp_Guide_FinalGift_Anim:Hide()
	T3WarmUp_Guide_FinalGift_Mark:Hide()
	info = T3WarmUp_Guide_GetInfo(1)
	if curDay >= info.begtime and curDay <= info.endtime then
		if g_1127Award_Flag == 1 then 
			T3WarmUp_Guide_FinalGift_Mark:Show()
		else
			T3WarmUp_Guide_FinalGift_Anim:Show()
		end
	end
end
-- 各功能按钮点击事件
function T3WarmUp_Guide_Action_Clicked(nIndex)
	-- 1=个人活跃 2=帮会活跃 3=帮会boss 4=汴京美食城 5=狂欢盛宴
	if nIndex == 1 then 
		if (IsInTServer() == 1) then
			PushDebugMessage("#{BHKF_140909_327}")
			return
		end	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenT300HuoYue")
			Set_XSCRIPT_ScriptID(888233)
			Set_XSCRIPT_Parameter( 0, nIndex )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif nIndex == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenGuildActValueUI")
			Set_XSCRIPT_ScriptID( 888213 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif nIndex == 4 then
		local curday = DataPool:GetServerDayTime()
		if curday < 20201127 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OpenChoujiangUI")
				Set_XSCRIPT_ScriptID( 888205 )
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
				Set_XSCRIPT_ScriptID( 888206 )
				Set_XSCRIPT_Parameter(0,1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()		
		end
	elseif nIndex == 5 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskPrizeUI")
			Set_XSCRIPT_ScriptID(891205)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	else
	end
end
-- 八景按钮
function T3WarmUp_Guide_Landscape_Clicked(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenT300BaJing")
		Set_XSCRIPT_ScriptID(888228)
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_Parameter( 1, 1 )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
-- 11月27日奖励
function T3WarmUp_Guide_Schedule_Award()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("T300FinalAward")
		Set_XSCRIPT_ScriptID(888228)
		Set_XSCRIPT_Parameter( 0, 0 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function T3WarmUp_Landscape_StatusAnimEnd(nIndex)
	-- PushDebugMessage("T3WarmUp_Landscape_StatusAnimEnd:"..(nIndex or "nil"))
	if not nIndex then return end
	local tabInfo = g_BaJingInfo[nIndex]
	if not tabInfo then 
		PushDebugMessage("T3WarmUp_Landscape_StatusAnimEnd nil:"..nIndex)
		return 
	end
	tabInfo.uiHuiZhi:Show()
end
