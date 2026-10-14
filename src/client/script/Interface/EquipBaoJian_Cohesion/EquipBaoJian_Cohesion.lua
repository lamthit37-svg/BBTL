
local 	g_ObjServerID = -1
local		g_ElementsCtrl = {}
local		g_ElementsNameTextCtrl = {}
local		g_ElementsValueTextCtrl = {}
local		g_ElementsNextValueTextCtrl = {}

local 	g_ElementsName =  {"#{ZZZB_150811_118}"  ,"#{ZZZB_150811_120}","#{ZZZB_150811_119}" ,"#{ZZZB_150811_121}" ,"#{ZZZB_150811_122}" }

local		g_ElementsImageNow = {

		"set:BaoJianUI1 image:BaoYuJin_Hover",
		"set:BaoJianUI5 image:BaoYuShui_Hover",
		"set:BaoJianUI1 image:BaoYuMu_Hover",
		"set:BaoJianUI5 image:BaoYuHuo_Hover",
		"set:BaoJianUI5 image:BaoYuTu_Hover",

}

local		g_ElementsImageNowGray = {

		"set:BaoJianUI3 image:BaoJianUI3_JinDisable",
		"set:BaoJianUI3 image:BaoJianUI3_ShuiDisable",
		"set:BaoJianUI3 image:BaoJianUI3_MuDisable",
		"set:BaoJianUI3 image:BaoJianUI3_HuoDisable",
		"set:BaoJianUI3 image:BaoJianUI3_TuDisable",

}

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

local 	g_ElementsValueName = {
	
	[ 1 ] = { 
		"#{ZZZB_150811_166}",
		"#{ZZZB_150811_167}",
		"#{ZZZB_150811_168}",
		"#{ZZZB_150811_169}",
	},
	
	[ 2 ] = { 
		"#{ZZZB_150811_172}",
		"#{ZZZB_150811_173}",
		"#{ZZZB_150811_174}",
		"#{ZZZB_150811_175}",
		"#{ZZZB_150811_176}",
		"#{ZZZB_150811_177}",
		"#{ZZZB_150811_178}",
		"#{ZZZB_150811_179}",
	},
	
	[ 3 ] = { 
		"#{ZYYH_120824_19}",
	},
	
	[ 4 ] = { 
		"#{ZZZB_150811_182}",
		"#{ZZZB_150811_183}",
	},
	
	[ 5 ] = { 
		"#{ZYYH_120824_18}",
	},

}

local	g_CostMoney = {  20000 , 50000 , 80000 ,120000 ,160000 , 
		200000 , 250000 , 300000 , 400000 ,500000}
		
local	g_CostItemCount = {  2 , 5 , 8 ,12 ,16 , 20 , 25 , 30 , 40 ,50}

local 	g_EquipBaoJian_Cohesion_Frame_UnifiedXPosition
local	g_EquipBaoJian_Cohesion_Frame_UnifiedYPosition	

function EquipBaoJian_Cohesion_PreLoad()

	this:RegisterEvent("FIVE_ELEMENTS_COHESION_OPEN")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("FIVEELEMENTS_UPDATE", false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("FIVE_ELEMENTS_SWITCHTYPE")


end

function EquipBaoJian_Cohesion_OnLoad()

	g_ElementsCtrl[ 1 ] = EquipBaoJian_Cohesion_Frame_Bk1_Icon1
	g_ElementsCtrl[ 2 ] = EquipBaoJian_Cohesion_Frame_Bk2_Icon1
	g_ElementsCtrl[ 3 ] = EquipBaoJian_Cohesion_Frame_Bk3_Icon1
	g_ElementsCtrl[ 4 ] = EquipBaoJian_Cohesion_Frame_Bk4_Icon1
	g_ElementsCtrl[ 5 ] = EquipBaoJian_Cohesion_Frame_Bk5_Icon1
	
	g_ElementsNameTextCtrl[ 1 ] = EquipBaoJian_Cohesion_Frame_Bk1_text1_1
	g_ElementsNameTextCtrl[ 2 ] = EquipBaoJian_Cohesion_Frame_Bk2_text1_1
	g_ElementsNameTextCtrl[ 3 ] = EquipBaoJian_Cohesion_Frame_Bk3_text1_1
	g_ElementsNameTextCtrl[ 4 ] = EquipBaoJian_Cohesion_Frame_Bk4_text1_1
	g_ElementsNameTextCtrl[ 5 ] = EquipBaoJian_Cohesion_Frame_Bk5_text1_1
	
	g_ElementsValueTextCtrl[ 1 ] = EquipBaoJian_Cohesion_Frame_Bk1_text1_2
	g_ElementsValueTextCtrl[ 2 ] = EquipBaoJian_Cohesion_Frame_Bk2_text1_2
	g_ElementsValueTextCtrl[ 3 ] = EquipBaoJian_Cohesion_Frame_Bk3_text1_2
	g_ElementsValueTextCtrl[ 4 ] = EquipBaoJian_Cohesion_Frame_Bk4_text1_2
	g_ElementsValueTextCtrl[ 5 ] = EquipBaoJian_Cohesion_Frame_Bk5_text1_2
	
	g_ElementsNextValueTextCtrl[ 1 ] = EquipBaoJian_Cohesion_Frame_Bk1_text1_3
	g_ElementsNextValueTextCtrl[ 2 ] = EquipBaoJian_Cohesion_Frame_Bk2_text1_3
	g_ElementsNextValueTextCtrl[ 3 ] = EquipBaoJian_Cohesion_Frame_Bk3_text1_3
	g_ElementsNextValueTextCtrl[ 4 ] = EquipBaoJian_Cohesion_Frame_Bk4_text1_3
	g_ElementsNextValueTextCtrl[ 5 ] = EquipBaoJian_Cohesion_Frame_Bk5_text1_3
	
	g_EquipBaoJian_Cohesion_Frame_UnifiedXPosition = EquipBaoJian_Cohesion_Frame:GetProperty("UnifiedXPosition")
	g_EquipBaoJian_Cohesion_Frame_UnifiedYPosition = EquipBaoJian_Cohesion_Frame:GetProperty("UnifiedYPosition")
	
end

function EquipBaoJian_Cohesion_OnEvent(event)

	if event == "FIVE_ELEMENTS_COHESION_OPEN" then
		
		local nObjServerID = tonumber( arg0 )
		local nObjCaredID = DataPool : GetNPCIDByServerID( nObjServerID )
		if nObjCaredID and nObjCaredID >= 0 then
			g_ObjServerID = nObjServerID
			EquipBaoJian_Cohesion_Init()
			this:Show()
			EquipBaoJian_Cohesion_Update()
			this:CareObject( nObjCaredID, 1)
		end
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
		EquipBaoJian_Cohesion_Update()	
		return
	end

	if event == "ADJEST_UI_POS" and this:IsVisible() then
		EquipBaoJian_Cohesion_Frame_On_ResetPos()
		return
	end
	
	if event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible() then
		EquipBaoJian_Cohesion_Frame_On_ResetPos()
		return
	end
	
	if event == "MONEY_CHANGE_EX" and this:IsVisible()  then
		EquipBaoJian_Cohesion_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		EquipBaoJian_Cohesion_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end

end
--关闭 或 打开 UI时 ，清空一次
function EquipBaoJian_Cohesion_CleanUp()

	EquipBaoJian_Cohesion_Own:SetText( "" )
	EquipBaoJian_Cohesion_Cohesion:SetText("")
	EquipBaoJian_Cohesion_DemandMoney:SetProperty("MoneyNumber", "0")
	EquipBaoJian_Cohesion_OK:Disable()
	EquipBaoJian_Cohesion_DemandMoney:SetProperty("MoneyNumber", "0")
	
end

--UI恢复到第一次打开时的状态
function EquipBaoJian_Cohesion_Init()
	
	EquipBaoJian_Cohesion_CleanUp()
	
	EquipBaoJian_Cohesion_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	EquipBaoJian_Cohesion_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
end

--点击Cancel
function EquipBaoJian_Cohesion_OnCancelClicked(  )

	EquipBaoJian_Cohesion_CleanUp()
	this:Hide()

end

--点击"X"
function EquipBaoJian_Cohesion_OnCloseClicked(  )

	EquipBaoJian_Cohesion_CleanUp()
	this:Hide()
	
end

--OnHide
function EquipBaoJian_Cohesion_OnHiden()
	
	g_ObjServerID = -1
	EquipBaoJian_Cohesion_CleanUp()
	
end

--点击OK
function EquipBaoJian_Cohesion_OnOK()

	--判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZZB_150811_184}")
		return
	end
	
	--if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
	--	return
	--end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FiveElementsCohesion" )
		Set_XSCRIPT_ScriptID( 880039 )
		Set_XSCRIPT_Parameter( 0, g_ObjServerID ) 
		Set_XSCRIPT_Parameter( 1, 0 ) 
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
end

-- 刷新
function EquipBaoJian_Cohesion_Update()
	
	for i = 1 , 5 do
	
		local bElementsActive 	= Player:IsFiveElements_ElementsActive( i - 1 )
		local bElementsLevel	= Player:GetFiveElements_ElementsLevel( i - 1 )
		local bElementsType		= Player:GetFiveElements_ElementsType( i - 1 )

		if bElementsLevel > 0 then	--凝聚过
			g_ElementsCtrl[ i ]:SetProperty("Image" , g_ElementsImage[ i ])
			local szStr = ScriptGlobal_Format( "#{ZZZB_150811_139}", g_ElementsName[ i ], tostring(bElementsLevel) )
			g_ElementsNameTextCtrl[ i ]:SetText(szStr)
			
			if i == 3 or i == 5 then
				
				local nElementsValue = DataPool:Lua_GetFiveElementsBaseValue( i - 1 )
				local nElementsNextValue = DataPool:Lua_GetFiveElementsNextBaseValue( i - 1 )
				
				local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_282}", g_ElementsValueName[ i ][ 1 ] , nElementsValue )
				g_ElementsValueTextCtrl[ i ]:SetText(nValueText)
				
				if bElementsLevel >= 100 then
					g_ElementsNextValueTextCtrl[ i ]:SetText("#{ZZZB_150811_159}" )	
				else
					nValueText = ScriptGlobal_Format( "#{ZZZB_150811_280}", g_ElementsValueName[ i ][ 1 ] , nElementsNextValue )
					g_ElementsNextValueTextCtrl[ i ]:SetText(nValueText)
				end

			end
			
			if i == 1 or i == 2 or i == 4 then
				if g_ElementsValueName[ i ][ bElementsType ] ~= nil then
					
					local nElementsValue = DataPool:Lua_GetFiveElementsBaseValue( i - 1 )
					local nElementsNextValue = DataPool:Lua_GetFiveElementsNextBaseValue( i - 1 )
					
					local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_282}", g_ElementsValueName[ i ][ bElementsType ] , nElementsValue )
					g_ElementsValueTextCtrl[ i ]:SetText(nValueText)
					
					if bElementsLevel >= 100 then
						g_ElementsNextValueTextCtrl[ i ]:SetText("#{ZZZB_150811_159}" )	
					else
						nValueText = ScriptGlobal_Format( "#{ZZZB_150811_280}", g_ElementsValueName[ i ][ bElementsType ] , nElementsNextValue )
						g_ElementsNextValueTextCtrl[ i ]:SetText(nValueText)
					end

				end
			end
			
		else		--未凝聚过
			g_ElementsCtrl[ i ]:SetProperty("Image" , g_ElementsImageNone[ i ])
			g_ElementsNameTextCtrl[ i ]:SetText(g_ElementsName[ i ])
			g_ElementsValueTextCtrl[ i ]:SetText("#{ZZZB_150811_158}")
			g_ElementsNextValueTextCtrl[ i ]:SetText("" )
			
		end
	end
	
	local nIndex2Cohesion = Player:GetFiveElementsIndexCanDoCohesion()
	if nIndex2Cohesion >= 0 and nIndex2Cohesion < 5 then
		
		local bElementsLevel	= Player:GetFiveElements_ElementsLevel( nIndex2Cohesion )
		
		if bElementsLevel > 0 then
			g_ElementsCtrl[ nIndex2Cohesion + 1 ]:SetProperty("Image" , g_ElementsImageNow[ nIndex2Cohesion + 1 ])
		else
			g_ElementsCtrl[ nIndex2Cohesion + 1 ]:SetProperty("Image" , g_ElementsImageNowGray[ nIndex2Cohesion + 1 ])
		end
		
		EquipBaoJian_Cohesion_Own:SetText(g_ElementsName[ nIndex2Cohesion + 1 ] )
		
		local bElementsLevel	= Player:GetFiveElements_ElementsLevel( nIndex2Cohesion )
		local nLevelGrade = math.floor ( bElementsLevel / 10 )
		
		if nLevelGrade >= 0 and nLevelGrade <= 9 then
			local strTemp = ScriptGlobal_Format("#{ZZZB_150811_281}" ,  tostring( g_CostItemCount[  nLevelGrade + 1 ] ) )
			EquipBaoJian_Cohesion_Cohesion:SetText(strTemp)
			
			EquipBaoJian_Cohesion_DemandMoney:SetProperty("MoneyNumber", tostring( g_CostMoney[  nLevelGrade + 1 ] ))
		end

		EquipBaoJian_Cohesion_OK:Enable()
	else
	
		EquipBaoJian_Cohesion_Own:SetText( "" )
		EquipBaoJian_Cohesion_Cohesion:SetText("")
		EquipBaoJian_Cohesion_DemandMoney:SetProperty("MoneyNumber", "0")
		EquipBaoJian_Cohesion_OK:Disable()
		
	end
	
end

function EquipBaoJian_Cohesion_OpenSwitchType(nIndex)

	if nIndex == 0 then
		Lua_OpenFiveElementsTypeSwitch(g_ObjServerID , nIndex)
	elseif nIndex == 1 then
		Lua_OpenFiveElementsTypeSwitch(g_ObjServerID , nIndex)
	elseif nIndex == 3 then
		Lua_OpenFiveElementsTypeSwitch(g_ObjServerID , nIndex)
	end
	
end


function EquipBaoJian_Cohesion_OnClose()
	
	this:Hide()
	
end

function EquipBaoJian_Cohesion_Frame_On_ResetPos()
	
	EquipBaoJian_Cohesion_Frame:SetProperty("UnifiedXPosition", g_EquipBaoJian_Cohesion_Frame_UnifiedXPosition)
	EquipBaoJian_Cohesion_Frame:SetProperty("UnifiedYPosition", g_EquipBaoJian_Cohesion_Frame_UnifiedYPosition)
	
end
