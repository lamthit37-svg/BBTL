--情人节整合

--time代表的是活动时间 各个功能自己填写 如果有多个时间阶段 不同的时间显示不同的tips 那么就都填写上
--tips 根据time配置的时间 根据 各个时间间隔显示不同的tips
--举例说明 最普通的就是两个时间A-B tips 就有三个  时间处于A之前显示tips1 处于A-B之间显示tips2 处于B之后显示Tips3
local g_Valentine_Guide_Event = {
	[1] = {time={20260205,20260215,}, btntips={"#{QRYJH_221104_108}","#{QRYJH_221104_3}","#{QRYJH_221104_110}",},},			--情人节应景活动
	[2] = {time={20260205,20260215,}, btntips={"#{QRJH_20221109_03}","#{QRJH_20221109_04}","#{QRJH_20221109_05}",},},			--情人节交互活动
	[3] = {time={20240212,20240221,}, btntips={"#{QRJJN_221118_04}","#{QRJJN_221118_05}","#{QRJJN_221118_06}",},},			--情人节纪念活动
	[4] = {time={20260205,20260215,}, btntips={"#{JHJL_220119_09}","#{JHJL_220119_08}","#{JHJL_220119_10}",},},			--七夕节结婚系统奖励回馈设计
	[5] = {time={20260205,20260215,}, btntips={"#{QRYJH_221104_111}","#{QRYJH_221104_112}","#{QRYJH_221104_110}",},},			--节日礼包
};

local g_Valentine_Guide_Frame_UnifiedPosition_Load
local g_Button_Guide_StateTemp = {1,1,1,1,1}
local g_Tips_Guide_StateTemp =   {0,0,0,0,0}
local g_Valentine_Guide_Button ={
}

local g_Valentine_Guide_Tip = {
}


local g_Valentine_Guide_BeginTime = 20260205
local g_Valentine_Guide_EndTime   = 20260215
local g_Ertongjie_GiftBtnTips = 0

function Valentine_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

end

function Valentine_Guide_OnLoad()

	Valentine_Guide_LoadControl()
    g_Valentine_Guide_Frame_UnifiedPosition_Load = Valentine_Guide_Frame:GetProperty("UnifiedPosition")
    
end

--=========
-- 装载控件
--=========
function Valentine_Guide_LoadControl()

	g_Valentine_Guide_Button[1] 	= Valentine_Guide_Btn1;
	g_Valentine_Guide_Button[2] 	= Valentine_Guide_Btn2;
	g_Valentine_Guide_Button[3] 	= Valentine_Guide_Btn3;
	g_Valentine_Guide_Button[4] 	= Valentine_Guide_Btn4;
	g_Valentine_Guide_Button[5]		= Valentine_Guide_BtnGift;

	g_Valentine_Guide_Tip[1] 		= Valentine_Guide_Btn1_Tips;
	g_Valentine_Guide_Tip[2] 		= Valentine_Guide_Btn2_Tips;
	g_Valentine_Guide_Tip[3] 		= Valentine_Guide_Btn3_Tips;
	g_Valentine_Guide_Tip[4] 		= Valentine_Guide_Btn4_Tips;
	g_Valentine_Guide_Tip[5]		= Valentine_Guide_BtnGift_Tips;


end
--=========
-- Event
--=========
function Valentine_Guide_OnEvent(event)

    if (event == "UI_COMMAND" and tonumber(arg0) == 99834502 )  then --打开
		Valentine_Guide_Open()
        this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Valentine_Guide_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Valentine_Guide_Close()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 99834503) then --显示小红点
		local actnum = table.getn(g_Valentine_Guide_Button)
		for index=1,actnum  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index]  = TipsState
		end
		Valentine_Guide_ShowButtonTips()
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89173801) then --891738寻路
		AutoRuntoTargetExWithName(139, 182, 0, "月老")
	end
end


--=========
-- 重置
--=========
function Valentine_Guide_On_ResetPos()

	Valentine_Guide_Frame:SetProperty("UnifiedPosition", g_Valentine_Guide_Frame_UnifiedPosition_Load)

end



--=========
-- 关闭
--=========
function Valentine_Guide_Close()
	this:Hide()
end

--=========
-- 打开
--=========
function Valentine_Guide_Open()

	for index=1,table.getn(g_Valentine_Guide_Button) do
		g_Valentine_Guide_Button[index]:Hide()
		g_Valentine_Guide_Tip[index]:Hide()
	end

	for index=1,table.getn(g_Valentine_Guide_Button)  do
		local DataState = Get_XParam_INT(index-1)
		local TipsState = math.mod(DataState, 10)
		local ButtonState = math.floor(DataState / 10)

		g_Button_Guide_StateTemp[index] 	= ButtonState
		g_Tips_Guide_StateTemp[index] 	    = TipsState

   end

	local curDay = DataPool:GetServerDayTime()
	for index=1,table.getn(g_Valentine_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		local event  	   = g_Valentine_Guide_Event[index]
		if isButtonShow == 1 then
			g_Valentine_Guide_Button[index]:Show()
			if curDay < event.time[1] then
				g_Valentine_Guide_Button[index]:SetToolTip(event.btntips[1])
			elseif curDay > event.time[table.getn(event.time)] and event.btntips[table.getn(event.time)+1] ~= nil  then
				g_Valentine_Guide_Button[index]:SetToolTip(event.btntips[table.getn(event.time)+1])
			end
			for i = 1, table.getn(event.time)-1 do
				if curDay >= event.time[i] and curDay <= event.time[i+1] and event.btntips[i+1] ~= nil then
					g_Valentine_Guide_Button[index]:SetToolTip(event.btntips[i+1])
				end
			end
			if isTipsShow == 1 then
				g_Valentine_Guide_Tip[index]:Show()
			end
		end
	end

	--设置小红点
	Valentine_Guide_ShowButtonTips()
	
end

--===============================================
-- 设置Button 小红点
--===============================================
function Valentine_Guide_ShowButtonTips()
	local IsShowMiniMapPoint = 0
	for index=1,table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 and g_Button_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			if this:IsVisible() then
				g_Valentine_Guide_Tip[index]:Show()
			end
		else
			g_Valentine_Guide_Tip[index]:Hide()
		end
	end

	--PushEvent("2023VALENTINETIPS",  IsShowMiniMapPoint)
	Lua_ShowQuickEnterPointTip(41, IsShowMiniMapPoint)

end

--===============================================
-- 打开情人节整合界面 索引到各个功能
--===============================================
function Valentine_Guide_Clicked( clickId )

    local curDay = DataPool:GetServerDayTime()
    
    if clickId == 1 then --情人节应景活动
        --PushDebugMessage("正在开发1")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(998366)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
    elseif clickId == 2 then --情人节交互活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUIMain")
			Set_XSCRIPT_ScriptID(998352)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
    elseif clickId == 3 then --情人节纪念活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenValentinesUI")
			Set_XSCRIPT_ScriptID(998356)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
    elseif clickId == 4 then --七夕节结婚系统奖励回馈设计
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnClick")
			Set_XSCRIPT_ScriptID(891738)
			Set_XSCRIPT_ParamCount(0)
        Send_XSCRIPT()
    elseif clickId == 9 then --节日礼包
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("Click_Gift")
        Set_XSCRIPT_ScriptID(998345)
        Set_XSCRIPT_ParamCount(0)
        Send_XSCRIPT()
    end
    
end
