
local 	g_ObjServerID = -1
local	g_CurrentJadeIndex = -1
local g_EquipBaoJian_Wash_YuanBaoPay = {};
local 	g_lock = 0
local	g_NeedCloseConfirm = 0
local 	g_ElementsName =  {
			"#{ZZZB_150811_190}",
			"#{ZZZB_150811_192}",
			"#{ZZZB_150811_191}",			
			"#{ZZZB_150811_193}",
			"#{ZZZB_150811_194}",
	}
	
local 	g_JadeName =  {
			"#{ZZZB_150811_134}",
			"#{ZZZB_150811_136}",
			"#{ZZZB_150811_135}",
			"#{ZZZB_150811_137}",
			"#{ZZZB_150811_138}",
	}

local 	g_JadeAnimate = { "BaoJianUI3_Jin" ,"BaoJianUI3_Shui" ,"BaoJianUI3_Mu" ,"BaoJianUI3_Huo" ,"BaoJianUI3_Tu"  }
local	g_JadeAnimateCtrl_1 = {}
local	g_JadeIconCtrl_1 = {}

local	g_JadeAnimateCtrl_2 = {}
local	g_JadeIconCtrl_2 = {}

local	g_JadeAnimateCtrl_3 = {}
local	g_JadeIconCtrl_3 = {}

local	g_JadeAnimateCtrl_4 = {}
local	g_JadeIconCtrl_4 = {}

local 	g_BeforJadeText = {}
local 	g_AfterJadeText = {}

local		g_ElementsImageNone = {

		"set:BaoJianUI1 image:BaoYuJin_Disabled",
		"set:BaoJianUI5 image:BaoYuShui_Disabled",
		"set:BaoJianUI5 image:BaoYuMu_Disabled",
		"set:BaoJianUI5 image:BaoYuHuo_Disabled",
		"set:BaoJianUI5 image:BaoYuTu_Disabled",

}

local 	g_ElementsImage = {
		"set:BaoJianUI1 image:BaoYuJin_Normal",
		"set:BaoJianUI5 image:BaoYuShui_Normal",
		"set:BaoJianUI1 image:BaoYuMu_Normal",
		"set:BaoJianUI5 image:BaoYuHuo_Normal",
		"set:BaoJianUI5 image:BaoYuTu_Normal",
}

local	g_IntroText = { 
			"#{ZZZB_150811_275}",
			"#{ZZZB_150811_276}",
			"#{ZZZB_150811_277}",
			"#{ZZZB_150811_278}",
			"#{ZZZB_150811_279}",
		}

local	g_ExtendBefore = 0
local	g_ExtendAfter = 0

local	g_Auto_Start = 0

local 	g_EquipBaoJian_Wash_Frame_UnifiedXPosition
local	g_EquipBaoJian_Wash_Frame_UnifiedYPosition	


--=========
--PreLoad==
--=========
function EquipBaoJian_Wash_PreLoad()

	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("FIVE_ELEMENTS_WASH_OPEN")
	this:RegisterEvent("FIVE_ELEMENTS_WASH_TEMP")
	this:RegisterEvent("FIVE_ELEMENTS_WASH_OVER")
	this:RegisterEvent("FIVE_ELEMENTS_WASH_CLOSE")
	this:RegisterEvent("FIVE_ELEMENTS_SWITCHTYPE")
	this:RegisterEvent("FIVE_ELEMENTS_AUTOWASH_START")
	this:RegisterEvent("FIVE_ELEMENTS_AUTOWASH_STOP")
end
--=========
--OnLoad
--=========
function EquipBaoJian_Wash_OnLoad()

	g_JadeAnimateCtrl_1 = {
	
		[ 1 ] = EquipBaoJian_Wash_Frame_Bk1_Animate1,
		[ 2 ] = EquipBaoJian_Wash_Frame_Bk1_Animate2,
		[ 3 ] = EquipBaoJian_Wash_Frame_Bk1_Animate3,
		[ 4 ] = EquipBaoJian_Wash_Frame_Bk1_Animate4,
		[ 5 ] = EquipBaoJian_Wash_Frame_Bk1_Animate5,
	}
	
	g_JadeIconCtrl_1 = {
	
		[ 1 ] = EquipBaoJian_Wash_Frame_Bk1_Btn1,
		[ 2 ] = EquipBaoJian_Wash_Frame_Bk1_Btn2,
		[ 3 ] = EquipBaoJian_Wash_Frame_Bk1_Btn3,
		[ 4 ] = EquipBaoJian_Wash_Frame_Bk1_Btn4,
		[ 5 ] = EquipBaoJian_Wash_Frame_Bk1_Btn5,
	}
	
	g_JadeAnimateCtrl_2 = {
	
		[ 1 ] = EquipBaoJian_Wash_Frame_Bk1_Animate1_1,
		[ 2 ] = EquipBaoJian_Wash_Frame_Bk1_Animate2_1,
		[ 3 ] = EquipBaoJian_Wash_Frame_Bk1_Animate3_1,
		[ 4 ] = EquipBaoJian_Wash_Frame_Bk1_Animate4_1,
		[ 5 ] = EquipBaoJian_Wash_Frame_Bk1_Animate5_1,
	}
	
	g_JadeIconCtrl_2 = {
	
		[ 1 ] = EquipBaoJian_Wash_Frame_Bk1_Btn1_1,
		[ 2 ] = EquipBaoJian_Wash_Frame_Bk1_Btn2_1,
		[ 3 ] = EquipBaoJian_Wash_Frame_Bk1_Btn3_1,
		[ 4 ] = EquipBaoJian_Wash_Frame_Bk1_Btn4_1,
		[ 5 ] = EquipBaoJian_Wash_Frame_Bk1_Btn5_1,
	}
	
	g_JadeAnimateCtrl_3 = {
	
		[ 1 ] = EquipBaoJian_Wash_Frame_Bk2_Animate1,
		[ 2 ] = EquipBaoJian_Wash_Frame_Bk2_Animate2,
		[ 3 ] = EquipBaoJian_Wash_Frame_Bk2_Animate3,
		[ 4 ] = EquipBaoJian_Wash_Frame_Bk2_Animate4,
		[ 5 ] = EquipBaoJian_Wash_Frame_Bk2_Animate5,
	}
	
	g_JadeIconCtrl_3 = {
	
		[ 1 ] = EquipBaoJian_Wash_Frame_Bk2_Btn1,
		[ 2 ] = EquipBaoJian_Wash_Frame_Bk2_Btn2,
		[ 3 ] = EquipBaoJian_Wash_Frame_Bk2_Btn3,
		[ 4 ] = EquipBaoJian_Wash_Frame_Bk2_Btn4,
		[ 5 ] = EquipBaoJian_Wash_Frame_Bk2_Btn5,
	}
	
	g_JadeAnimateCtrl_4 = {
	
		[ 1 ] = EquipBaoJian_Wash_Frame_Bk2_Animate1_1,
		[ 2 ] = EquipBaoJian_Wash_Frame_Bk2_Animate2_1,
		[ 3 ] = EquipBaoJian_Wash_Frame_Bk2_Animate3_1,
		[ 4 ] = EquipBaoJian_Wash_Frame_Bk2_Animate4_1,
		[ 5 ] = EquipBaoJian_Wash_Frame_Bk2_Animate5_1,
	}
	
	g_JadeIconCtrl_4 = {
	
		[ 1 ] = EquipBaoJian_Wash_Frame_Bk2_Btn1_1,
		[ 2 ] = EquipBaoJian_Wash_Frame_Bk2_Btn2_1,
		[ 3 ] = EquipBaoJian_Wash_Frame_Bk2_Btn3_1,
		[ 4 ] = EquipBaoJian_Wash_Frame_Bk2_Btn4_1,
		[ 5 ] = EquipBaoJian_Wash_Frame_Bk2_Btn5_1,
	}
	
	g_BeforJadeText[ 1 ] = EquipBaoJian_Wash_Frame_Bk1_Text1_2
	g_BeforJadeText[ 2 ] = EquipBaoJian_Wash_Frame_Bk1_Text1_3
	g_BeforJadeText[ 3 ] = EquipBaoJian_Wash_Frame_Bk1_Text1_4
	g_BeforJadeText[ 4 ] = EquipBaoJian_Wash_Frame_Bk1_Text1_5
	g_BeforJadeText[ 5 ] = EquipBaoJian_Wash_Frame_Bk1_Text1_6
	
	g_AfterJadeText[ 1 ] = EquipBaoJian_Wash_Frame_Bk2_Text1_2
	g_AfterJadeText[ 2 ] = EquipBaoJian_Wash_Frame_Bk2_Text1_3
	g_AfterJadeText[ 3 ] = EquipBaoJian_Wash_Frame_Bk2_Text1_4
	g_AfterJadeText[ 4 ] = EquipBaoJian_Wash_Frame_Bk2_Text1_5
	g_AfterJadeText[ 5 ] = EquipBaoJian_Wash_Frame_Bk2_Text1_6
	
	
	g_EquipBaoJian_Wash_Frame_UnifiedXPosition = EquipBaoJian_Wash_Frame:GetProperty("UnifiedXPosition")
	g_EquipBaoJian_Wash_Frame_UnifiedYPosition = EquipBaoJian_Wash_Frame:GetProperty("UnifiedYPosition")
	
	g_EquipBaoJian_Wash_YuanBaoPay = {
		[1] = 1,
		[2] = 1,
		[3] = 1,
		[4] = 1,
		[5] = 1,
	}
	
end
--=========
--OnEvent
--=========
function EquipBaoJian_Wash_OnEvent(event)

	if event == "FIVE_ELEMENTS_WASH_OPEN" then
	
		if g_CurrentJadeIndex >= 0 and g_CurrentJadeIndex <= 4 then
			g_EquipBaoJian_Wash_YuanBaoPay[g_CurrentJadeIndex+1] = EquipBaoJian_Wash_YuanBaoPay:GetCheck();	
		end
		
		local nObjServerID = tonumber( arg0 )
		local nObjCaredID = DataPool : GetNPCIDByServerID( nObjServerID )
		if nObjCaredID and nObjCaredID >= 0 then
			g_ObjServerID = nObjServerID
			g_CurrentJadeIndex = tonumber( arg1 ) - 1
			EquipBaoJian_Wash_Init()
			if g_EquipBaoJian_Wash_YuanBaoPay[g_CurrentJadeIndex+1] == 1 or g_EquipBaoJian_Wash_YuanBaoPay[g_CurrentJadeIndex+1] == 0 then
				EquipBaoJian_Wash_YuanBaoPay:SetCheck(g_EquipBaoJian_Wash_YuanBaoPay[g_CurrentJadeIndex+1])
			end
			this:Show()
			EquipBaoJian_Wash_Update()
			this:CareObject( nObjCaredID, 1)
		end
		return
	end
	
	if event == "FIVE_ELEMENTS_WASH_CLOSE" and this:IsVisible()  then
		EquipBaoJian_Wash_CleanUp()
		this:Hide()
		return
	end
	
	if event == "FIVE_ELEMENTS_WASH_TEMP" and this:IsVisible() then
		
		EquipBaoJian_Wash_ShowTempResult(tonumber( arg0 ),tonumber( arg1 ),tonumber( arg2 ),tonumber( arg3 ),tonumber( arg4 ))
		g_NeedCloseConfirm = 1
		return
	end

	if event == "FIVE_ELEMENTS_SWITCHTYPE" and this:IsVisible() then
		this:Hide()
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "FIVEELEMENTS_UPDATE"  and this:IsVisible() then
		EquipBaoJian_Wash_Update()	
		return
	end
	
	if event == "FIVE_ELEMENTS_WASH_OVER"  and this:IsVisible() then
		EquipBaoJian_Wash_Update()
		g_NeedCloseConfirm = 0
		g_ExtendAfter = 0	
		return
	end
	
	if event == "FIVE_ELEMENTS_AUTOWASH_START" and this:IsVisible() then
		EquipBaoJian_Wash_AutoBegin()	
		return
	end
	
	if event == "FIVE_ELEMENTS_AUTOWASH_STOP" and this:IsVisible() then
		EquipBaoJian_Wash_AutoEnd()	
		return
	end
	

	if event == "ADJEST_UI_POS" and this:IsVisible() then
		EquipBaoJian_Wash_Frame_On_ResetPos()
		return
	end
	
	if event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible() then
		EquipBaoJian_Wash_Frame_On_ResetPos()
		return
	end
	
	if event == "MONEY_CHANGE_EX" and this:IsVisible()  then
		EquipBaoJian_Wash_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		EquipBaoJian_Wash_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end
end
--=========
--Update UI
--=========
function EquipBaoJian_Wash_Update()
	
	if g_CurrentJadeIndex < 0 or g_CurrentJadeIndex > 4 then
		return
	end

	g_lock = 0
	local strTitle = ScriptGlobal_Format( "#{ZZZB_150811_210}", g_ElementsName[ g_CurrentJadeIndex + 1 ])
	EquipBaoJian_Wash_DragTitle:SetText(strTitle)
	
	EquipBaoJian_Wash_Frame_Info:SetText(g_IntroText[ g_CurrentJadeIndex + 1])
	
	local bElementsActive = Player:IsFiveElements_ElementsActive( g_CurrentJadeIndex )
	local bElementsLevel = Player:GetFiveElements_ElementsLevel( g_CurrentJadeIndex )
	local bElementsType	= Player:GetFiveElements_ElementsType( g_CurrentJadeIndex )
	
	if bElementsLevel > 0 then
		EquipBaoJian_Wash_Frame_Bk1_Icon1:SetProperty("Image" , g_ElementsImage[ g_CurrentJadeIndex + 1 ])
		EquipBaoJian_Wash_Frame_Bk2_Icon1:SetProperty("Image" , g_ElementsImage[ g_CurrentJadeIndex + 1 ])
	else
		EquipBaoJian_Wash_Frame_Bk1_Icon1:SetProperty("Image" , g_ElementsImageNone[ g_CurrentJadeIndex + 1 ])
		EquipBaoJian_Wash_Frame_Bk2_Icon1:SetProperty("Image" , g_ElementsImageNone[ g_CurrentJadeIndex + 1 ])
	end
	
	local nAllJadeExtend = 0
	if bElementsActive == 1 then

		for i = 1 , 5 do
				
			local bJadeType = Player:GetFiveElements_JadeType( g_CurrentJadeIndex  , i  - 1)
			
			g_JadeIconCtrl_1[ i ]:Hide()
			g_JadeIconCtrl_2[ i ]:Hide()
			
			if bJadeType >= 0 and bJadeType < 5 then
				g_JadeAnimateCtrl_1[ i ]:Show()
				g_JadeAnimateCtrl_1[ i ]:SetProperty("Animate" , g_JadeAnimate[ bJadeType + 1 ])
				
				g_JadeAnimateCtrl_2[ i ]:Show()
				g_JadeAnimateCtrl_2[ i ]:SetProperty("Animate" , g_JadeAnimate[ bJadeType + 1 ])
				
				local nExtendValue = Player:GetFiveElements_JadeExtend( g_CurrentJadeIndex ,  bJadeType)
				if nExtendValue >= 0 then
					nExtendValue = "+"..tostring(nExtendValue)
				end
				local jadeStr = ScriptGlobal_Format( g_JadeName[ bJadeType + 1 ], tostring(nExtendValue))
				g_BeforJadeText[ i ]:SetText(jadeStr)
				
				nAllJadeExtend = nAllJadeExtend + nExtendValue
			end
	
		end
		
	else

		for i = 1 , 5 do
			
			g_JadeIconCtrl_1[ i ]:Show()
			g_JadeAnimateCtrl_1[ i ]:Hide()
			
			g_JadeIconCtrl_2[ i ]:Show()
			g_JadeAnimateCtrl_2[ i ]:Hide()
			
			g_BeforJadeText[ i ]:SetText("#{ZZZB_150811_216}")
			
		end
	
	end
	
	g_ExtendBefore = nAllJadeExtend
	
	if nAllJadeExtend >= 0 then
		nAllJadeExtend = "+"..tostring(nAllJadeExtend)
	end
	local strAllExtend = ScriptGlobal_Format( "#{ZZZB_150811_214}", nAllJadeExtend)
	EquipBaoJian_Wash_Frame_Bk1_Text1_1:SetText(strAllExtend)
	
	for i = 1 , 5 do
			
		g_JadeIconCtrl_3[ i ]:Hide()
		g_JadeAnimateCtrl_3[ i ]:Hide()
		
		g_JadeIconCtrl_4[ i ]:Hide()
		g_JadeAnimateCtrl_4[ i ]:Hide()
		
		g_AfterJadeText[ i ]:SetText("")
		
		EquipBaoJian_Wash_Frame_Bk2_text1_1:SetText("")
		
	end
	
	EquipBaoJian_Wash_DemandMoney:SetProperty("MoneyNumber", "10000")
	
	EquipBaoJian_Button:Hide()
	
	if g_Auto_Start == 1 then
		EquipBaoJian_Wash_OnOK()	
	end
	
end

function EquipBaoJian_Wash_ShowTempResult(jade_type_1,jade_type_2,jade_type_3,jade_type_4,jade_type_5)
	
	if jade_type_1 == nil or jade_type_2 == nil or jade_type_3 == nil or jade_type_4 == nil or jade_type_5 == nil then
		PushDebugMessage(tostring(jade_type_3))
		return
	end
		
	local nType = {jade_type_1 , jade_type_2,jade_type_3,jade_type_4,jade_type_5}
	
	local nAllJadeExtend = 0
	for i = 1 , 5 do
	
		g_JadeIconCtrl_3[ i ]:Hide()
		g_JadeIconCtrl_4[ i ]:Hide()
		
		if nType[ i ] >= 0 and nType[ i ]  < 5 then

			g_JadeAnimateCtrl_3[ i ]:Show()
			g_JadeAnimateCtrl_3[ i ]:SetProperty("Animate" , g_JadeAnimate[ nType[ i ]  + 1 ])
			
			g_JadeAnimateCtrl_4[ i ]:Show()
			g_JadeAnimateCtrl_4[ i ]:SetProperty("Animate" , g_JadeAnimate[ nType[ i ]  + 1 ])
			
			local nExtendValue = Player:GetFiveElements_JadeExtend( g_CurrentJadeIndex ,  nType[ i ] )
			if nExtendValue >= 0 then
				nExtendValue = "+"..tostring(nExtendValue)
			end
			local jadeStr = ScriptGlobal_Format( g_JadeName[ nType[ i ]  + 1 ], tostring(nExtendValue))
			g_AfterJadeText[ i ]:SetText(jadeStr)
			
			nAllJadeExtend = nAllJadeExtend + nExtendValue
		end

	end
	
	g_ExtendAfter = nAllJadeExtend
	
	if nAllJadeExtend >= 0 then
		nAllJadeExtend = "+"..tostring(nAllJadeExtend)
	end
	local strAllExtend = ScriptGlobal_Format( "#{ZZZB_150811_217}", nAllJadeExtend)
	EquipBaoJian_Wash_Frame_Bk2_text1_1:SetText(strAllExtend)
	
	EquipBaoJian_Button:Show()
	
	if g_Auto_Start == 1 then	
		if g_ExtendAfter > g_ExtendBefore then
			EquipBaoJian_Wash_OnSwitch()
		else
			EquipBaoJian_Wash_OnOK()
		end
	else
		if g_ExtendAfter > g_ExtendBefore then
			Lua_FiveElementsNotSwitchConfirm(tonumber(g_CurrentJadeIndex))
		end
	end
	
end

--关闭 / 打开 UI ,清空界面
function EquipBaoJian_Wash_CleanUp()
	
	EquipBaoJian_Wash_DemandMoney:SetProperty("MoneyNumber", "0")
	g_Auto_Start = 0
	EquipBaoJian_Wash_Quick_Up:SetText("#{ZZZB_151105_04}")
	
end

--UI恢复到第一次打开时的状态
function EquipBaoJian_Wash_Init()
	
	EquipBaoJian_Wash_CleanUp()
	
	EquipBaoJian_Wash_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	EquipBaoJian_Wash_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
end

--点击Cancel
function EquipBaoJian_Wash_OnCancelClicked()
	
	if g_Auto_Start == 1 then
		EquipBaoJian_Wash_AutoEnd()
		return
	end
	
	if g_NeedCloseConfirm == 1 then
		Lua_CloseFiveElementsWashConfirm()
		return
	end
	EquipBaoJian_Wash_CleanUp()
	this:Hide()

end

--点击"X"
function EquipBaoJian_Wash_OnCloseClicked(  )
	
	if g_Auto_Start == 1 then
		EquipBaoJian_Wash_AutoEnd()
		return
	end
	
	if g_NeedCloseConfirm == 1 then
		Lua_CloseFiveElementsWashConfirm()
		return
	end
	EquipBaoJian_Wash_CleanUp()
	this:Hide()
	
end

--OnHide
function EquipBaoJian_Wash_OnHiden()

	g_EquipBaoJian_Wash_YuanBaoPay[g_CurrentJadeIndex+1] = EquipBaoJian_Wash_YuanBaoPay:GetCheck();	
	g_ObjServerID = -1
	g_CurrentJadeIndex = -1
	EquipBaoJian_Wash_CleanUp()
	g_NeedCloseConfirm = 0
	g_ExtendBefore = 0
	g_ExtendAfter = 0
	g_Auto_Start = 0
	EquipBaoJian_Wash_Quick_Up:SetText("#{ZZZB_151105_04}")
	
end

--点击OK
function EquipBaoJian_Wash_OnOK()

	--判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZZB_150811_184}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
		return
	end
	
	if g_ExtendBefore >= 100 then
		PushDebugMessage("#{ZZZB_151105_02}")
		EquipBaoJian_Wash_AutoEnd()
		return
	end
	
	if g_lock == 1 then
		PushDebugMessage("#{MSSD_180529_30}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FiveElementsJadeWash" )
		Set_XSCRIPT_ScriptID( 880039 )
		Set_XSCRIPT_Parameter( 0, g_CurrentJadeIndex ) 
		if g_Auto_Start == 1 then
			Set_XSCRIPT_Parameter( 1, 2 ) 
		else
			Set_XSCRIPT_Parameter( 1, tonumber(EquipBaoJian_Wash_YuanBaoPay:GetCheck()) ) 
		end
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
	
	--加个0.5s定时器
	if g_Auto_Start ~= 1 then
		SetTimer("EquipBaoJian_Wash","EquipBaoJian_Wash_TimerProc()", 200)
		g_lock = 1
	end
end


function EquipBaoJian_Wash_TimerProc()
	KillTimer("EquipBaoJian_Wash_TimerProc()")
	g_lock = 0
end

function EquipBaoJian_Wash_OnSwitch()
	
	--判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZZB_150811_184}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
		return
	end
	
	if g_ExtendAfter >= g_ExtendBefore then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FiveElementsJadeSwitch" )
			Set_XSCRIPT_ScriptID( 880039 )
			Set_XSCRIPT_Parameter( 0, g_CurrentJadeIndex ) 
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	else
		--Lua_FiveElementsWashSwitchConfirm(tonumber(g_CurrentJadeIndex))
		PushDebugMessage("#{ZZZB_160616_12}")
	end

end

function EquipBaoJian_Wash_OnAuto()
	
	if g_Auto_Start == 1 then
		EquipBaoJian_Wash_AutoEnd()
		return
	end
	
	--判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZZB_150811_184}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
		return
	end
	
	if g_ExtendBefore >= 100 then
		PushDebugMessage("#{ZZZB_151105_02}")
		return
	end
	
	Lua_FiveElementsAutoWashConfirm()	
	
end

function EquipBaoJian_Wash_AutoBegin()

	g_Auto_Start = 1	
	EquipBaoJian_Wash_Quick_Up:SetText("#{ZZZB_151105_05}")
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FiveElementsJadeWash" )
		Set_XSCRIPT_ScriptID( 880039 )
		Set_XSCRIPT_Parameter( 0, g_CurrentJadeIndex ) 
		Set_XSCRIPT_Parameter( 1, 2 ) 		--表示自动，没有元宝购买的行为
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()

end

function EquipBaoJian_Wash_AutoEnd()

	g_Auto_Start = 0
	EquipBaoJian_Wash_Quick_Up:SetText("#{ZZZB_151105_04}")

end


function EquipBaoJian_Wash_Frame_On_ResetPos()
	
	EquipBaoJian_Wash_Frame:SetProperty("UnifiedXPosition", g_EquipBaoJian_Wash_Frame_UnifiedXPosition)
	EquipBaoJian_Wash_Frame:SetProperty("UnifiedYPosition", g_EquipBaoJian_Wash_Frame_UnifiedYPosition)
	
end

