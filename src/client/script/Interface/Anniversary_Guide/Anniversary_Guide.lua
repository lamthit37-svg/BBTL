--周年庆

--time代表的是活动时间 各个功能自己填写 如果有多个时间阶段 不同的时间显示不同的tips 那么就都填写上
--tips 根据time配置的时间 根据 各个时间间隔显示不同的tips 
--举例说明 最普通的就是两个时间A-B tips 就有三个  时间处于A之前显示tips1 处于A-B之间显示tips2 处于B之后显示Tips3
local g_Anniversary_Guide_Event = {
	[1] = {time={20260506,20260516,}, btntips={"#{SEZN_190326_66}","#{SEZN_190326_67}","#{SEZN_190326_68}",},},			--七日令（七日签、开门令）
	[2] = {time={20260506,20260520,}, btntips={"#{ZNDB_230215_08}","#{ZNDB_230215_07}","#{ZNDB_230215_09}",},},			--诗酒赠英豪
	[3] = {time={20260508,20260510,}, btntips={"#{SEZN_190326_80}","#{SEZN_190326_79}","#{SEZN_190326_79}",},},			--飞凰礼
	[4] = {time={20260417,20260430,}, btntips={"#{SEZN_190326_82}","#{SEZN_190326_82}","#{SEZN_190326_83}",},},			--灯如昼
	[5] = {time={20250506,20250520,}, btntips={"#{TJHF_230228_03}","#{TJHF_230228_02}","#{TJHF_230228_03}",},},			--降鸿福
	[6] = {time={20260417,20260430,}, btntips={"#{ZNXY_230324_01}","#{SEZN_190326_22}","#{SEZN_190326_23}",},},			--车锦绣
	[7] = {time={20240419,20240430,}, btntips={"#{ZNJHHD_210326_01}","#{ZNJHHD_210326_01}","#{ZNJHHD_210326_01}",},},	--韶景流年 未开xml隐藏了
	[8] = {time={20260501,20260505,}, btntips={"#{SLZN_230210_1}","#{SLZN_230210_2}","#{SLZN_230210_3}",},},			--钱庄理事
	[9] = {time={20230508,20230510,}, btntips={"#{SYYH_191206_182}","#{SYYH_191206_182}","#{SYYH_191206_182}",},},		--火树银花  未开xml隐藏了 
	[10]= {time={20250506,20250520,}, btntips={"#{CSDS_230216_02}","#{CSDS_230216_03}","#{CSDS_230216_04}",},},			--英豪破掳戏
	[11]= {time={20260501,20260505,}, btntips={"#{ZNDK_230214_03}","#{ZNDK_230214_04}","#{ZNDK_230214_05}",},},			--笑谈天龙事 
	[12]= {time={20260417,20260520,}, btntips={"#{ZNJS_230220_01}","#{ZNJS_230220_01}","#{ZNJS_230220_02}",},},	 		--江湖异闻录 
	[13]= {time={20260417,20260520,}, btntips={"#{ZNQYJ_220215_04}","#{ZNQYJ_220215_05}","#{ZNQYJ_220215_06}",},},	--龙腾万里 
	[14]= {time={20260417,20260430,}, btntips={"#{ZNLSG_230215_11}","#{ZNLSG_230215_10}","#{ZNLSG_230215_12}",},},	--物华宝图 
	[15]= {time={20260506,20260520,}, btntips={"#{ZNQSZ_230301_04}","#{ZNQSZ_230301_05}","#{ZNQSZ_230301_06}",},},	--浮生故梦 
	[16]= {time={20230424,20230428,}, btntips={"#{WMTL_230301_01}","#{WMTL_230301_01}","#{WMTL_230301_01}",},},	--豪礼酬八方  未开xml隐藏了
	[17]= {time={20260417,20260520,}, btntips={"#{ZNQYJ_220215_04}","#{ZNQYJ_220215_122}","#{ZNQYJ_220215_123}",},},	--苍龙夜影 
	[18]= {time={20240506,20240522,}, btntips={"#{WHTJ_240117_01}","#{WHTJ_240117_01}","#{WHTJ_240117_01}",},},	--时装拍卖 未开xml隐藏了
	[19]= {time={20240419,20240522,}, btntips={"#{YZWXS_240319_01}","#{YZWXS_240319_01}","#{YZWXS_240319_02}",},},	--燕子坞限时活动 未开xml隐藏了
};

local g_Anniversary_Guide_Frame_UnifiedPosition
local g_Button_Guide_StateTemp = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,}--
local g_Tips_Guide_StateTemp =   {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,}--
local g_Image_Guide_StateTemp =  {0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,}--

local g_Anniversary_Guide_Button ={
}
local g_Anniversary_Guide_Button_BK ={
}
local g_Anniversary_Guide_Button_Gift ={
}
local g_Anniversary_Guide_Frame_Gift ={
} 
local g_Anniversary_Guide_Tip = {
}  
local g_Anniversary_Guide_Image = {
} 
local g_Guide_EventIndex = -1 --当前选中的选项
local g_Anniversary_Guide_ButtonCDTime = 1; --按钮冷却时间
local g_Anniversary_Guide_ButtonLastTime = 0;
local g_Anniversary_Guide_LastClickedId = -1; --上次选中的选项
local g_Anniversary_Guide_EventIndex = -1 --当前选中的选项

local g_Anniversary_Guide_BeginTime = 20260417
local g_Anniversary_Guide_EndTime   = 20260520
local g_Anniversary_GiftBtnTips = 0
  
local g_Anniversary_Guide_ImageList = {
[13] = { 
	[1] = {"set:Anniversary_HolidayGift2023 image:SJ", "#{SLZN_230321_16}"},
	[2] = {"set:Anniversary_HolidayGift2023 image:YSQ", "#{SLZN_230321_18}"},
},
} 

function Anniversary_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",true)		--
	this:RegisterEvent("OPEN_ANNIVERSARY_GUIDE",true)		--
	this:RegisterEvent("CLOSE_ANNIVERSARY_GUIDE",true)		--
	
end

function Anniversary_Guide_OnLoad()
	Anniversary_Guide_LoadControl()
	g_Anniversary_Guide_Frame_UnifiedPosition = Anniversary_Guide_Frame:GetProperty("UnifiedPosition")
	
	--local from_to_info_Front = string.format("curve:Liner mode:Loop duration:90 startx:0 starty:0 endx:-512 endy:0")
	--Anniversary_Guide_CloudFront:Tween_SetInfo("Position", from_to_info_Front)
	--
	--local from_to_info_Behind = string.format("curve:Liner mode:Loop duration:95 startx:0 starty:0 endx:-512 endy:0")
	--Anniversary_Guide_CloudBehind:Tween_SetInfo("Position", from_to_info_Behind) 
	
end
--=========
-- 装载控件
--=========
function Anniversary_Guide_LoadControl()

	g_Anniversary_Guide_Button_BK[1] 	= Anniversary_Guide_Btn1_BK; 
	g_Anniversary_Guide_Button_BK[2] 	= Anniversary_Guide_Btn2_BK;
	g_Anniversary_Guide_Button_BK[3] 	= Anniversary_Guide_Btn3_BK;
	g_Anniversary_Guide_Button_BK[4] 	= Anniversary_Guide_Btn4_BK;
	g_Anniversary_Guide_Button_BK[5] 	= Anniversary_Guide_Btn5_BK;
	g_Anniversary_Guide_Button_BK[6] 	= Anniversary_Guide_Btn6_BK;
	g_Anniversary_Guide_Button_BK[7] 	= Anniversary_Guide_Btn7_BK;
	g_Anniversary_Guide_Button_BK[8] 	= Anniversary_Guide_Btn8_BK;
	g_Anniversary_Guide_Button_BK[9] 	= Anniversary_Guide_Btn9_BK;
	g_Anniversary_Guide_Button_BK[10] 	= Anniversary_Guide_Btn10_BK;
	g_Anniversary_Guide_Button_BK[11] 	= Anniversary_Guide_Btn11_BK;
	g_Anniversary_Guide_Button_BK[12] 	= Anniversary_Guide_Btn12_BK; 
	g_Anniversary_Guide_Button_BK[13] 	= Anniversary_Guide_Btn13_BK;  
	g_Anniversary_Guide_Button_BK[14] 	= Anniversary_Guide_Btn14_BK;   
	g_Anniversary_Guide_Button_BK[15] 	= Anniversary_Guide_Btn15_BK;  
	g_Anniversary_Guide_Button_BK[16] 	= Anniversary_Guide_Btn16_BK; 
	g_Anniversary_Guide_Button_BK[17] 	= Anniversary_Guide_Btn17_BK; 
	g_Anniversary_Guide_Button_BK[18] 	= Anniversary_Guide_Btn18_BK; 
	g_Anniversary_Guide_Button_BK[19] 	= Anniversary_Guide_Btn19_BK; 

	g_Anniversary_Guide_Button[1] 	= Anniversary_Guide_Btn1; 
	g_Anniversary_Guide_Button[2] 	= Anniversary_Guide_Btn2;
	g_Anniversary_Guide_Button[3] 	= Anniversary_Guide_Btn3;
	g_Anniversary_Guide_Button[4] 	= Anniversary_Guide_Btn4;
	g_Anniversary_Guide_Button[5] 	= Anniversary_Guide_Btn5;
	g_Anniversary_Guide_Button[6] 	= Anniversary_Guide_Btn6;
	g_Anniversary_Guide_Button[7] 	= Anniversary_Guide_Btn7;
	g_Anniversary_Guide_Button[8] 	= Anniversary_Guide_Btn8;
	g_Anniversary_Guide_Button[9] 	= Anniversary_Guide_Btn9;
	g_Anniversary_Guide_Button[10] 	= Anniversary_Guide_Btn10;
	g_Anniversary_Guide_Button[11] 	= Anniversary_Guide_Btn11;
	g_Anniversary_Guide_Button[12] 	= Anniversary_Guide_Btn12; 
	g_Anniversary_Guide_Button[13] 	= Anniversary_Guide_Btn13;  
	g_Anniversary_Guide_Button[14] 	= Anniversary_Guide_Btn14;   
	g_Anniversary_Guide_Button[15] 	= Anniversary_Guide_Btn15;  
	g_Anniversary_Guide_Button[16] 	= Anniversary_Guide_Btn16; 
	g_Anniversary_Guide_Button[17] 	= Anniversary_Guide_Btn17; 
	g_Anniversary_Guide_Button[18] 	= Anniversary_Guide_Btn18; 
	g_Anniversary_Guide_Button[19] 	= Anniversary_Guide_Btn19; 
	
	g_Anniversary_Guide_Tip[1] 		= Anniversary_Guide_Btn1_Tips;
	g_Anniversary_Guide_Tip[2] 		= Anniversary_Guide_Btn2_Tips;
	g_Anniversary_Guide_Tip[3] 		= Anniversary_Guide_Btn3_Tips;
	g_Anniversary_Guide_Tip[4] 		= Anniversary_Guide_Btn4_Tips;
	g_Anniversary_Guide_Tip[5] 		= Anniversary_Guide_Btn5_Tips;
	g_Anniversary_Guide_Tip[6] 		= Anniversary_Guide_Btn6_Tips;
	g_Anniversary_Guide_Tip[7] 		= Anniversary_Guide_Btn7_Tips;
	g_Anniversary_Guide_Tip[8] 		= Anniversary_Guide_Btn8_Tips;
	g_Anniversary_Guide_Tip[9] 		= Anniversary_Guide_Btn9_Tips;
	g_Anniversary_Guide_Tip[10] 	= Anniversary_Guide_Btn10_Tips;
	g_Anniversary_Guide_Tip[11] 	= Anniversary_Guide_Btn11_Tips;
	g_Anniversary_Guide_Tip[12] 	= Anniversary_Guide_Btn12_Tips; 
	g_Anniversary_Guide_Tip[13] 	= Anniversary_Guide_Btn13_Tips;  
	g_Anniversary_Guide_Tip[14] 	= Anniversary_Guide_Btn14_Tips;  
	g_Anniversary_Guide_Tip[15] 	= Anniversary_Guide_Btn15_Tips;   
	g_Anniversary_Guide_Tip[16] 	= Anniversary_Guide_Btn16_Tips; 
	g_Anniversary_Guide_Tip[17] 	= Anniversary_Guide_Btn17_Tips; 
	g_Anniversary_Guide_Tip[18] 	= Anniversary_Guide_Btn18_Tips; 
	g_Anniversary_Guide_Tip[19] 	= Anniversary_Guide_Btn19_Tips; 

	g_Anniversary_Guide_Image[1] 	= Anniversary_Guide_Btn1_Image;
	g_Anniversary_Guide_Image[2] 	= Anniversary_Guide_Btn2_Image;
	g_Anniversary_Guide_Image[3] 	= Anniversary_Guide_Btn3_Image;
	g_Anniversary_Guide_Image[4] 	= Anniversary_Guide_Btn4_Image;
	g_Anniversary_Guide_Image[5] 	= Anniversary_Guide_Btn5_Image;
	g_Anniversary_Guide_Image[6] 	= Anniversary_Guide_Btn6_Image;
	g_Anniversary_Guide_Image[7] 	= Anniversary_Guide_Btn7_Image;
	g_Anniversary_Guide_Image[8] 	= Anniversary_Guide_Btn8_Image;
	g_Anniversary_Guide_Image[9] 	= Anniversary_Guide_Btn9_Image;
	g_Anniversary_Guide_Image[10] 	= Anniversary_Guide_Btn10_Image;
	g_Anniversary_Guide_Image[11] 	= Anniversary_Guide_Btn11_Image;
	g_Anniversary_Guide_Image[12] 	= Anniversary_Guide_Btn12_Image; 
	g_Anniversary_Guide_Image[13] 	= Anniversary_Guide_Btn13_Image;  
	g_Anniversary_Guide_Image[14] 	= Anniversary_Guide_Btn14_Image;  
	g_Anniversary_Guide_Image[15] 	= Anniversary_Guide_Btn15_Image;   
	g_Anniversary_Guide_Image[16] 	= Anniversary_Guide_Btn16_Image; 
	g_Anniversary_Guide_Image[17] 	= Anniversary_Guide_Btn17_Image; 
	g_Anniversary_Guide_Image[18] 	= Anniversary_Guide_Btn18_Image; 
	g_Anniversary_Guide_Image[19] 	= Anniversary_Guide_Btn19_Image; 
end
--=========
-- Event
--=========
function Anniversary_Guide_OnEvent(event)

	if (event == "OPEN_ANNIVERSARY_BEFORE")  then
		if this:IsVisible() then
			Anniversary_Guide_Close()
			return
		end
		AskServerTimeAgain() 
		Anniversary_Guide_OpenBefore(0)
	elseif event == "CLOSE_ANNIVERSARY_GUIDE" then
		if this:IsVisible() then
			Anniversary_Guide_Close()
			return
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Anniversary_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		Anniversary_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 23200401) then --显示小红点

		Anniversary_Guide_Open()
			
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 23200402) then --显示小红点
		local btnstatus = Get_XParam_INT(0)
		g_Anniversary_GiftBtnTips = Get_XParam_INT(1)
		if g_Anniversary_GiftBtnTips == 0 then
			Anniversary_Guide_BtnGift_Tips:Hide()
		else
			Anniversary_Guide_BtnGift_Tips:Show()
		end
		if btnstatus == 0 then
			Anniversary_Guide_BtnGift:Hide() 
		else
			Anniversary_Guide_BtnGift:Show() 
		end
		Anniversary_Guide_ShowButtonTips()
	elseif event == "OPEN_ANNIVERSARY_GUIDE" then
		Anniversary_Guide_Open()
		this:Show() 
	end

end

--===============================================
-- Open()
--===============================================
function  Anniversary_Guide_OpenBefore(nDengRuZhou) 
	local curDay = DataPool:GetServerDayTime()
	if curDay > g_Anniversary_Guide_EndTime or curDay < g_Anniversary_Guide_BeginTime then
		PushDebugMessage("#{SEZN_190326_63}")
		return
	end  
	if nDengRuZhou == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenAnniversary")
			Set_XSCRIPT_ScriptID(232004)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenAnniversary")
			Set_XSCRIPT_ScriptID(232004)
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

--=========
-- 重置
--=========
function Anniversary_Guide_On_ResetPos()

	Anniversary_Guide_Frame:SetProperty("UnifiedPosition", g_Anniversary_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function Anniversary_Guide_Close()  
	this:Hide()
end

--=========
-- 打开
--=========
function Anniversary_Guide_Open() 
	for index=1,table.getn(g_Anniversary_Guide_Button) do
		g_Anniversary_Guide_Button_BK[index]:Hide()
		g_Anniversary_Guide_Button[index]:Hide()
		g_Anniversary_Guide_Tip[index]:Hide()
		g_Anniversary_Guide_Image[index]:Hide()
	end
	for index=1,table.getn(g_Anniversary_Guide_Button)  do
		 local ButtonState,TipsState,ImageState = DataPool:Lua_GetAnniversaryButtonState(index-1) 
		 g_Button_Guide_StateTemp[index] 	= ButtonState
		 g_Tips_Guide_StateTemp[index] 	    = TipsState
		 g_Image_Guide_StateTemp[index]		= ImageState
		 --Lua_TDU_Log("Anniversary_Guide_Open index:"..index.." ButtonState:"..ButtonState.." TipsState"..TipsState)
	end

	--设置按钮
	Anniversary_Guide_ShowButton()
  
	--设置小红点
	Anniversary_Guide_ShowButtonTips()
	--
	 
end

--===============================================
-- 设置Button 
--===============================================
function Anniversary_Guide_ShowButton() 

	local curDay = DataPool:GetServerDayTime() 
	for index=1,table.getn(g_Anniversary_Guide_Event) do 
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index] 
		local event  	   = g_Anniversary_Guide_Event[index]
		local isImageShow  = g_Image_Guide_StateTemp[index] 
		if isButtonShow == 1 then 
			g_Anniversary_Guide_Button_BK[index]:Show()
			g_Anniversary_Guide_Button[index]:Show()
			if curDay < event.time[1] then
				g_Anniversary_Guide_Button[index]:SetToolTip(event.btntips[1])
			elseif curDay > event.time[table.getn(event.time)] and event.btntips[table.getn(event.time)+1] ~= nil  then
				g_Anniversary_Guide_Button[index]:SetToolTip(event.btntips[table.getn(event.time)+1])
			end
			for i = 1, table.getn(event.time)-1 do
				if curDay >= event.time[i] and curDay <= event.time[i+1] and event.btntips[i+1] ~= nil then
					g_Anniversary_Guide_Button[index]:SetToolTip(event.btntips[i+1])
				end
			end
			--if KaJi:LuaFnIsKaJiServer() == 1 and index == 10 then --盛宴狂欢 卡级服特写
			--	g_Anniversary_Guide_Button[index]:SetToolTip("#{SJFLKJ_220107_2}")
			--end
			if isTipsShow == 1 then
				g_Anniversary_Guide_Tip[index]:Show()
			end  
			
			if isImageShow >= 1 then
				g_Anniversary_Guide_Image[index]:Show()
				--if g_Anniversary_Guide_ImageList[index] ~= nil and g_Anniversary_Guide_ImageList[index][isImageShow] ~= nil then
				--	g_Anniversary_Guide_Image[index]:SetProperty("Image", g_Anniversary_Guide_ImageList[index][isImageShow][1])
				--	g_Anniversary_Guide_Image[index]:SetToolTip(g_Anniversary_Guide_ImageList[index][isImageShow][2])
				--end
			end
		end 
	end
  
end

--===============================================
-- 设置Button 小红点
--===============================================
function Anniversary_Guide_ShowButtonTips() 
	local IsShowMiniMapPoint = 0
	for index=1,table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 and g_Button_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			if this:IsVisible() then 
				g_Anniversary_Guide_Tip[index]:Show()  
			end
		else
			g_Anniversary_Guide_Tip[index]:Hide() 
		end
	end

	if IsShowMiniMapPoint == 0 and g_Anniversary_GiftBtnTips == 1 then
		IsShowMiniMapPoint = 1
	end
	--PushEvent("ZHOUNIANQINGTIPS",  IsShowMiniMapPoint)
	Lua_ShowQuickEnterPointTip(5, IsShowMiniMapPoint)

end

--===============================================
-- 打开老的周年庆界面 索引到各个功能
--===============================================
function Anniversary_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then --七日令
		-- 七日令（七日签、开门令）`
		if curDay < g_Anniversary_Guide_Event[clickId].time[1] then
			PushDebugMessage("#{SEZN_190326_19}")
			return
		elseif curDay > g_Anniversary_Guide_Event[clickId].time[2] then
			PushDebugMessage("#{SEZN_190326_20}")
			return
		else
			PushEvent("OPEN_ANNIVERSARY",  1)
		end 
	elseif clickId == 2 then		
		--代币整合活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(998444) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		
	elseif clickId == 3 then 
		--飞凰礼
		if curDay > g_Anniversary_Guide_Event[clickId].time[2] then
			PushDebugMessage("#{SEZN_190326_34}")
			return
		else
			PushEvent("OPEN_ANNIVERSARY",  4)
		end
	elseif clickId == 4 then --灯如昼		
		PushEvent("OPEN_ANNIVERSARY",  5)
	elseif clickId == 5 then  --降鸿福
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenDetailUI")
			Set_XSCRIPT_ScriptID(890676) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 6 then --车锦绣 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenDetailUI")
			Set_XSCRIPT_ScriptID(891059) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 7 then  --韶景流年
		local nLevel = Player:GetLevel();
		if curDay < g_Anniversary_Guide_Event[clickId].time[1] then
			PushDebugMessage("#{ZNJHHD_210326_02}")
			return
		elseif curDay > g_Anniversary_Guide_Event[clickId].time[2] then
			PushDebugMessage("#{ZNJHHD_210326_02}")
			return
		elseif nLevel < 30 then
			PushDebugMessage("#{ZNJHHD_210326_03}")
			return
		else 		
			AutoRunToTargetEx(261,248,0)
			SetAutoRunTargetNPCName( "周年清" )

			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ClickToday")
				Set_XSCRIPT_ScriptID(888413) 
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
		end 	
	elseif clickId == 8 then  	-- 周年h5		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpen")
			Set_XSCRIPT_ScriptID(998436)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 9 then  --火树银花		
		PushDebugMessage("#{SYYH_191206_183}")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("MarkRedPoint")
			Set_XSCRIPT_ScriptID(893378)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 10 then --打地鼠活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(998445)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 11 then --游戏内打卡
		--周年打卡活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(998417) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 12 then --周年庆市集    
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnRecMessage")
			Set_XSCRIPT_ScriptID(998437)
			Set_XSCRIPT_Parameter(0, 1) --ntype	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif clickId == 13 then --周年庆应景
		if IsInTServer() == 1 then
			--T服不允许操作
			PushDebugMessage("#{ZNQYJ_220215_120}")
			return
		end

		if Player:GetLevel() < 30 then
			PushDebugMessage("#{ZNQYJ_220215_02}")
			return
		end
		if curDay < g_Anniversary_Guide_Event[clickId].time[1] or curDay > g_Anniversary_Guide_Event[clickId].time[2] then
			PushDebugMessage("#{ZNQYJ_220215_03}")
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("PushMainUI")
			Set_XSCRIPT_ScriptID(888480)
			Set_XSCRIPT_Parameter(0, 1) --ntype	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif clickId == 14 then --周年庆拉收
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenMainUI")
			Set_XSCRIPT_ScriptID(290400) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 15 then --浮生故梦
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnClickOpenUI")
			Set_XSCRIPT_ScriptID(998460)
			Set_XSCRIPT_Parameter(0, 1) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif clickId == 16 then --豪礼酬八方
		if curDay < g_Anniversary_Guide_Event[clickId].time[1] or curDay > g_Anniversary_Guide_Event[clickId].time[2] then
			PushDebugMessage("#{WMTL_230301_02}")
			return
		end
		if Player:GetLevel() < 30 then
			PushDebugMessage("#{WMTL_230301_03}")
			return
		end
	
		PushEvent("OPEN_WANMEITIANLONG")
	elseif clickId == 17 then --时装兑换
		if IsInTServer() == 1 then
			--T服不允许操作
			PushDebugMessage("#{ZNQYJ_220215_120}")
			return
		end

		if Player:GetLevel() < 30 then
			PushDebugMessage("#{ZNQYJ_220215_02}")
			return
		end
		if curDay < g_Anniversary_Guide_Event[clickId].time[1] or curDay > g_Anniversary_Guide_Event[clickId].time[2] then
			PushDebugMessage("#{ZNQYJ_220215_03}")
			return
		end
		--领取时装
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnAskOpenDressUI")
			Set_XSCRIPT_ScriptID(888483)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 18 then --时装拍卖
		if IsInHell() == 1 then
			PushDebugMessage("#{WHTJ_240117_04}")	--当前场景无法进行此操作
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("TryOpenFashionAuction")
			Set_XSCRIPT_ScriptID(777888)
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_Parameter(2, 0) --是否收刷新cd限制
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif clickId == 19 then --燕子坞活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenFlushOrCloseUI")
			Set_XSCRIPT_ScriptID(999090)
			Set_XSCRIPT_Parameter(0, 1) --打开
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	end  
end

function Anniversary_Guide_ActivityRaiders_Click()
	PushEvent("UI_COMMAND", 23200400)
end

function Anniversary_Guide_BtnGift_Click()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("Click_Gift")
	Set_XSCRIPT_ScriptID(232004) 
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
