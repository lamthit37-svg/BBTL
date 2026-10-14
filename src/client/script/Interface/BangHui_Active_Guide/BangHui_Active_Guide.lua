--帮会活跃主界面
local g_Frame_UnifiedPosition

--活动按钮小红点
local g_ButtonShowList = {}

-- 活动等级限制
local g_LimitLevel = 30

local g_Button_Guide_StateTemp = {1,1,1}
local g_Tips_Guide_StateTemp = {0,0,0}

--=========
-- PreLoad
--=========
function BangHui_Active_Guide_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

end

--=========
-- OnLoad
--=========
function BangHui_Active_Guide_OnLoad()

	g_Frame_UnifiedPosition = BangHui_Active_Guide_Frame:GetProperty("UnifiedPosition") 

	g_ButtonShowList = 
	{
		[1] = { btn = BangHui_Active_Guide_Btn1, tips = BangHui_Active_Guide_Btn1_Tips, bTipShow = 0, btntips="#{BHHYRW_230301_3}", }, --帮会活跃
		[2] = { btn = BangHui_Active_Guide_Btn2, tips = BangHui_Active_Guide_Btn2_Tips, bTipShow = 0, btntips="#{CZSJ_230301_02}", }, --城战奖励升级
		[3] = { btn = BangHui_Active_Guide_Btn3, tips = BangHui_Active_Guide_Btn3_Tips, bTipShow = 0, btntips="#{LXQD_220719_6}", }, --连签寻宝
	}
	
end

--=========
-- OnEvent
--=========
function BangHui_Active_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 99845501 then
		--更新红点
		if this:IsVisible() then
			BangHui_Active_Guide_Update()
		end

	elseif event == "UI_COMMAND" and tonumber(arg0) == 99845502 then
		if this:IsVisible() then
			this:Hide()
			return
		end

		BangHui_Active_Guide_Update()
		this:Show()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		BangHui_Active_Guide_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		BangHui_Active_Guide_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		BangHui_Active_Guide_OnClose()
		
	end

end

--=========
-- 重置
--=========
function BangHui_Active_Guide_On_ResetPos()

	BangHui_Active_Guide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 打开
--=========
function BangHui_Active_Guide_Update()

	
	for i = 1, table.getn(g_ButtonShowList) do
		g_ButtonShowList[i].btn:Hide()
		g_ButtonShowList[i].tips:Hide()
	end

	for i = 1,table.getn(g_ButtonShowList)  do
		 local DataState = Get_XParam_INT(i-1)
		 local TipsState = math.mod(DataState, 10)
		 local ButtonState = math.floor(DataState / 10)

		 g_Button_Guide_StateTemp[i] = ButtonState
		 g_Tips_Guide_StateTemp[i] = TipsState

	end

	local curDay = DataPool:GetServerDayTime()
	for i=1,table.getn(g_ButtonShowList) do
		local isButtonShow = g_Button_Guide_StateTemp[i]
		local isTipsShow   	= g_Tips_Guide_StateTemp[i]

		if isButtonShow == 1 then
			g_ButtonShowList[i].btn:Show()
			g_ButtonShowList[i].btn:SetToolTip(g_ButtonShowList[i].btntips)
			if isTipsShow == 1 then
				g_ButtonShowList[i].tips:Show()
			end

		end
	end
end

--=========
-- 关闭
--=========
function BangHui_Active_Guide_OnClose()

	BangHui_Active_Guide_OnHiden()
end

--=========
-- 隐藏
--=========
function BangHui_Active_Guide_OnHiden()
	this:Hide()
end

--=========
-- 点击事件
--=========
function BangHui_Active_Guide_Clicked(clickId)
	local curDay = DataPool:GetServerDayTime()
	
	if clickId == 1 then 	
		
		local nLevel = Player:GetLevel()
		if nLevel < g_LimitLevel then
			PushDebugMessage("#{CJYJ_211203_02}")
			return
		end		
		
		Guild:OpenGuildActiveFrame()	

	elseif clickId == 2 then

		local nLevel = Player:GetData("LEVEL")
		if  (nLevel < 30) then
			-- 不到30级
			PushDebugMessage("#{CZSJ_230301_06}")
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("UpdateRedPoint")
			Set_XSCRIPT_ScriptID(998213)
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

		-- 城战奖励升级
		PushEvent("2023Q1_TCW_AWARDENHANCE_OPEN")
	elseif clickId == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenWindowRequest")
			Set_XSCRIPT_ScriptID(998172)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
		
end

--=========
-- 小问号
--=========
function BangHui_Active_Guide_Help()
	PushEvent("CCSHOP_HELP", 141)
end


