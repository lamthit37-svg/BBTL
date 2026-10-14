--Frozen 整合界面
local g_Frozen_Guide_Frame_UnifiedPosition
 --如果功能有多个阶段，按钮有两个tips那么配置多个时间
local g_Frozen_Guide_Event = { 
	--礼包 11-0
	[0] = { begtime = 20251218, endtime = 20260114, StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_33}", btntips_doing = {"#{BXJZH_240927_33}",}, btntips_end = "#{BXJZH_240927_33}",
	}, 
	--冰雪大作战
	[1] = { begtime = 20251218, endtime = 20260114,	StageTime = {{20251218,20260114,},},
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_06}",}, btntips_end = "#{BXJZH_240927_10}",
	},
	--黑熊掰苞米
	[2] = { begtime = 20251218, endtime = 20260114,	StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_07}",}, btntips_end = "#{BXJZH_240927_10}",
	},
	--月下瑶台?闲适
	[3] = { begtime = 20251218, endtime = 20251231,	StageTime = {{20251218,20251231,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_08}",},	btntips_end = "#{BXJZH_240927_10}",
	},	
	--月下瑶台?盈裕 13-4
	[4] = { begtime = 20260101, endtime = 20260114, StageTime = {{20260101,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_17}",}, btntips_end = "#{BXJZH_240927_10}",
	}, 
	--冻冻脑瓜
	[5] = { begtime = 20251218, endtime = 20260114, StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{DXDT_240920_101}",},	btntips_end = "#{BXJZH_240927_10}",
	},
	--萌狐碰碰冰
	[6] = { begtime = 20251218, endtime = 20260114,	StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_28}",},	btntips_end = "#{BXJZH_240927_10}",
	},
	--猛兽战车
	[7] = { begtime = 20251218, endtime = 20260114,	StageTime = {{20251218,20260114,},},
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_29}",},	btntips_end = "#{BXJZH_240927_10}",
	},
	--奇想圣诞
	[8] = { begtime = 20251225, endtime = 20251225,	StageTime = {{20251225,20251225,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_30}",},	btntips_end = "#{BXJZH_240927_10}",
	}, 
	--雪人梦工厂
	[9] = { begtime = 20251218, endtime = 20260114,	StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_31}",},	btntips_end = "#{BXJZH_240927_10}",
	}, 
	--古韵华裳
	[10] = { begtime = 20250101, endtime = 20250101, StageTime = {{20250101,20250101,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_61}",}, btntips_end = "#{BXJZH_240927_10}",
	}, 
	--元旦聚宝 14-11
	[11] = { begtime = 20260101, endtime = 20260101, StageTime = {{20260101,20260101,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_61}",}, btntips_end = "#{BXJZH_240927_10}",
	}, 
	--整合领奖 点数奖励 15-12
	[12] = { begtime = 20251218, endtime = 20260114,	StageTime = {{20251218,20260114,},},
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJD_241118_2}",},	btntips_end = "#{BXJZH_240927_10}",
	},
	--雪狐寻宝 4-13
	[13] = { begtime = 20251218, endtime = 20260114,	StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_09}",},	btntips_end = "#{BXJZH_240927_10}",
	},
	--冰雪节战令 16-14
	[14] = { begtime = 20251218, endtime = 20260114,	StageTime = {{20251218,20260114,},},
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_09}",},	btntips_end = "#{BXJZH_240927_10}",
	},
	--假面舞会 10-15
	[15] = { begtime = 20251218, endtime = 20260114, StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_28}",},	btntips_end = "#{BXJZH_240927_10}",
	}, 
	-- 舞会抽奖 12-16
	[16] = { begtime = 20251218, endtime = 20260114, StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{WHCJ_251018_71}", btntips_doing = {"#{BXJZH_251103_01}",}, btntips_end = "#{WHCJ_251018_73}",
	}, 
	--  物华天竞
	[17] = { begtime = 20251218, endtime = 20260114, StageTime = {{20251218,20260114,},}, 
			btntips_unbeg = "#{BXJZH_240927_05}", btntips_doing = {"#{BXJZH_240927_59}",}, btntips_end = "#{BXJZH_240927_10}",
	}, 
}

local g_Frozen_Guide_Button_Guide_StateTemp = {}
local g_Frozen_Guide_Tips_Guide_StateTemp   = {}
local g_Frozen_Guide_image   				= { 
	[0] = 0, 
	[1] = 1, 
	[2] = 1, 
	[3] = 1, 
	[4] = 1, 
	[5] = 1, 
	[6] = 0, 
	[7] = 1, 
	[8] = 0, 
	[9] = 1, 
	[10]= 0, 
	[11]= 0, 
	[12]= 1, 
	[13]= 0, 
	[14]= 0, 
	[15]= 1,
	[16]= 0,
	[17]= 0,
}
local g_Frozen_Guide_Lock   				= {
	[0] = 0, 
	[1] = 1, 
	[2] = 1, 
	[3] = 1, 
	[4] = 1, 
	[5] = 1, 
	[6] = 0, 
	[7] = 1, 
	[8] = 0, 
	[9] = 1, 
	[10]= 0, 
	[11]= 0, 
	[12]= 0, 
	[13]= 0, 
	[14]= 0, 
	[15]= 1,
	[16]= 0,
	[17]= 0,
}
local g_Frozen_Guide_Button = {}
local g_Frozen_Guide_Tip = {}
local g_Frozen_Guide_ImageCtl = {}
local g_Frozen_Guide_LockCtl = {}

local g_Frozen_Guide_UICOM_Open       = 50100901
local g_Frozen_Guide_UICOM_Close      = 50100902
local g_Frozen_Guide_UICOM_RefreshRed = 50100903
local g_Frozen_Guide_QuickEnterId     = 67
  

function Frozen_Guide_PreLoad()
	--第二个参数代表界面隐藏时事件是否有效,默认为true
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) --进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS", false)

end

function Frozen_Guide_OnLoad()
	Frozen_Guide_LoadControl()
	g_Frozen_Guide_Frame_UnifiedPosition = Frozen_Guide_Frame:GetProperty("UnifiedPosition")
end

-- 装载控件
function Frozen_Guide_LoadControl()
	g_Frozen_Guide_Button[0]  = Frozen_Guide_Btn0
	g_Frozen_Guide_Button[1]  = Frozen_Guide_Btn1
	g_Frozen_Guide_Button[2]  = Frozen_Guide_Btn2
	g_Frozen_Guide_Button[3]  = Frozen_Guide_Btn3
	g_Frozen_Guide_Button[4]  = Frozen_Guide_Btn4 
	g_Frozen_Guide_Button[5]  = Frozen_Guide_Btn5
	g_Frozen_Guide_Button[6]  = Frozen_Guide_Btn6
	g_Frozen_Guide_Button[7]  = Frozen_Guide_Btn7
	g_Frozen_Guide_Button[8]  = Frozen_Guide_Btn8  
	g_Frozen_Guide_Button[9]  = Frozen_Guide_Btn9 
	g_Frozen_Guide_Button[10] = Frozen_Guide_Btn10 
	g_Frozen_Guide_Button[11] = Frozen_Guide_Btn11
	g_Frozen_Guide_Button[12] = Frozen_Guide_Btn12 
	g_Frozen_Guide_Button[13] = Frozen_Guide_Btn13 
	g_Frozen_Guide_Button[14] = Frozen_Guide_Btn14 
	g_Frozen_Guide_Button[15] = Frozen_Guide_Btn15 
	g_Frozen_Guide_Button[16] = Frozen_Guide_Btn16 
	g_Frozen_Guide_Button[17] = Frozen_Guide_Btn17 

	g_Frozen_Guide_Tip[0]  	  = Frozen_Guide_Btn0_Tips
	g_Frozen_Guide_Tip[1]  	  = Frozen_Guide_Btn1_Tips
	g_Frozen_Guide_Tip[2]  	  = Frozen_Guide_Btn2_Tips
	g_Frozen_Guide_Tip[3]  	  = Frozen_Guide_Btn3_Tips
	g_Frozen_Guide_Tip[4]  	  = Frozen_Guide_Btn4_Tips 
	g_Frozen_Guide_Tip[5]  	  = Frozen_Guide_Btn5_Tips
	g_Frozen_Guide_Tip[6]  	  = Frozen_Guide_Btn6_Tips
	g_Frozen_Guide_Tip[7]  	  = Frozen_Guide_Btn7_Tips
	g_Frozen_Guide_Tip[8]  	  = Frozen_Guide_Btn8_Tips  
	g_Frozen_Guide_Tip[9]  	  = Frozen_Guide_Btn9_Tips  
	g_Frozen_Guide_Tip[10] 	  = Frozen_Guide_Btn10_Tips 
	g_Frozen_Guide_Tip[11] 	  = Frozen_Guide_Btn11_Tips  
	g_Frozen_Guide_Tip[12] 	  = Frozen_Guide_Btn12_Tips  
	g_Frozen_Guide_Tip[13] 	  = Frozen_Guide_Btn13_Tips  
	g_Frozen_Guide_Tip[14] 	  = Frozen_Guide_Btn14_Tips  
	g_Frozen_Guide_Tip[15] 	  = Frozen_Guide_Btn15_Tips  
	g_Frozen_Guide_Tip[16] 	  = Frozen_Guide_Btn16_Tips  
	g_Frozen_Guide_Tip[17] 	  = Frozen_Guide_Btn17_Tips  

	g_Frozen_Guide_ImageCtl[1]  	  = Frozen_Guide_Btn1_Info
	g_Frozen_Guide_ImageCtl[2]  	  = Frozen_Guide_Btn2_Info 
	g_Frozen_Guide_ImageCtl[3]  	  = Frozen_Guide_Btn3_Info
	g_Frozen_Guide_ImageCtl[4]  	  = Frozen_Guide_Btn4_Info
	g_Frozen_Guide_ImageCtl[5]  	  = Frozen_Guide_Btn5_Info 
	g_Frozen_Guide_ImageCtl[7]  	  = Frozen_Guide_Btn7_Info
	g_Frozen_Guide_ImageCtl[9]  	  = Frozen_Guide_Btn9_Info 
	g_Frozen_Guide_ImageCtl[12]  	  = Frozen_Guide_Btn12_Info
	g_Frozen_Guide_ImageCtl[15]  	  = Frozen_Guide_Btn15_Info 
	
	g_Frozen_Guide_LockCtl[1]  = Frozen_Guide_Btn1_Locked
	g_Frozen_Guide_LockCtl[2]  = Frozen_Guide_Btn2_Locked
	g_Frozen_Guide_LockCtl[3]  = Frozen_Guide_Btn3_Locked
	g_Frozen_Guide_LockCtl[4]  = Frozen_Guide_Btn4_Locked
	g_Frozen_Guide_LockCtl[5]  = Frozen_Guide_Btn5_Locked
	g_Frozen_Guide_LockCtl[7]  = Frozen_Guide_Btn7_Locked
	g_Frozen_Guide_LockCtl[9]  = Frozen_Guide_Btn9_Locked
	g_Frozen_Guide_LockCtl[15]  = Frozen_Guide_Btn15_Locked

end

-- Event
function Frozen_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_Frozen_Guide_UICOM_Open then
		if this:IsVisible() then
			Frozen_Guide_Close()
			return
		end 
		AskServerTimeAgain()
		Frozen_Guide_Update()
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_Frozen_Guide_UICOM_Close then
		Frozen_Guide_Close()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_Frozen_Guide_UICOM_RefreshRed then
		if this:IsVisible() then 
			Frozen_Guide_Update()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_Guide_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_Guide_Close()
	elseif event == "ADJEST_UI_POS" then
		Frozen_Guide_On_ResetPos()
	end

end

-- 重置界面位置
function Frozen_Guide_On_ResetPos()
	Frozen_Guide_Frame:SetProperty("UnifiedPosition", g_Frozen_Guide_Frame_UnifiedPosition)
end

function Frozen_Guide_OnHidden()
	Frozen_Guide_Close()
end

-- 关闭
function Frozen_Guide_Close() 
	this:Hide()
end

-- 刷新界面
function Frozen_Guide_Update()
	for index = 0, table.getn(g_Frozen_Guide_Button) do
		g_Frozen_Guide_Tip[index]:Hide()
		g_Frozen_Guide_Button[index]:Hide()
		if g_Frozen_Guide_image[index] == 1 then
			g_Frozen_Guide_ImageCtl[index]:Hide()
		end
		if g_Frozen_Guide_Lock[index] == 1 then
			g_Frozen_Guide_LockCtl[index]:Hide()
		end
	end

	local nBtnInfo  = Get_XParam_INT(0)
	local nTipsInfo = Get_XParam_INT(1)

	for index = 0, table.getn(g_Frozen_Guide_Event) do
		local _,ButtonState = GetBitValueInUINT(nBtnInfo, index, 1)  
		local _,TipsState = GetBitValueInUINT(nTipsInfo, index, 1)  
		g_Frozen_Guide_Button_Guide_StateTemp[index] = ButtonState
		g_Frozen_Guide_Tips_Guide_StateTemp[index] = TipsState
	end

	local curDay = DataPool:GetServerDayTime()
	for index = 0, table.getn(g_Frozen_Guide_Event) do
		local isButtonShow = g_Frozen_Guide_Button_Guide_StateTemp[index]
		local isTipsShow = g_Frozen_Guide_Tips_Guide_StateTemp[index]
		local event = g_Frozen_Guide_Event[index]

		if isButtonShow == 1 then
			if g_Frozen_Guide_image[index] == 1 then
				g_Frozen_Guide_ImageCtl[index]:Show()
			end
			--跟阶段这个属性无所谓了 按钮的显隐完全交给GetButtonState传回的值
			g_Frozen_Guide_Button[index]:Show()
			if curDay < event.begtime then
				g_Frozen_Guide_Button[index]:SetToolTip(event.btntips_unbeg) 
			elseif curDay > event.endtime then
				g_Frozen_Guide_Button[index]:SetToolTip(event.btntips_end)
			end
			for i = 1, table.getn(event.StageTime) do
				if curDay >= event.StageTime[i][1] and curDay <= event.StageTime[i][2] and event.btntips_doing[i] ~= nil then
					g_Frozen_Guide_Button[index]:SetToolTip(event.btntips_doing[i])
				end
			end
			if isTipsShow == 1 then
				g_Frozen_Guide_Tip[index]:Show()
			else
				g_Frozen_Guide_Tip[index]:Hide()
			end 
		elseif curDay >= event.begtime and curDay <= event.endtime and g_Frozen_Guide_Lock[index] == 1 then
			g_Frozen_Guide_LockCtl[index]:Show()			
		end
	end

	local IsShowMiniMapPoint = 0
	for index = 0, table.getn(g_Frozen_Guide_Event) do
		if g_Frozen_Guide_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end

	Lua_ShowQuickEnterPointTip(g_Frozen_Guide_QuickEnterId, IsShowMiniMapPoint)
  
end

-- 打开各个功能界面
function Frozen_Guide_Clicked(clickId)
	local curDay = DataPool:GetServerDayTime() 
	if clickId == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowClientUI")
			Set_XSCRIPT_ScriptID(501010)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenGotoUI")
			Set_XSCRIPT_ScriptID(800302)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 2 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenActivityUI")
			Set_XSCRIPT_ScriptID(999463)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenWindowRequest")
			Set_XSCRIPT_ScriptID(999512)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 4 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenWindowRequest")
			Set_XSCRIPT_ScriptID(999513)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	 	 	
	elseif clickId == 5 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenUI")
			Set_XSCRIPT_ScriptID(999482)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif clickId == 6 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(820041)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	 		
	elseif clickId == 7 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskOpenMainUI")
			Set_XSCRIPT_ScriptID(999496)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif clickId == 8 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(510014)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	 
	elseif clickId == 9 then 
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenGotoUI")
		Set_XSCRIPT_ScriptID(999473)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	  
	elseif clickId == 10 then  
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(820094)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	 	  
	elseif clickId == 11 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(510014)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif clickId == 12 then -- 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowClientUI")
			Set_XSCRIPT_ScriptID(501012)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif clickId == 13 then -- 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenSnowUI")
			Set_XSCRIPT_ScriptID(999501)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif clickId == 14 then 	
		if(IsWindowShow("XiariZhanling")) then
			CloseWindow("XiariZhanling", true)
			return
		end
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AskOpenMainUI" )
			Set_XSCRIPT_ScriptID( 791150 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 15 then 		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(820094)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	 
	elseif clickId == 16 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenGotoUI")
			Set_XSCRIPT_ScriptID(999780)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

	elseif clickId == 17 then   
	end
end
