--双旦系列

local g_ShuangDan_Guide_Frame_UnifiedPosition

local g_ShuangDan_Guide_Event = {
	--浮花拾晓 
	--[1] = {begtime=20231214, endtime =20240107, level =30, 
	--		btntips_unbeg="#{GQKJ_190722_07}", 
	--		btntips_doing="#{FHSX_211019_05}", 
	--		btntips_end="#{GQKJ_190722_08}",
	--		},
	--踏雪寻芳
	[1] = {begtime=20231214, endtime =20240107, level =30, 
			btntips_unbeg="#{SDQY_211101_01}", 
			btntips_doing="#{SDQY_211101_01}", 
			btntips_end="#{SDQY_211101_01}",
			},
	--清欢百味
	[2] = {begtime=20231214, endtime =20240107, level =30, 
			btntips_unbeg="#{BWQH_211027_04}", 
			btntips_doing="#{BWQH_211027_04}", 
			btntips_end="#{BWQH_211027_05}",
			},
	--飞花解意
	[3] = {begtime=20231214, endtime =20240107, level =30, 
			btntips_unbeg="#{SDCJ_231026_01}", 
			btntips_doing="#{SDCJ_231026_01}", 
			btntips_end="#{SDCJ_231026_02}",
			},	
	--东君有信
	[4] = {begtime=20231214, endtime =20240107, level =30, 
			btntips_unbeg="#{YDHD_171206_06}", 
			btntips_doing="#{YDHD_171206_06}", 
			btntips_end="#{YDHD_171206_06}",
			},	
	--圣诞节礼包
	[5] = {begtime=20231214, endtime =20231230, level =30, 
			btntips_unbeg="#{SDLB_211020_01}", 
			btntips_doing="#{SDLB_211020_01}", 
			btntips_end="#{SDLB_211020_01}",
			},	
	--元旦礼包
	[6] = {begtime=20231231, endtime =20240107, level =30, 
			btntips_unbeg="#{YDLB_211009_2}", 
			btntips_doing="#{YDLB_211009_2}", 
			btntips_end="#{YDLB_211009_2}",
			},
	--寒芳满衣
	--[8] = {begtime=20231214, endtime =20240107, level =30, 
	--		btntips_unbeg="#{GQKJ_190722_20}", 
	--		btntips_doing="#{FHSX_211019_108}", 
	--		btntips_end="#{GQKJ_190722_21}",
	--		},
};

local g_ShuangDan_Button_Guide_StateTemp = {1,1,1,1,1,1,1,1}
local g_ShuangDan_Tips_Guide_StateTemp = {0,0,0,0,0,0,0,0}

local g_ShuangDan_Guide_Button ={}
local g_ShuangDan_Guide_Tip = {}

function ShuangDan_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

function ShuangDan_Guide_OnLoad()

	ShuangDan_Guide_LoadControl()
	
	g_ShuangDan_Guide_Frame_UnifiedPosition = ShuangDan_Guide_FrameNULL:GetProperty("UnifiedPosition") 
	
end

--=========
-- 装载控件
--=========
function ShuangDan_Guide_LoadControl()

	--g_ShuangDan_Guide_Button[1] 	= ShuangDan_Guide_Activity1
	g_ShuangDan_Guide_Button[1] 	= ShuangDan_Guide_Activity2 
	g_ShuangDan_Guide_Button[2] 	= ShuangDan_Guide_Activity3
	g_ShuangDan_Guide_Button[3] 	= ShuangDan_Guide_Activity4
	g_ShuangDan_Guide_Button[4] 	= ShuangDan_Guide_Activity5
	g_ShuangDan_Guide_Button[5] 	= ShuangDan_Guide_FestivalGift1
	g_ShuangDan_Guide_Button[6] 	= ShuangDan_Guide_FestivalGift2
	--g_ShuangDan_Guide_Button[8] 	= ShuangDan_Guide_Activity6
	
	--g_ShuangDan_Guide_Tip[1] 	= ShuangDan_Guide_Activity1_Tips
	g_ShuangDan_Guide_Tip[1] 	= ShuangDan_Guide_Activity2_Tips
	g_ShuangDan_Guide_Tip[2] 	= ShuangDan_Guide_Activity3_Tips
	g_ShuangDan_Guide_Tip[3] 	= ShuangDan_Guide_Activity4_Tips
	g_ShuangDan_Guide_Tip[4] 	= ShuangDan_Guide_Activity5_Tips 
	g_ShuangDan_Guide_Tip[5] 	= ShuangDan_Guide_FestivalGift1_Tips 
	g_ShuangDan_Guide_Tip[6] 	= ShuangDan_Guide_FestivalGift2_Tips 
	--g_ShuangDan_Guide_Tip[8] 	= ShuangDan_Guide_Activity6_Tips 
	
end

--=========
-- Event
--=========
function ShuangDan_Guide_OnEvent(event) 

	if(event == "UI_COMMAND" and tonumber(arg0) == 88882001) then
	
		if this:IsVisible() then
			ShuangDan_Guide_Close()
			return
		end
		
		AskServerTimeAgain() 
			
		ShuangDan_Guide_Open()
		
		this:Show()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ShuangDan_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ShuangDan_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		ShuangDan_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88882003) then --显示小红点

		for index=1,table.getn(g_ShuangDan_Tips_Guide_StateTemp)  do
			local DataState = Get_XParam_INT(index-1)
			local TipsState = math.mod(DataState, 10)
			local ButtonState = math.floor(DataState / 10)
				 
			g_ShuangDan_Tips_Guide_StateTemp[index] = TipsState
			g_ShuangDan_Button_Guide_StateTemp[index] = ButtonState
		end
		ShuangDan_Guide_ShowButtonTips()  
		
	end

end
 
--=========
-- 重置
--=========
function ShuangDan_Guide_On_ResetPos()

	ShuangDan_Guide_FrameNULL:SetProperty("UnifiedPosition", g_ShuangDan_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function ShuangDan_Guide_Close() 
	this:Hide()
end

--=========
-- 打开
--=========
function ShuangDan_Guide_Open() 

	for index = 1, table.getn(g_ShuangDan_Guide_Tip) do 
		g_ShuangDan_Guide_Tip[index]:Hide()
		g_ShuangDan_Guide_Button[index]:Hide()
	end

	for index = 1, table.getn(g_ShuangDan_Tips_Guide_StateTemp)  do
		local DataState = Get_XParam_INT(index-1)
		local TipsState = math.mod(DataState, 10)
		local ButtonState = math.floor(DataState / 10)
			 
		g_ShuangDan_Tips_Guide_StateTemp[index] = TipsState
		g_ShuangDan_Button_Guide_StateTemp[index] = ButtonState
	end

	local curDay = DataPool:GetServerDayTime()
	for index = 1, table.getn(g_ShuangDan_Guide_Event) do
		local isButtonShow = g_ShuangDan_Button_Guide_StateTemp[index]
		local isTipsShow = g_ShuangDan_Tips_Guide_StateTemp[index]
		local event = g_ShuangDan_Guide_Event[index]

		if isButtonShow == 1 then 
			g_ShuangDan_Guide_Button[index]:Show()
			if curDay < event.begtime then
				g_ShuangDan_Guide_Button[index]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_ShuangDan_Guide_Button[index]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_ShuangDan_Guide_Button[index]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_ShuangDan_Guide_Tip[index]:Show()
			end
			event.isShow = 1
		end
	end 
	
	--设置小红点
	ShuangDan_Guide_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function ShuangDan_Guide_ShowButtonTips()

	for index = 1, table.getn(g_ShuangDan_Guide_Event) do
		local isButtonShow = g_ShuangDan_Button_Guide_StateTemp[index]
		local isTipsShow = g_ShuangDan_Tips_Guide_StateTemp[index]
		
		if isButtonShow == 1 then
			g_ShuangDan_Guide_Button[index]:Show()
			if isTipsShow == 1 then
				g_ShuangDan_Guide_Tip[index]:Show()
			else
				g_ShuangDan_Guide_Tip[index]:Hide()
			end
		else
			g_ShuangDan_Guide_Button[index]:Hide()
		end
	end

	local IsShowMiniMapPoint = 0
	for index = 1, table.getn(g_ShuangDan_Tips_Guide_StateTemp) do
		if g_ShuangDan_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end
 
	Lua_ShowQuickEnterPointTip(27, IsShowMiniMapPoint)
end

--===============================================
-- 打开奖励界面
--===============================================
function ShuangDan_Guide_AllRewards_Click()
	PushEvent("UI_COMMAND", 88882002)
end

--===============================================
-- 打开各个功能界面
--===============================================
function ShuangDan_Guide_Activity_Click( clickId )
	local curDay = DataPool:GetServerDayTime()
	
	--if clickId == 1 then 
    -- 浮花拾晓
	--	Clear_XSCRIPT()
	--			Set_XSCRIPT_Function_Name("OnOpenUI")
	--			Set_XSCRIPT_ScriptID(888801)
	--			Set_XSCRIPT_ParamCount(0)
	--	Send_XSCRIPT()	
	--else
	if clickId == 2 then 
	-- 踏雪寻芳
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(888800)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
		
	elseif clickId == 3 then 
	-- 清欢百味
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(888812)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
		ShuangDan_Guide_Close() 
	elseif clickId == 4 then 
	-- 飞花解意 2023Q4 替换成 双旦抽奖
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnOpenUI")
				Set_XSCRIPT_ScriptID(800816)
				Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	
	elseif clickId == 5 then 
	-- 东君有信
		if curDay < g_ShuangDan_Guide_Event[4].begtime or curDay > g_ShuangDan_Guide_Event[4].endtime then
            PushDebugMessage("#{YDHD_171206_07}")
            return
        end

        if Player:GetLevel() < g_ShuangDan_Guide_Event[4].level then
            PushDebugMessage("#{YDHD_171206_08}")
            return
        end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenNewYearisDay")
			Set_XSCRIPT_ScriptID(892637)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif clickId == 6 then 
	-- 圣诞节礼包
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenGetLibaoUI")
			Set_XSCRIPT_ScriptID(888307)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif clickId == 7 then 
	-- 元旦礼包
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenGiftUI")
			Set_XSCRIPT_ScriptID(888803)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	--elseif clickId == 8 then 
	-- 寒芳满衣
	--	Clear_XSCRIPT()
	--			Set_XSCRIPT_Function_Name("OnOpenUI")
	--			Set_XSCRIPT_ScriptID(888836)
	--			Set_XSCRIPT_ParamCount(0)
	--	Send_XSCRIPT()		
	end 

end
