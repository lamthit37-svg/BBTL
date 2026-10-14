--2024周年庆预热活动设计

local g_Frame_UnifiedPosition

local g_JieSuoNum = 0 --解锁的页面个数
local g_FinishNum = 0 --当前完成的数量
local g_ShowPage = 0 --当前默认显示的页码 也是 当前完成的数量
local g_RedPoint = 0 --累积奖励小红点
local g_GetPrize = 0 --累积奖励领取标记

local g_MaxPage = 4 --最大页数
local g_CurPage = 1 --当前页码（1~4）

local g_Begintime = 0
local g_Endtime = 0
local g_LimitLevel = 30

--npc坐标
local g_posX = 267
local g_posZ = 270
local g_name = "陈孤鸿"

local g_PageInfo = {}

--=========
-- PreLoad()
--=========
function Anniversary2024_Yure_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function Anniversary2024_Yure_OnLoad()
	
	g_Frame_UnifiedPosition = Anniversary2024_Yure_Frame:GetProperty("UnifiedPosition")
		
	g_JieSuoNum = 0 --解锁的页面个数
	g_FinishNum = 0
	g_ShowPage = 0 --当前默认显示的页码 也是 当前完成的数量
	g_RedPoint = 0 --累积奖励小红点
	g_CurPage = 1 --当前页码
	g_GetPrize = 0
	g_Begintime = 0
	g_Endtime = 0
	
	g_PageInfo[1] = {text="#{LYJB_240222_03}", image="set:Anniversary2024Pic_Yure1 image:Anniversary2024Pic_Yure1_Img1"}
	g_PageInfo[2] = {text="#{LYJB_240222_04}", image="set:Anniversary2024Pic_Yure2 image:Anniversary2024Pic_Yure2_Img2"}
	g_PageInfo[3] = {text="#{LYJB_240222_05}", image="set:Anniversary2024Pic_Yure2 image:Anniversary2024Pic_Yure2_Img3"}
	g_PageInfo[4] = {text="#{LYJB_240222_06}", image="set:Anniversary2024Pic_Yure3 image:Anniversary2024Pic_Yure3_Img4"}
	
end

--=========
-- Event
--=========
function Anniversary2024_Yure_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 99903901) then
	
		local bShow = Get_XParam_INT(0)
		--关闭界面
		if bShow == 0 then
			Anniversary2024_Yure_Close()		
		--打开界面
		elseif bShow == 1 then
			g_JieSuoNum = Get_XParam_INT(1)
			g_FinishNum = Get_XParam_INT(2)
			g_ShowPage = Get_XParam_INT(3)
			g_RedPoint = Get_XParam_INT(4)	
			g_GetPrize = Get_XParam_INT(5)	
			g_CurPage = g_ShowPage
			
			local redShow = Get_XParam_INT(6)
			g_Begintime = Get_XParam_INT(7)
			g_Endtime = Get_XParam_INT(8)			
			Lua_ShowQuickEnterPointTip(56, redShow)		
			if this:IsVisible() then
				Anniversary2024_Yure_Close()
			else
				Anniversary2024_Yure_Open()
				this:Show()
			end
		--刷新界面
		elseif bShow == 2 then
			if this:IsVisible() then
				g_JieSuoNum = Get_XParam_INT(1)
				g_FinishNum = Get_XParam_INT(2)
				g_ShowPage = Get_XParam_INT(3)
				g_RedPoint = Get_XParam_INT(4)
				g_GetPrize = Get_XParam_INT(5)
				g_CurPage = g_ShowPage				
				Anniversary2024_Yure_Open()
			end
			local redShow = Get_XParam_INT(6)
			g_Begintime = Get_XParam_INT(7)
			g_Endtime = Get_XParam_INT(8)			
			Lua_ShowQuickEnterPointTip(56, redShow)			
		end		
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Anniversary2024_Yure_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Anniversary2024_Yure_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		Anniversary2024_Yure_On_ResetPos()

	end
	
end

--=========
-- 重置
--=========
function Anniversary2024_Yure_On_ResetPos()

	Anniversary2024_Yure_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function Anniversary2024_Yure_Open()

	Anniversary2024_Yure_Info:SetText("")
	Anniversary2024_Yure_ImageBkB:SetProperty("Image", "")
	Anniversary2024_Yure_Text:SetText("")
	
	local Info = g_PageInfo[g_CurPage]
	if Info == nil then
		--异常处理：当前页码非法时，默认第1页
		g_CurPage = 1
		Info = g_PageInfo[1]
	end
	
	Anniversary2024_Yure_Info:SetText(Info.text)
	
	Anniversary2024_Yure_ImageBkB:SetProperty("Image", Info.image)
	
	if g_FinishNum == g_MaxPage then
		Anniversary2024_Yure_Text:SetText(ScriptGlobal_Format("#{LYJB_240222_154}", g_FinishNum))
	else
		Anniversary2024_Yure_Text:SetText(ScriptGlobal_Format("#{LYJB_240222_08}", g_FinishNum))
	end
	
	if g_GetPrize == 1 then
		Anniversary2024_Yure_RewardBtn:Disable()
		Anniversary2024_Yure_Reward_tips:Hide()
		Anniversary2024_Yure_RewardBtnOK:Show()
	elseif g_FinishNum == g_MaxPage then
		Anniversary2024_Yure_RewardBtn:Enable()
		Anniversary2024_Yure_Reward_tips:Show()
		Anniversary2024_Yure_RewardBtnOK:Hide()
	else
		Anniversary2024_Yure_RewardBtn:Enable()
		Anniversary2024_Yure_Reward_tips:Hide()
		Anniversary2024_Yure_RewardBtnOK:Hide()	
	end
	
	--新增控件
	if g_CurPage <= g_FinishNum then
		Anniversary2024_Yure_ImageOver:Show()
	else
		Anniversary2024_Yure_ImageOver:Hide()
	end
	
end

--==============
-- 点击左侧箭头
--==============
function Anniversary2024_Yure_Page_Left()

	if g_CurPage == 1 then
		PushDebugMessage("#{LYJB_240222_10}")
		return
	end

	if (g_CurPage-1) >= 1 then
		g_CurPage = g_CurPage - 1
		Anniversary2024_Yure_Open()
	end
	
end

--==============
-- 点击右侧箭头
--==============
function Anniversary2024_Yure_Page_Right()

	if g_CurPage == g_JieSuoNum then
		if g_JieSuoNum == g_MaxPage then
			PushDebugMessage("#{LYJB_240222_11}")
		else
			PushDebugMessage("#{LYJB_240222_12}")
		end
		return
	end
	
	if (g_CurPage+1) <= g_JieSuoNum then
		g_CurPage = g_CurPage + 1
		Anniversary2024_Yure_Open()
	end
	
end

--=========
-- 寻路
--=========
function Anniversary2024_Yure_GotoNpc()
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay < g_Begintime or curDay > g_Endtime then
		PushDebugMessage("#{LYJB_240222_14}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{LYJB_240222_15}")
		return
	end	
	AutoRuntoTargetExWithName(g_posX, g_posZ, 0, g_name)
	PushDebugMessage("#{LYJB_240222_25}")
end

--=========
-- 点击领奖
--=========
function Anniversary2024_Yure_GetReward(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 999039 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end

--=========
-- 问号帮助
--=========
function Anniversary2024_Yure_ForHelp()
	PushEvent("CCSHOP_HELP", 207)
end

--=========
-- Close
--=========
function Anniversary2024_Yure_Close()

	this:Hide()

end