--花朝节 dujm

--time代表的是活动时间 各个功能自己填写 如果有多个时间阶段 不同的时间显示不同的tips 那么就都填写上
--tips 根据time配置的时间 根据 各个时间间隔显示不同的tips 
--举例说明 最普通的就是两个时间A-B tips 就有三个  时间处于A之前显示tips1 处于A-B之间显示tips2 处于B之后显示Tips3
local g_HuaZhaoJie_Guide_Event = {
	[1] = {time={20260316,20260401,}, btntips={"#{SHH_211221_05}","#{SHH_211221_04}","#{SHH_211221_06}",},},	 		--做花笺
	[2] = {time={20260316,20260401,}, btntips={"#{ZHGJ_211227_03}","#{ZHGJ_211227_02}","#{ZHGJ_211227_04}",},},			--春日百花图
	[3] = {time={20220303,20220323,}, btntips={"#{HZYR_211222_73}","#{HZYR_211222_72}","#{HZYR_211222_74}",},},			--预热活动
	[4] = {time={20220317,20220403,}, btntips={"#{CFSN_220224_115}","#{CFSN_220224_05}","#{CFSN_220224_116}",},},			--春风送暖
	[5] = {time={20260316,20260401,}, btntips={"#{HZJZH_211221_11}","#{HZJZH_211221_11}","#{HZJZH_211221_11}",},},		--节日礼包
	[6] = {time={20220317,20220330,}, btntips={"#{XMPYRFF_210826_04}","#{XMPYRFF_210826_04}","#{XMPYRFF_210826_122}",},},		-- 繁光会宴
	[7] = {time={20260316,20260401,}, btntips={"#{HZJPH_231222_03}","#{HZJPH_231222_04}","#{HZJPH_231222_05}",},},		-- 花朝节排行榜活动
};

local g_HuaZhaoJie_Guide_Frame_UnifiedPosition
local g_Button_Guide_StateTemp = {1,1,1,1,1,1,1,}
local g_Tips_Guide_StateTemp =   {0,0,0,0,0,0,0,}
local g_HuaZhaoJie_Guide_Button ={}
local g_HuaZhaoJie_Guide_Tip = {} 
 
 
 
function HuaZhaoJie_Guide_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_HUAZHAOJIE_BEFORE",true)		--
	this:RegisterEvent("OPEN_HUAZHAOJIE_GUIDE",true)		--
	this:RegisterEvent("CLOSE_HUAZHAOJIE_GUIDE",true)		--	
end

function HuaZhaoJie_Guide_OnLoad()
	HuaZhaoJie_Guide_LoadControl()
	g_HuaZhaoJie_Guide_Frame_UnifiedPosition = HuaZhaoJie_Guide_FrameNULL:GetProperty("UnifiedPosition")	
end
--=========
-- 装载控件
--=========
function HuaZhaoJie_Guide_LoadControl()
	g_HuaZhaoJie_Guide_Button[1] 	= HuaZhaoJie_Guide_Activity1; 
	g_HuaZhaoJie_Guide_Button[2] 	= HuaZhaoJie_Guide_Activity2; --
	g_HuaZhaoJie_Guide_Button[3] 	= HuaZhaoJie_Guide_Activity3; --
	g_HuaZhaoJie_Guide_Button[4] 	= HuaZhaoJie_Guide_Activity4;
	g_HuaZhaoJie_Guide_Button[5] 	= HuaZhaoJie_Guide_FestivalGift1;
	g_HuaZhaoJie_Guide_Button[6] 	= HuaZhaoJie_Guide_Activity5;
	g_HuaZhaoJie_Guide_Button[7] 	= HuaZhaoJie_Guide_Activity6;

	g_HuaZhaoJie_Guide_Tip[1] 		= HuaZhaoJie_Guide_Activity1_Tips;
	g_HuaZhaoJie_Guide_Tip[2] 		= HuaZhaoJie_Guide_Activity2_Tips;
	g_HuaZhaoJie_Guide_Tip[3] 		= HuaZhaoJie_Guide_Activity3_Tips;
	g_HuaZhaoJie_Guide_Tip[4] 		= HuaZhaoJie_Guide_Activity4_Tips;
	g_HuaZhaoJie_Guide_Tip[5] 		= HuaZhaoJie_Guide_FestivalGift1_Tips;
	g_HuaZhaoJie_Guide_Tip[6] 		= HuaZhaoJie_Guide_Activity5_Tips;
	g_HuaZhaoJie_Guide_Tip[7] 		= HuaZhaoJie_Guide_Activity6_Tips;
end
--=========
-- Event
--=========
function HuaZhaoJie_Guide_OnEvent(event)

	if event == "CLOSE_HUAZHAOJIE_GUIDE" then
		if this:IsVisible() then
			HuaZhaoJie_Guide_Close()
			return
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		HuaZhaoJie_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		HuaZhaoJie_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		HuaZhaoJie_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88888501) then --显示小红点

		for index=1,table.getn(g_HuaZhaoJie_Guide_Button)  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index]  = TipsState
		end
		HuaZhaoJie_Guide_ShowButtonTips()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88888502) then --显示小红点
		local btnstatus = Get_XParam_INT(0)
		local tipstatus = Get_XParam_INT(1)
		if tipstatus == 0 then
			HuaZhaoJie_Guide_BtnGift_Tips:Hide()
		else
			HuaZhaoJie_Guide_BtnGift_Tips:Show()
		end
		if btnstatus == 0 then
			HuaZhaoJie_Guide_BtnGift:Hide() 
		else
			HuaZhaoJie_Guide_BtnGift:Show() 
		end
	elseif event == "OPEN_HUAZHAOJIE_GUIDE" then
		HuaZhaoJie_Guide_Open()
		this:Show() 
	end

end
 

--=========
-- 重置
--=========
function HuaZhaoJie_Guide_On_ResetPos()
	HuaZhaoJie_Guide_FrameNULL:SetProperty("UnifiedPosition", g_HuaZhaoJie_Guide_Frame_UnifiedPosition)
end

--=========
-- 关闭
--=========
function HuaZhaoJie_Guide_Close()  
	this:Hide()
end

--=========
-- 打开
--=========
function HuaZhaoJie_Guide_Open() 
	for index=1,table.getn(g_HuaZhaoJie_Guide_Button) do
		g_HuaZhaoJie_Guide_Button[index]:Hide()
		g_HuaZhaoJie_Guide_Tip[index]:Hide()
	end
	for index=1,table.getn(g_HuaZhaoJie_Guide_Button)  do
		 local ButtonState,TipsState = DataPool:Lua_GetHuaZhaoJieButtonState(index-1) 
		 g_Button_Guide_StateTemp[index] 	= ButtonState
		 g_Tips_Guide_StateTemp[index] 	    = TipsState
		 Lua_TDU_Log("HuaZhaoJie_Guide_Open index:"..index.." ButtonState:"..ButtonState.." TipsState"..TipsState)
	end

	local curDay = DataPool:GetServerDayTime() 
	for index=1,table.getn(g_HuaZhaoJie_Guide_Event) do 
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index] 
		local event  	   = g_HuaZhaoJie_Guide_Event[index]
		if isButtonShow == 1 then 
			g_HuaZhaoJie_Guide_Button[index]:Show()
			if curDay < event.time[1] then
				g_HuaZhaoJie_Guide_Button[index]:SetToolTip(event.btntips[1])
			elseif curDay > event.time[table.getn(event.time)] and event.btntips[table.getn(event.time)+1] ~= nil  then
				g_HuaZhaoJie_Guide_Button[index]:SetToolTip(event.btntips[table.getn(event.time)+1])
			end
			for i = 1, table.getn(event.time)-1 do
				if curDay >= event.time[i] and curDay <= event.time[i+1] and event.btntips[i+1] ~= nil then
					g_HuaZhaoJie_Guide_Button[index]:SetToolTip(event.btntips[i+1])
				end
			end
			if isTipsShow == 1 then
				g_HuaZhaoJie_Guide_Tip[index]:Show()
			end  
		end 
	end
  
	--设置小红点
	HuaZhaoJie_Guide_ShowButtonTips()
	--
	 
end

--===============================================
-- 设置Button 小红点
--===============================================
function HuaZhaoJie_Guide_ShowButtonTips() 
	local IsShowMiniMapPoint = 0
	for index=1,table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 and g_Button_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			if this:IsVisible() then 
				g_HuaZhaoJie_Guide_Tip[index]:Show()  
			end
		else
			g_HuaZhaoJie_Guide_Tip[index]:Hide() 
		end
	end
	--PushEvent("HUAZHAOJIETIPS",  IsShowMiniMapPoint)
	Lua_ShowQuickEnterPointTip(31, IsShowMiniMapPoint)
end

--===============================================
-- 打开老的周年庆界面 索引到各个功能
--===============================================
function HuaZhaoJie_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenChunHuaQianShuUI" )					-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 888931 )										-- 脚本编号
			Set_XSCRIPT_ParamCount( 0 ) 										-- 参数个数  
		Send_XSCRIPT()
	elseif clickId == 2 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenZheHuaGuJiuUI" )					-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 888946 )										-- 脚本编号
			Set_XSCRIPT_ParamCount( 0 ) 										-- 参数个数  
		Send_XSCRIPT()
	elseif clickId == 3 then  
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenMainUI")
			Set_XSCRIPT_ScriptID(888886)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 4 then 
		local curday = DataPool:GetServerDayTime()
		if curday > 20220330 then
			PushEvent("OPEN_JIUJIUXIAOHAN_SPRING_EXCHANGEPRIZE")
		else
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenWindowRequest")
			Set_XSCRIPT_ScriptID(888971)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end

	elseif clickId == 5 then  
		HuaZhaoJie_Guide_JieRi_Click() 
	elseif clickId == 6 then   
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenUI" )
			Set_XSCRIPT_ScriptID( 888765 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 7 then    
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AskOpenMainUI" )
			Set_XSCRIPT_ScriptID( 790077 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end 
end
 
function HuaZhaoJie_Guide_JieRi_Click()	

	local curDay = DataPool:GetServerDayTime()
	if curDay < g_HuaZhaoJie_Guide_Event[5].time[1] or curDay > g_HuaZhaoJie_Guide_Event[5].time[2] then
		PushDebugMessage("#{HZJZH_211221_05}")
		return
	end

	if Player:GetLevel() < 30 then
		PushDebugMessage("#{HZJZH_211221_04}")
		return
	end
	
	-- 活动攻略 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowClientUI" )
		Set_XSCRIPT_ScriptID( 888926 )
	Send_XSCRIPT()
end

function HuaZhaoJie_Guide_AllRewards_Click()
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_HuaZhaoJie_Guide_Event[5].time[1] or curDay > g_HuaZhaoJie_Guide_Event[5].time[2] then
		PushDebugMessage("#{HZJZH_211221_14}")
		return
	end

	if Player:GetLevel() < 30 then
		PushDebugMessage("#{HZJZH_211221_15}")
		return
	end

	PushEvent("UI_COMMAND", 88892600)
end