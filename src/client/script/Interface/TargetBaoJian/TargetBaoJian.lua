
local		g_ElementsCtrl = {}
local		g_JadeAnimateCtrl = {}
local		g_JadeIconCtrl = {}
local		g_ElementsNameTextCtrl = {}
local		g_ElementsValueTextCtrl = {}
local		g_ElementsJadeExtendCtrl = {}
local		g_ElementsEquipExtendCtrl = {}

local 	g_JadeAnimate = { "BaoJianUI3_Jin" ,"BaoJianUI3_Shui" ,"BaoJianUI3_Mu" ,"BaoJianUI3_Huo" ,"BaoJianUI3_Tu"  }
local 	g_ElementsName =  {"#{ZZZB_150811_118}"  ,"#{ZZZB_150811_120}","#{ZZZB_150811_119}" ,"#{ZZZB_150811_121}" ,"#{ZZZB_150811_122}" }

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

local		g_ElementsCtrl_Parent = {}

local		g_RightThreeImage = {

	[ 1 ] = "set:BaoJianUI1 image:DiLongzhu_Disabled",		--灭
	[ 2 ] = "set:BaoJianUI1 image:DiLongzhu_Hover",			--亮
}

local		g_LeftThreeImage = {

	[ 1 ] = "set:BaoJianUI1 image:TianLongzhu_Disabled",	--灭
	[ 2 ] = "set:BaoJianUI1 image:TianLongzhu_Hover",		--亮
}

local 	g_TargetBaoJian_Frame_UnifiedXPosition
local		g_TargetBaoJian_Frame_UnifiedYPosition	

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetBaoJian_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = ""},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = ""},
	[6] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = ""},
	[7] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = ""},
	[8] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = ""},
	[9] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = ""},
	[10] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = ""},
	[11] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = ""},
	[12] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = ""},
	[13] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = ""},
	[14] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = ""},
	[15] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = ""},
}

local g_TargetPageButton = {}
local g_TargetPageCount = 0
local g_TargetPageOrder = {}

function TargetBaoJian_PreLoad()

	this:RegisterEvent("TARGET_FIVE_ELEMENTS_OPEN")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OTHER_FIVEELEMENTS_UPDATE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)


end

function TargetBaoJian_OnLoad()

	g_ElementsCtrl[ 1 ] = TargetBaoJian_Frame_Bk1_Icon1
	g_ElementsCtrl[ 2 ] = TargetBaoJian_Frame_Bk2_Icon1
	g_ElementsCtrl[ 3 ] = TargetBaoJian_Frame_Bk3_Icon1
	g_ElementsCtrl[ 4 ] = TargetBaoJian_Frame_Bk4_Icon1
	g_ElementsCtrl[ 5 ] = TargetBaoJian_Frame_Bk5_Icon1
	
	g_JadeAnimateCtrl[ 1 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk1_Animate1,
		[ 2 ] = TargetBaoJian_Frame_Bk1_Animate2,
		[ 3 ] = TargetBaoJian_Frame_Bk1_Animate3,
		[ 4 ] = TargetBaoJian_Frame_Bk1_Animate4,
		[ 5 ] = TargetBaoJian_Frame_Bk1_Animate5
	}
	
	g_JadeAnimateCtrl[ 2 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk2_Animate1,
		[ 2 ] = TargetBaoJian_Frame_Bk2_Animate2,
		[ 3 ] = TargetBaoJian_Frame_Bk2_Animate3,
		[ 4 ] = TargetBaoJian_Frame_Bk2_Animate4,
		[ 5 ] = TargetBaoJian_Frame_Bk2_Animate5
	}
	
	g_JadeAnimateCtrl[ 3 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk3_Animate1,
		[ 2 ] = TargetBaoJian_Frame_Bk3_Animate2,
		[ 3 ] = TargetBaoJian_Frame_Bk3_Animate3,
		[ 4 ] = TargetBaoJian_Frame_Bk3_Animate4,
		[ 5 ] = TargetBaoJian_Frame_Bk3_Animate5
	}
	
	g_JadeAnimateCtrl[ 4 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk4_Animate1,
		[ 2 ] = TargetBaoJian_Frame_Bk4_Animate2,
		[ 3 ] = TargetBaoJian_Frame_Bk4_Animate3,
		[ 4 ] = TargetBaoJian_Frame_Bk4_Animate4,
		[ 5 ] = TargetBaoJian_Frame_Bk4_Animate5
	}
	
	g_JadeAnimateCtrl[ 5 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk5_Animate1,
		[ 2 ] = TargetBaoJian_Frame_Bk5_Animate2,
		[ 3 ] = TargetBaoJian_Frame_Bk5_Animate3,
		[ 4 ] = TargetBaoJian_Frame_Bk5_Animate4,
		[ 5 ] = TargetBaoJian_Frame_Bk5_Animate5
	}
	
	g_JadeIconCtrl[ 1 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk1_Btn1,
		[ 2 ] = TargetBaoJian_Frame_Bk1_Btn2,
		[ 3 ] = TargetBaoJian_Frame_Bk1_Btn3,
		[ 4 ] = TargetBaoJian_Frame_Bk1_Btn4,
		[ 5 ] = TargetBaoJian_Frame_Bk1_Btn5
	}
	
	g_JadeIconCtrl[ 2 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk2_Btn1,
		[ 2 ] = TargetBaoJian_Frame_Bk2_Btn2,
		[ 3 ] = TargetBaoJian_Frame_Bk2_Btn3,
		[ 4 ] = TargetBaoJian_Frame_Bk2_Btn4,
		[ 5 ] = TargetBaoJian_Frame_Bk2_Btn5
	}
	
	g_JadeIconCtrl[ 3 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk3_Btn1,
		[ 2 ] = TargetBaoJian_Frame_Bk3_Btn2,
		[ 3 ] = TargetBaoJian_Frame_Bk3_Btn3,
		[ 4 ] = TargetBaoJian_Frame_Bk3_Btn4,
		[ 5 ] = TargetBaoJian_Frame_Bk3_Btn5
	}
	
	g_JadeIconCtrl[ 4 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk4_Btn1,
		[ 2 ] = TargetBaoJian_Frame_Bk4_Btn2,
		[ 3 ] = TargetBaoJian_Frame_Bk4_Btn3,
		[ 4 ] = TargetBaoJian_Frame_Bk4_Btn4,
		[ 5 ] = TargetBaoJian_Frame_Bk4_Btn5
	}
	
	g_JadeIconCtrl[ 5 ] = {
	
		[ 1 ] = TargetBaoJian_Frame_Bk5_Btn1,
		[ 2 ] = TargetBaoJian_Frame_Bk5_Btn2,
		[ 3 ] = TargetBaoJian_Frame_Bk5_Btn3,
		[ 4 ] = TargetBaoJian_Frame_Bk5_Btn4,
		[ 5 ] = TargetBaoJian_Frame_Bk5_Btn5
	}
	
	g_ElementsNameTextCtrl[ 1 ] = TargetBaoJian_Frame_Btn_text1_1
	g_ElementsNameTextCtrl[ 2 ] = TargetBaoJian_Frame_Btn2_text1_1
	g_ElementsNameTextCtrl[ 3 ] = TargetBaoJian_Frame_Btn3_text1_1
	g_ElementsNameTextCtrl[ 4 ] = TargetBaoJian_Frame_Btn4_text1_1
	g_ElementsNameTextCtrl[ 5 ] = TargetBaoJian_Frame_Btn5_text1_1
	
	g_ElementsValueTextCtrl[ 1 ] = TargetBaoJian_Frame_Btn_text1_2
	g_ElementsValueTextCtrl[ 2 ] = TargetBaoJian_Frame_Btn2_text1_2
	g_ElementsValueTextCtrl[ 3 ] = TargetBaoJian_Frame_Btn3_text1_2
	g_ElementsValueTextCtrl[ 4 ] = TargetBaoJian_Frame_Btn4_text1_2
	g_ElementsValueTextCtrl[ 5 ] = TargetBaoJian_Frame_Btn5_text1_2
	
	g_ElementsJadeExtendCtrl[ 1 ] = TargetBaoJian_Frame_Btn_text1_3
	g_ElementsJadeExtendCtrl[ 2 ] = TargetBaoJian_Frame_Btn2_text1_3
	g_ElementsJadeExtendCtrl[ 3 ] = TargetBaoJian_Frame_Btn3_text1_3
	g_ElementsJadeExtendCtrl[ 4 ] = TargetBaoJian_Frame_Btn4_text1_3
	g_ElementsJadeExtendCtrl[ 5 ] = TargetBaoJian_Frame_Btn5_text1_3
	
	g_ElementsEquipExtendCtrl[ 1 ] = TargetBaoJian_Frame_Btn_text1_4
	g_ElementsEquipExtendCtrl[ 2 ] = TargetBaoJian_Frame_Btn2_text1_4
	g_ElementsEquipExtendCtrl[ 3 ] = TargetBaoJian_Frame_Btn3_text1_4
	g_ElementsEquipExtendCtrl[ 4 ] = TargetBaoJian_Frame_Btn4_text1_4
	g_ElementsEquipExtendCtrl[ 5 ] = TargetBaoJian_Frame_Btn5_text1_4
	
	g_ElementsCtrl_Parent[ 1 ] = TargetBaoJian_Frame_Bk1
	g_ElementsCtrl_Parent[ 2 ] = TargetBaoJian_Frame_Bk2
	g_ElementsCtrl_Parent[ 3 ] = TargetBaoJian_Frame_Bk3
	g_ElementsCtrl_Parent[ 4 ] = TargetBaoJian_Frame_Bk4
	g_ElementsCtrl_Parent[ 5 ] = TargetBaoJian_Frame_Bk5
	
	g_TargetBaoJian_Frame_UnifiedXPosition = TargetBaoJian_Frame:GetProperty("UnifiedXPosition")
	g_TargetBaoJian_Frame_UnifiedYPosition = TargetBaoJian_Frame:GetProperty("UnifiedYPosition")
	
	g_TargetPageButton[1] = TargetBaoJian_SelfEquip
	g_TargetPageButton[2] = TargetBaoJian_SelfData
	g_TargetPageButton[3] = TargetBaoJian_Pet
	g_TargetPageButton[4] = TargetBaoJian_Infant
	g_TargetPageButton[5] = TargetBaoJian_Wuhun
	g_TargetPageButton[6] = TargetBaoJian_Miji
	g_TargetPageButton[7] = TargetBaoJian_ZhenYuan
	g_TargetPageButton[8] = TargetBaoJian_JingMai
	g_TargetPageButton[9] = TargetBaoJian_ShenDing
	g_TargetPageButton[10] = TargetBaoJian_JunXian
	g_TargetPageButton[11] = TargetBaoJian_BaoJian
	g_TargetPageButton[12] = TargetBaoJian_WuYi
	g_TargetPageButton[13] = TargetBaoJian_ShenQi
	g_TargetPageButton[14] = TargetBaoJian_Armor
	g_TargetPageButton[15] = TargetBaoJian_CangPin
	
end

function TargetBaoJian_OnEvent(event)

	if event == "TARGET_FIVE_ELEMENTS_OPEN" then
		
		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~= "number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		this:CareObject(obj_id , 1)
		
		this:Show()
		TargetBaoJian_Update()
		TargetBaoJian_ShowPage()
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "OTHER_FIVEELEMENTS_UPDATE" and this:IsVisible() then
		TargetBaoJian_Update()
		return
	end

	if event == "ADJEST_UI_POS" and this:IsVisible() then
		TargetBaoJian_Frame_On_ResetPos()
		return
	end
	
	if event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible() then
		TargetBaoJian_Frame_On_ResetPos()
		return
	end

end

-- 刷新
function TargetBaoJian_Update()
	
	local otherUnionPos = Variable:GetVariable("OtherUnionPos")
	if(otherUnionPos ~= nil) then
		TargetBaoJian_Frame:SetProperty("UnifiedPosition", otherUnionPos)
	end
	
	TargetBaoJian_BaoJian:SetCheck(1)
	
	for i = 1 , 5 do
	
		local bElementsActive	= Player:IsOtherFiveElements_ElementsActive( i - 1 )
		local bElementsLevel	= Player:GetOtherFiveElements_ElementsLevel( i - 1 )
		local bElementsType		= Player:GetOtherFiveElements_ElementsType( i - 1 )
		
		if bElementsLevel > 0 then
			g_ElementsCtrl[ i ]:SetProperty("Image" , g_ElementsImage[ i ])
			local szStr = ScriptGlobal_Format( "#{ZZZB_150811_139}", g_ElementsName[ i ], tostring(bElementsLevel) )
			g_ElementsNameTextCtrl[ i ]:SetText(szStr)
			
			if i == 3 or i == 5 then
				
				local nElementsValue = DataPool:Lua_GetOtherFiveElementsValueWithEquipAndJade( i - 1 )
				
				local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_141}", g_ElementsValueName[ i ][ 1 ] , nElementsValue )
				g_ElementsValueTextCtrl[ i ]:SetText(nValueText)
				
				if bElementsActive == 1 then
					local nAllExtendValue = 0
					for j = 0 , 4 do
						
						local bJadeType = Player:GetOtherFiveElements_JadeType( i - 1  , j )
						local nExtendValue = Player:GetOtherFiveElements_JadeExtend( i - 1 ,  bJadeType)
						if nExtendValue then
							nAllExtendValue = nAllExtendValue + nExtendValue
						end
					end
					
					if nAllExtendValue >= 0 then
						nAllExtendValue = "#c00FFFF+"..tostring(nAllExtendValue).."%"
					else
						nAllExtendValue = "#c00FFFF"..tostring(nAllExtendValue).."%"
					end
					
					g_ElementsJadeExtendCtrl[ i ]:SetText(tostring(nAllExtendValue))
				else
					g_ElementsJadeExtendCtrl[ i ]:SetText("#c00FFFF+0%")
				end
				g_ElementsJadeExtendCtrl[ i ]:SetToolTip("#{ZZZB_150811_142}")
				
				local nEquipExtend_1 = DataPool:Lua_GetOtherEquipZhiZunExtend(1)
				local nEquipExtend_2 = DataPool:Lua_GetOtherEquipZhiZunExtend(2)
				g_ElementsEquipExtendCtrl[ i ]:SetText("#c00ccff+"..tostring(nEquipExtend_1 + nEquipExtend_2).."%" )
				g_ElementsEquipExtendCtrl[ i ]:SetToolTip("#{ZZZB_150811_143}")	
				
			end
			
			if i == 1 or i == 2 or i == 4 then
				if g_ElementsValueName[ i ][ bElementsType ] ~= nil then
					
					local nElementsValue = DataPool:Lua_GetOtherFiveElementsValueWithEquipAndJade( i - 1 )
					
					local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_141}", g_ElementsValueName[ i ][ bElementsType ] , nElementsValue )
					g_ElementsValueTextCtrl[ i ]:SetText(nValueText)
					
					if bElementsActive == 1 then
						local nAllExtendValue = 0
						for j = 0 , 4 do
							
							local bJadeType = Player:GetOtherFiveElements_JadeType( i - 1  , j )
							local nExtendValue = Player:GetOtherFiveElements_JadeExtend( i - 1 ,  bJadeType)
							if nExtendValue then
								nAllExtendValue = nAllExtendValue + nExtendValue
							end
						end
						
						if nAllExtendValue >= 0 then
							nAllExtendValue = "#c00FFFF+"..tostring(nAllExtendValue)
						else
							nAllExtendValue = "#c00FFFF"..tostring(nAllExtendValue)
						end
						
						g_ElementsJadeExtendCtrl[ i ]:SetText(tostring(nAllExtendValue).."%")
					else
						g_ElementsJadeExtendCtrl[ i ]:SetText("#c00FFFF+0%")
					end
					g_ElementsJadeExtendCtrl[ i ]:SetToolTip("#{ZZZB_150811_142}")
					
					local nEquipExtend_1 = DataPool:Lua_GetOtherEquipZhiZunExtend(1)
					local nEquipExtend_2 = DataPool:Lua_GetOtherEquipZhiZunExtend(2)
					g_ElementsEquipExtendCtrl[ i ]:SetText("#c00ccff+"..tostring(nEquipExtend_1 + nEquipExtend_2).."%" )
					g_ElementsEquipExtendCtrl[ i ]:SetToolTip("#{ZZZB_150811_143}")	
					
				end
			end
		
		else
			g_ElementsCtrl[ i ]:SetProperty("Image" , g_ElementsImageNone[ i ])
			g_ElementsNameTextCtrl[ i ]:SetText(g_ElementsName[ i ])
			g_ElementsValueTextCtrl[ i ]:SetText("#{ZZZB_150811_140}")
			g_ElementsJadeExtendCtrl[ i ]:SetText("")
			g_ElementsEquipExtendCtrl[ i ]:SetText("")
		end
		
		if bElementsActive == 1 then
			
			for j = 1 , 5 do
				
				local bJadeType = Player:GetOtherFiveElements_JadeType( i - 1  , j - 1 )
				g_JadeIconCtrl[ i ][ j ]:Hide()
	
				if g_JadeAnimate[ bJadeType + 1 ] ~= nil then
					g_JadeAnimateCtrl[ i ][ j ]:Show()
					g_JadeAnimateCtrl[ i ][ j ]:SetProperty("Animate" , g_JadeAnimate[ bJadeType + 1 ])
				end
			end
		else
			for j = 1 , 5 do
				
				g_JadeIconCtrl[ i ][ j ]:Show()
				g_JadeAnimateCtrl[ i ][ j ]:Hide()
			end	
		end
	end
	
	TargetBaoJian_UpdateEquipExtend()
	
end


function TargetBaoJian_UpdateEquipExtend()
	
	local nExtendLevel_1 = DataPool:Lua_GetOtherEquipZhiZunExtendLevel( 1 )
	local nExtendLevel_2 = DataPool:Lua_GetOtherEquipZhiZunExtendLevel( 2 )
	
	--荣耀1
	if nExtendLevel_1 == 1 then
		
		TargetBaoJian_Frame_Bk9_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk9_Icon1:SetToolTip("#{ZZZB_150811_145}" )
		
		TargetBaoJian_Frame_Bk10_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk10_Icon1:SetToolTip("#{ZZZB_150811_146}")
		
		TargetBaoJian_Frame_Bk11_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk11_Icon1:SetToolTip("#{ZZZB_150811_148}")
		
	elseif nExtendLevel_1 == 2 then
		
		TargetBaoJian_Frame_Bk9_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk9_Icon1:SetToolTip("#{ZZZB_150811_147}")
		
		TargetBaoJian_Frame_Bk10_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk10_Icon1:SetToolTip("#{ZZZB_150811_147}")
		
		TargetBaoJian_Frame_Bk11_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk11_Icon1:SetToolTip("#{ZZZB_150811_148}")
	
	elseif nExtendLevel_1 == 3 then
		
		TargetBaoJian_Frame_Bk9_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk9_Icon1:SetToolTip("#{ZZZB_150811_149}")
		
		TargetBaoJian_Frame_Bk10_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk10_Icon1:SetToolTip("#{ZZZB_150811_149}")
		
		TargetBaoJian_Frame_Bk11_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk11_Icon1:SetToolTip("#{ZZZB_150811_149}")
	
	else
		
		TargetBaoJian_Frame_Bk9_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk9_Icon1:SetToolTip("#{ZZZB_150811_144}")
		
		TargetBaoJian_Frame_Bk10_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk10_Icon1:SetToolTip("#{ZZZB_150811_146}")
		
		TargetBaoJian_Frame_Bk11_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk11_Icon1:SetToolTip("#{ZZZB_150811_148}")
		
	end

	if nExtendLevel_2 == 1 then
		
		TargetBaoJian_Frame_Bk8_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk8_Icon1:SetToolTip("#{ZZZB_150811_151}")
		
		TargetBaoJian_Frame_Bk7_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk7_Icon1:SetToolTip("#{ZZZB_150811_152}")
		
		TargetBaoJian_Frame_Bk6_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk6_Icon1:SetToolTip("#{ZZZB_150811_154}")
	
	elseif nExtendLevel_2 == 2 then
		
		TargetBaoJian_Frame_Bk8_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk8_Icon1:SetToolTip("#{ZZZB_150811_153}")
		
		TargetBaoJian_Frame_Bk7_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk7_Icon1:SetToolTip("#{ZZZB_150811_153}")
		
		TargetBaoJian_Frame_Bk6_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk6_Icon1:SetToolTip("#{ZZZB_150811_154}")
	
	elseif nExtendLevel_2 == 3 then
		
		TargetBaoJian_Frame_Bk8_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk8_Icon1:SetToolTip("#{ZZZB_150811_155}")
		
		TargetBaoJian_Frame_Bk7_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk7_Icon1:SetToolTip("#{ZZZB_150811_155}")
		
		TargetBaoJian_Frame_Bk6_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		TargetBaoJian_Frame_Bk6_Icon1:SetToolTip("#{ZZZB_150811_155}")
		
	else
	
		TargetBaoJian_Frame_Bk8_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk8_Icon1:SetToolTip("#{ZZZB_150811_150}")
		
		TargetBaoJian_Frame_Bk7_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk7_Icon1:SetToolTip("#{ZZZB_150811_152}")
		
		TargetBaoJian_Frame_Bk6_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		TargetBaoJian_Frame_Bk6_Icon1:SetToolTip("#{ZZZB_150811_154}")
		
	end

end

function TargetBaoJian_UpdateText()

end

function TargetBaoJian_OnClose()
	
	this:Hide()
	
end

function TargetBaoJian_Elements_MouseLeave(nIndex)
	
	Lua_CloseFiveElementsTip(1 , nIndex)	
end

function TargetBaoJian_Elements_MouseEnter(nIndex)
	
	if SystemSetup:IsClassic() == 1 then
		local SetX= g_ElementsCtrl[nIndex]:GetProperty("AbsoluteXPosition")
			+ g_ElementsCtrl_Parent[nIndex]:GetProperty("AbsoluteXPosition") + TargetBaoJian_Frame_Part:GetProperty("AbsoluteXPosition")
			+ TargetBaoJian_Client:GetProperty("AbsoluteXPosition") + TargetBaoJian_Frame_Client:GetProperty("AbsoluteXPosition")
			+ TargetBaoJian_Frame:GetProperty("AbsoluteXPosition")
			
		local SetY = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteYPosition")
			+ g_ElementsCtrl_Parent[nIndex]:GetProperty("AbsoluteYPosition") + TargetBaoJian_Frame_Part:GetProperty("AbsoluteYPosition") 
			+ TargetBaoJian_Client:GetProperty("AbsoluteYPosition") + TargetBaoJian_Frame_Client:GetProperty("AbsoluteYPosition")
			+ TargetBaoJian_Frame:GetProperty("AbsoluteYPosition")
			
		local SetWidth = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteWidth")
		local SetHeight = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteHeight")
		Lua_OpenFiveElementsTip(1 , nIndex , SetX ,SetY ,tonumber(SetWidth) ,tonumber(SetHeight))
	else
		local SetX= g_ElementsCtrl[nIndex]:GetProperty("AbsoluteXPosition")
			+ g_ElementsCtrl_Parent[nIndex]:GetProperty("AbsoluteXPosition") + TargetBaoJian_Frame_Part:GetProperty("AbsoluteXPosition")
			+ TargetBaoJian_Client:GetProperty("AbsoluteXPosition") + TargetBaoJian_Frame_Client:GetProperty("AbsoluteXPosition")
			+ TargetBaoJian_Frame:GetProperty("AbsoluteXPosition")
			
		local SetY = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteYPosition")
			+ g_ElementsCtrl_Parent[nIndex]:GetProperty("AbsoluteYPosition") + TargetBaoJian_Frame_Part:GetProperty("AbsoluteYPosition")
			+ TargetBaoJian_Client:GetProperty("AbsoluteYPosition") + TargetBaoJian_Frame_Client:GetProperty("AbsoluteYPosition")
			+ TargetBaoJian_Frame:GetProperty("AbsoluteYPosition")
			
		local SetWidth = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteWidth")
		local SetHeight = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteHeight")
		Lua_OpenFiveElementsTip(1 , nIndex , SetX ,SetY ,tonumber(SetWidth) ,tonumber(SetHeight))
	end

	
end

--装备
function TargetBaoJian_SelfEquip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenEquipFrame("other")
end

--资料
function TargetBaoJian_SelfData_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPrivatePage("other")
end

--珍兽
function TargetBaoJian_Pet_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPetFrame("other")
end

--子女
function TargetBaoJian_Infant_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Infant:Other_ToggleInfantPage()
	if bRet ~= 1 then
		TargetBaoJian_Infant:SetCheck(0)
	end
end

--武魂
function TargetBaoJian_Wuhun_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherWuhun()
end

--秘籍
function TargetBaoJian_Miji_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherMiji()
	this:Hide()
end

--真元
function TargetBaoJian_ZhenYuan_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Pneuma:ToggleTargetZhenYuanPage()
	if bRet ~= 1 then
		TargetBaoJian_ZhenYuan:SetCheck(0)
	end
end

--经脉
function TargetBaoJian_JingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherJingMai()
end

--神鼎
function  TargetBaoJian_ShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local nLevel = CachedTarget:GetData("LEVEL",1)
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" )
	else
		local bRet = SystemSetup:OpenOtherShenDing()
		if nRet ~= 1 then
			TargetBaoJian_ShenDing:SetCheck(0)
		end
	end
end

--侠印
function  TargetBaoJian_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	else
		TargetBaoJian_JunXian:SetCheck(0)
	end
end

--骑乘
function TargetBaoJian_Ride_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenRidePage("other")
end


function TargetBaoJian_Frame_On_ResetPos()
	
	TargetBaoJian_Frame:SetProperty("UnifiedXPosition", g_TargetBaoJian_Frame_UnifiedXPosition)
	TargetBaoJian_Frame:SetProperty("UnifiedYPosition", g_TargetBaoJian_Frame_UnifiedYPosition)
	
end

function TargetBaoJian_WuYi_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetBaoJian_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetBaoJian_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetBaoJian_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function TargetBaoJian_ShowPage()

	for i = 1, table.getn(g_TargetBaoJian_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetBaoJian_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetBaoJian_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetBaoJian_Page) do
		if TargetBaoJian_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetBaoJian_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetBaoJian_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetBaoJian_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		TargetBaoJian_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		TargetBaoJian_Pet_Page_Switch()
	elseif idx == 4 then--子女
		TargetBaoJian_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		TargetBaoJian_Wuhun_Page_Switch()
	elseif idx == 6 then--秘籍
		TargetBaoJian_Miji_Page_Switch()
	elseif idx == 7 then--真元
		TargetBaoJian_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		TargetBaoJian_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		TargetBaoJian_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		TargetBaoJian_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		--TargetBaoJian_BaoJian_Page_Switch()
	elseif idx == 12 then--武意
		TargetBaoJian_WuYi_Page_Switch()
	elseif idx == 13 then--神器
		TargetBaoJian_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetBaoJian_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetBaoJian_CangPin_Page_Switch()
	end
end

function TargetBaoJian_CheckPage(idx)
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 7 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 8 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 9 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	end
	return 0
end

function TargetBaoJian_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end

