-- zhongqiu 中秋主界面

local g_ZQMain_Event = 
{
    -- 各功能按照注释顺序修改即可
    -- 中秋锦鲤 换成中秋节祭嫦娥了
    [1] = {begtime=20220901, endtime =20220918, level =30, btntips_unbeg="#{CQD_210806_06}", btntips_doing="#{CQD_210806_06}", btntips_end="#{CQD_210806_06}",},
    --签到抽奖
    [2] = {begtime=20200917, endtime =20201004, level =30, btntips_unbeg="#{ZQQF_190724_07}", btntips_doing="#{ZQQF_190724_07}", btntips_end="#{ZQQF_190724_07}",},
    -- 每日一卦
    [3] = {begtime=20240916, endtime =20240929, level =30, btntips_unbeg="#{ZQQF_190724_08}", btntips_doing="#{ZQQF_190724_08}", btntips_end="#{ZQQF_190724_08}",},
    -- 千里共婵娟
	[4] = {begtime=20240916, endtime =20240929, level =30, btntips_unbeg="#{QLGCJ_190801_02}", btntips_doing="#{QLGCJ_190801_02}", btntips_end="#{QLGCJ_190801_02}",},
	[5] = {begtime=20240916, endtime =20240929, level =30, btntips_unbeg="#{ZQZH_200715_01}", btntips_doing="#{ZQZH_200715_01}", btntips_end="#{ZQZH_200715_01}",},--节日礼包
	[6] = {begtime=20240916, endtime =20240929, level =30, btntips_unbeg="", btntips_doing="", btntips_end="",},-- 活动攻略
};

local g_ZQMain_Frame_UnifiedPosition
local g_Button_Guide_StateTemp  = {1,1,1,1,1,1}
local g_Tips_Guide_StateTemp    = {0,0,0,0,0,0}

local g_ZQMain_Button           = {}
local g_ZQMain_Tip              = {}

-- -- 预热时间 第二阶段中秋锦鲤额外显示一张覆盖图 今年没有预热了
-- local g_ZQMain_PreBeginTime     = 20190905
-- local g_ZQMain_PreEndTime       = 20190911

-- NPC寻路信息 苏州（251,265）月纤纤
local g_infoNPCGoto     = 
{
    [1] = {nSceneID = 1, nPosX = 251, nPosY = 265, strNPCName = "月纤纤"},
}


-- 正式活动时间
--local g_ZQMain_BeginTime        = 20200917
--local g_ZQMain_EndTime          = 20201004

-- 当前服务器时间
local g_nCurServerDay			= 0

function ZQMain_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

function ZQMain_OnLoad()
	ZQMain_LoadControl()
	g_ZQMain_Frame_UnifiedPosition = ZQMain_Frame:GetProperty("UnifiedPosition") 
	
end
--=========
-- 装载控件
--=========
function ZQMain_LoadControl()

	g_ZQMain_Button[1] 	    = ZQMain_Btn1;
	g_ZQMain_Button[2] 	    = ZQMain_Btn2;
	g_ZQMain_Button[3] 	    = ZQMain_Btn3;
	g_ZQMain_Button[4] 	    = ZQMain_Btn4;
	g_ZQMain_Button[5] 	    = ZQMain_Btn5;
	g_ZQMain_Button[6] 	    = ZQMain_Btn6;

	g_ZQMain_Tip[1] 		= ZQMain_Btn1_Tips;
	g_ZQMain_Tip[2] 		= ZQMain_Btn2_Tips;
	g_ZQMain_Tip[3] 		= ZQMain_Btn3_Tips;
	g_ZQMain_Tip[4] 		= ZQMain_Btn4_Tips;
	g_ZQMain_Tip[5] 		= ZQMain_Btn5_Tips;
	g_ZQMain_Tip[6] 		= ZQMain_Btn6_Tips;

end
--=========
-- Event
--=========
function ZQMain_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 79001501) then -- 
		if this:IsVisible() then
			ZQMain_Close()
			return
		end
		-- AskServerTimeAgain()
		local bShowJieRiLiBao = Get_XParam_INT(7)
		ZQMain_Update(bShowJieRiLiBao)
		this:Show()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZQMain_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ZQMain_Close()

	elseif event == "ADJEST_UI_POS" then

		ZQMain_On_ResetPos()

	-- 刷新
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 79001502) then

		-- AskServerTimeAgain()
		local bShowJieRiLiBao = Get_XParam_INT(7)
		ZQMain_Update(bShowJieRiLiBao)
		-- for index=1,table.getn(g_ZQMain_Button)  do
		-- 	 local TipsState = Get_XParam_INT(index-1)
		-- 	 g_Tips_Guide_StateTemp[index]  = TipsState
		-- end
		-- ZQMain_ShowButtonTips()  		
	end

end
 
--=========
-- 重置
--=========
function ZQMain_On_ResetPos()

	ZQMain_Frame:SetProperty("UnifiedPosition", g_ZQMain_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function ZQMain_Close() 
	PushEvent("2020ZQ_CLOSE")
	this:Hide()
end

--=========
-- 刷新
--=========
function ZQMain_Update(bShowJieRiLiBao) 
	for index=1,table.getn(g_ZQMain_Tip) do 
		g_ZQMain_Tip[index]:Hide()
		g_ZQMain_Button[index]:Hide()
	end

	g_nCurServerDay = Get_XParam_INT(0) 
	for index=1,table.getn(g_ZQMain_Tip)  do
		 local TipsState = Get_XParam_INT(index) 
		 g_Tips_Guide_StateTemp[index] 	    = TipsState
	end

	local curDay = g_nCurServerDay
	local buttonId = 1
	for index=1,table.getn(g_ZQMain_Event) do
		local isButtonShow  = g_Button_Guide_StateTemp[index]
		local isTipsShow   	= g_Tips_Guide_StateTemp[index]
		local event  		= g_ZQMain_Event[index]

		if isButtonShow == 1 then 
			g_ZQMain_Button[buttonId]:Show()
			if curDay < event.begtime then
				g_ZQMain_Button[buttonId]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_ZQMain_Button[buttonId]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_ZQMain_Button[buttonId]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_ZQMain_Tip[buttonId]:Show()
			end
			event.isShow = 1
			buttonId = buttonId+1
		end
	end
	
	-- 特写去掉，今年没有预热了
	-- 锦鲤活动特写 特写展示图片和tips
	-- if curDay >= g_ZQMain_BeginTime and curDay <= g_ZQMain_EndTime then
	-- 	-- 活动第二阶段
	-- 	ZQMain_Btn1_Image : Show()
	-- 	-- 点击查看锦鲤献礼活动。 ZQJL_190725_118
	-- 	ZQMain_Btn1 : SetToolTip("#{ZQJL_190725_118}")
	-- elseif curDay >= g_ZQMain_PreBeginTime and curDay <= g_ZQMain_PreEndTime then
	-- 	-- 活动第一阶段
	-- 	ZQMain_Btn1_Image : Hide()
	-- 	-- 点击查看锦鲤现世活动。 ZQJL_190725_21
	-- 	ZQMain_Btn1 : SetToolTip("#{ZQJL_190725_21}")
	-- elseif curDay < g_ZQMain_PreBeginTime then
	-- 	-- 活动前
	-- 	ZQMain_Btn1_Image : Hide()
	-- 	ZQMain_Btn1 : SetToolTip("#{ZQJL_190725_21}")
	-- elseif curDay > g_ZQMain_EndTime then
	-- 	-- 活动后
	-- 	ZQMain_Btn1_Image : Show()
	-- 	ZQMain_Btn1 : SetToolTip("#{ZQJL_190725_118}")
	-- end
	
	-- 如果领过节日礼包 就不再主界面显示这个按钮了
	if bShowJieRiLiBao == 1 then
		g_ZQMain_Button[5]:Hide()
		g_ZQMain_Tip[5]:Hide()
	end
	
	--去掉巧弄千灯按钮
	g_ZQMain_Button[2]:Hide()
	g_ZQMain_Tip[2]:Hide()
		
	-- 设置小红点
	ZQMain_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function ZQMain_ShowButtonTips()

	local buttonId = 1
	for index=1,table.getn(g_ZQMain_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		if isButtonShow == 1 then
			if isTipsShow == 1 then
				g_ZQMain_Tip[buttonId]:Show()
			else
				g_ZQMain_Tip[buttonId]:Hide()
			end
			buttonId = buttonId+1
		end
	end

	local IsShowMiniMapPoint = 0
	for index=1,table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end

	--PushEvent("UI_COMMAND", 79001505, IsShowMiniMapPoint) 
	Lua_ShowQuickEnterPointTip(18, IsShowMiniMapPoint)
end

--===============================================
-- 打开各个功能界面
--===============================================
function ZQMain_Clicked( clickId )
    local curDay = g_nCurServerDay
    
    -- 各功能按照注释顺序修改即可
	-- 打开逻辑各个功能自己负责填写，包括条件判断提示、打开子界面操作、关闭主界面操作等
	-- 一般性来说，不需要处理关闭主界面操作，会要求界面配置的时候配成主界面和所有子界面互斥
    if clickId == 1 then 
		-- 签到
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenSignIn" )
			Set_XSCRIPT_ScriptID(888723)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
		return

    elseif clickId == 2 then 
        -- 中秋祈福
		--Clear_XSCRIPT()
		--	Set_XSCRIPT_Function_Name( "GetRedPoint" )
		--	Set_XSCRIPT_ScriptID(893161)
		--	Set_XSCRIPT_ParamCount(0)
		--Send_XSCRIPT()	
		--local curDay = DataPool:GetServerDayTime()
		--if curDay < g_ZQMain_BeginTime or curDay > g_ZQMain_EndTime then
		--	PushDebugMessage("#{ZQQF_190724_10}")
		--	return
		--end
		--local nLevel = Player:GetLevel();
		--if nLevel < 30 then
		--	PushDebugMessage("#{ZQQF_190724_11}")
		--	return
		--end
		--local bRet = AutoRuntoTargetExWithName(280, 183, 164, "苏轼")
		--if 0 == bRet then
		--	PushDebugMessage("无法自动寻路")
		--	return
		--end
		--PushDebugMessage("#{ZQQF_190724_12}")
		--return		
    elseif clickId == 3 then 
		local subEvent  = g_ZQMain_Event[clickId]
		if nil == subEvent then
			PushDebugMessage("非法按钮")
			return
		end
		
        -- 每日一卦 		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetRedPoint" )
			Set_XSCRIPT_ScriptID(893162)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
		
		local nCurDay = DataPool:GetServerDayTime()
		if nCurDay < subEvent.begtime or nCurDay > subEvent.endtime then
			PushDebugMessage("#{ZQQF_190724_13}")
			return
		end
		
		local nLevel = Player:GetLevel();
		if nLevel < 30 then
			PushDebugMessage("#{ZQQF_190724_14}")
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenGuaUI" )
			Set_XSCRIPT_ScriptID(893162)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
		return			
    elseif clickId == 4 then  
        -- 千里共婵娟
        Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenZhQiuRabbit" )
			Set_XSCRIPT_ScriptID(892904)			
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 5 then  
        -- 礼包
        Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID(888132)			
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 6 then  
        -- 攻略
        Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID(888131)			
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end 

end
