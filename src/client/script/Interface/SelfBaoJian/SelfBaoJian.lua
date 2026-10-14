
local		g_ElementsCtrl = {}
local		g_JadeAnimateCtrl = {}
local		g_JadeIconCtrl = {}
local		g_ElementsNameTextCtrl = {}
local		g_ElementsValueTextCtrl = {}
local		g_ElementsJadeExtendCtrl = {}
local		g_ElementsEquipExtendCtrl = {}

local 	g_JadeAnimate = { "BaoJianUI3_Jin" ,"BaoJianUI3_Shui" ,"BaoJianUI3_Mu" ,"BaoJianUI3_Huo" ,"BaoJianUI3_Tu"  }
local 	g_ElementsName =  {"#{ZZZB_150811_118}"  ,"#{ZZZB_150811_120}" ,"#{ZZZB_150811_119}","#{ZZZB_150811_121}" ,"#{ZZZB_150811_122}" }

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

local	g_RightThreeImage = {

	[ 1 ] = "set:BaoJianUI1 image:DiLongzhu_Disabled",		--灭
	[ 2 ] = "set:BaoJianUI1 image:DiLongzhu_Hover",			--亮
}

local	g_LeftThreeImage = {

	[ 1 ] = "set:BaoJianUI1 image:TianLongzhu_Disabled",	--灭
	[ 2 ] = "set:BaoJianUI1 image:TianLongzhu_Hover",		--亮
}

local	g_ElementsCtrl_Parent = {}

local 	g_SelfBaoJian_Frame_UnifiedXPosition
local	g_SelfBaoJian_Frame_UnifiedYPosition


--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SelfBaoJian_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = "#{RWYQ_150707_01}"},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = "#{RWYQ_150707_02}"},
	[6] = {Text = "#{XL_XML_35}",				NeedCheck = 0, Tip = "#{RWYQ_150707_03}"},
	[7] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = "#{RWYQ_150707_04}"},
	[8] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = "#{RWYQ_150707_05}"},
	[9] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_06}"},
	[10] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = "#{RWYQ_150707_07}"},
	[11] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_08}"},
	[12] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = "#{ZZZB_150811_114}"},
	[13] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = "#{WYXT_20170907_302}"},
	[14] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = "#{JXSQ_170829_217}"},
	[15] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = "#{NJBZ_220816_12}"},
	[16] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = "#{CPSJ_260112_2}"},
	[17] = {Text = "#{INTERFACE_XML_496}",		NeedCheck = 0, Tip = ""},
}

local g_SelfBaoJian_PageButton = {}
local g_SelfBaoJian_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function SelfBaoJian_PreLoad()

	this:RegisterEvent("SELF_FIVE_ELEMENTS_OPEN")
	this:RegisterEvent("FIVEELEMENTS_UPDATE")

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 更新装备
	this:RegisterEvent("REFRESH_EQUIP")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function SelfBaoJian_OnLoad()

	g_ElementsCtrl[ 1 ] = SelfBaoJian_Frame_Bk1_Icon1
	g_ElementsCtrl[ 2 ] = SelfBaoJian_Frame_Bk2_Icon1
	g_ElementsCtrl[ 3 ] = SelfBaoJian_Frame_Bk3_Icon1
	g_ElementsCtrl[ 4 ] = SelfBaoJian_Frame_Bk4_Icon1
	g_ElementsCtrl[ 5 ] = SelfBaoJian_Frame_Bk5_Icon1

	g_JadeAnimateCtrl[ 1 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk1_Animate1,
		[ 2 ] = SelfBaoJian_Frame_Bk1_Animate2,
		[ 3 ] = SelfBaoJian_Frame_Bk1_Animate3,
		[ 4 ] = SelfBaoJian_Frame_Bk1_Animate4,
		[ 5 ] = SelfBaoJian_Frame_Bk1_Animate5
	}

	g_JadeAnimateCtrl[ 2 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk2_Animate1,
		[ 2 ] = SelfBaoJian_Frame_Bk2_Animate2,
		[ 3 ] = SelfBaoJian_Frame_Bk2_Animate3,
		[ 4 ] = SelfBaoJian_Frame_Bk2_Animate4,
		[ 5 ] = SelfBaoJian_Frame_Bk2_Animate5
	}

	g_JadeAnimateCtrl[ 3 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk3_Animate1,
		[ 2 ] = SelfBaoJian_Frame_Bk3_Animate2,
		[ 3 ] = SelfBaoJian_Frame_Bk3_Animate3,
		[ 4 ] = SelfBaoJian_Frame_Bk3_Animate4,
		[ 5 ] = SelfBaoJian_Frame_Bk3_Animate5
	}

	g_JadeAnimateCtrl[ 4 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk4_Animate1,
		[ 2 ] = SelfBaoJian_Frame_Bk4_Animate2,
		[ 3 ] = SelfBaoJian_Frame_Bk4_Animate3,
		[ 4 ] = SelfBaoJian_Frame_Bk4_Animate4,
		[ 5 ] = SelfBaoJian_Frame_Bk4_Animate5
	}

	g_JadeAnimateCtrl[ 5 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk5_Animate1,
		[ 2 ] = SelfBaoJian_Frame_Bk5_Animate2,
		[ 3 ] = SelfBaoJian_Frame_Bk5_Animate3,
		[ 4 ] = SelfBaoJian_Frame_Bk5_Animate4,
		[ 5 ] = SelfBaoJian_Frame_Bk5_Animate5
	}

	g_JadeIconCtrl[ 1 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk1_Btn1,
		[ 2 ] = SelfBaoJian_Frame_Bk1_Btn2,
		[ 3 ] = SelfBaoJian_Frame_Bk1_Btn3,
		[ 4 ] = SelfBaoJian_Frame_Bk1_Btn4,
		[ 5 ] = SelfBaoJian_Frame_Bk1_Btn5
	}

	g_JadeIconCtrl[ 2 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk2_Btn1,
		[ 2 ] = SelfBaoJian_Frame_Bk2_Btn2,
		[ 3 ] = SelfBaoJian_Frame_Bk2_Btn3,
		[ 4 ] = SelfBaoJian_Frame_Bk2_Btn4,
		[ 5 ] = SelfBaoJian_Frame_Bk2_Btn5
	}

	g_JadeIconCtrl[ 3 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk3_Btn1,
		[ 2 ] = SelfBaoJian_Frame_Bk3_Btn2,
		[ 3 ] = SelfBaoJian_Frame_Bk3_Btn3,
		[ 4 ] = SelfBaoJian_Frame_Bk3_Btn4,
		[ 5 ] = SelfBaoJian_Frame_Bk3_Btn5
	}

	g_JadeIconCtrl[ 4 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk4_Btn1,
		[ 2 ] = SelfBaoJian_Frame_Bk4_Btn2,
		[ 3 ] = SelfBaoJian_Frame_Bk4_Btn3,
		[ 4 ] = SelfBaoJian_Frame_Bk4_Btn4,
		[ 5 ] = SelfBaoJian_Frame_Bk4_Btn5
	}

	g_JadeIconCtrl[ 5 ] = {

		[ 1 ] = SelfBaoJian_Frame_Bk5_Btn1,
		[ 2 ] = SelfBaoJian_Frame_Bk5_Btn2,
		[ 3 ] = SelfBaoJian_Frame_Bk5_Btn3,
		[ 4 ] = SelfBaoJian_Frame_Bk5_Btn4,
		[ 5 ] = SelfBaoJian_Frame_Bk5_Btn5
	}

	g_ElementsNameTextCtrl[ 1 ] = SelfBaoJian_Frame_Btn_text1_1
	g_ElementsNameTextCtrl[ 2 ] = SelfBaoJian_Frame_Btn2_text1_1
	g_ElementsNameTextCtrl[ 3 ] = SelfBaoJian_Frame_Btn3_text1_1
	g_ElementsNameTextCtrl[ 4 ] = SelfBaoJian_Frame_Btn4_text1_1
	g_ElementsNameTextCtrl[ 5 ] = SelfBaoJian_Frame_Btn5_text1_1

	g_ElementsValueTextCtrl[ 1 ] = SelfBaoJian_Frame_Btn_text1_2
	g_ElementsValueTextCtrl[ 2 ] = SelfBaoJian_Frame_Btn2_text1_2
	g_ElementsValueTextCtrl[ 3 ] = SelfBaoJian_Frame_Btn3_text1_2
	g_ElementsValueTextCtrl[ 4 ] = SelfBaoJian_Frame_Btn4_text1_2
	g_ElementsValueTextCtrl[ 5 ] = SelfBaoJian_Frame_Btn5_text1_2

	g_ElementsJadeExtendCtrl[ 1 ] = SelfBaoJian_Frame_Btn_text1_3
	g_ElementsJadeExtendCtrl[ 2 ] = SelfBaoJian_Frame_Btn2_text1_3
	g_ElementsJadeExtendCtrl[ 3 ] = SelfBaoJian_Frame_Btn3_text1_3
	g_ElementsJadeExtendCtrl[ 4 ] = SelfBaoJian_Frame_Btn4_text1_3
	g_ElementsJadeExtendCtrl[ 5 ] = SelfBaoJian_Frame_Btn5_text1_3

	g_ElementsEquipExtendCtrl[ 1 ] = SelfBaoJian_Frame_Btn_text1_4
	g_ElementsEquipExtendCtrl[ 2 ] = SelfBaoJian_Frame_Btn2_text1_4
	g_ElementsEquipExtendCtrl[ 3 ] = SelfBaoJian_Frame_Btn3_text1_4
	g_ElementsEquipExtendCtrl[ 4 ] = SelfBaoJian_Frame_Btn4_text1_4
	g_ElementsEquipExtendCtrl[ 5 ] = SelfBaoJian_Frame_Btn5_text1_4

	g_ElementsCtrl_Parent[ 1 ] = SelfBaoJian_Frame_Bk1
	g_ElementsCtrl_Parent[ 2 ] = SelfBaoJian_Frame_Bk2
	g_ElementsCtrl_Parent[ 3 ] = SelfBaoJian_Frame_Bk3
	g_ElementsCtrl_Parent[ 4 ] = SelfBaoJian_Frame_Bk4
	g_ElementsCtrl_Parent[ 5 ] = SelfBaoJian_Frame_Bk5

	g_SelfBaoJian_Frame_UnifiedXPosition = SelfBaoJian_Frame:GetProperty("UnifiedXPosition")
	g_SelfBaoJian_Frame_UnifiedYPosition = SelfBaoJian_Frame:GetProperty("UnifiedYPosition")

	g_SelfBaoJian_PageButton[1] = SelfBaoJian_SelfEquip
	g_SelfBaoJian_PageButton[2] = SelfBaoJian_SelfData
	g_SelfBaoJian_PageButton[3] = SelfBaoJian_Pet
	g_SelfBaoJian_PageButton[4] = SelfBaoJian_Infant
	g_SelfBaoJian_PageButton[5] = SelfBaoJian_Wuhun
	g_SelfBaoJian_PageButton[6] = SelfBaoJian_Xiulian
	g_SelfBaoJian_PageButton[7] = SelfBaoJian_Miji
	g_SelfBaoJian_PageButton[8] = SelfBaoJian_ZhenYuan
	g_SelfBaoJian_PageButton[9] = SelfBaoJian_JingMai
	g_SelfBaoJian_PageButton[10] = SelfBaoJian_ShenDing
	g_SelfBaoJian_PageButton[11] = SelfBaoJian_JunXian
	g_SelfBaoJian_PageButton[12] = SelfBaoJian_BaoJian
	g_SelfBaoJian_PageButton[13] = SelfBaoJian_WuYi
	g_SelfBaoJian_PageButton[14] = SelfBaoJian_ShenQi
	g_SelfBaoJian_PageButton[15] = SelfBaoJian_Armor
	g_SelfBaoJian_PageButton[16] = SelfBaoJian_CangPin
	g_SelfBaoJian_PageButton[17] = SelfBaoJian_OtherInfo
	
	g_SelfBaoJian_PageMask[1] = SelfBaoJian_SelfEquip_tips
	g_SelfBaoJian_PageMask[2] = SelfBaoJian_SelfData_tips
	g_SelfBaoJian_PageMask[3] = SelfBaoJian_Pet_tips
	g_SelfBaoJian_PageMask[4] = SelfBaoJian_Infant_tips
	g_SelfBaoJian_PageMask[5] = SelfBaoJian_Wuhun_tips
	g_SelfBaoJian_PageMask[6] = SelfBaoJian_Xiulian_tips
	g_SelfBaoJian_PageMask[7] = SelfBaoJian_Miji_tips
	g_SelfBaoJian_PageMask[8] = SelfBaoJian_ZhenYuan_tips
	g_SelfBaoJian_PageMask[9] = SelfBaoJian_JingMai_tips
	g_SelfBaoJian_PageMask[10] = SelfBaoJian_ShenDing_tips
	g_SelfBaoJian_PageMask[11] = SelfBaoJian_JunXian_tips
	g_SelfBaoJian_PageMask[12] = SelfBaoJian_BaoJian_tips
	g_SelfBaoJian_PageMask[13] = SelfBaoJian_WuYi_tips
	g_SelfBaoJian_PageMask[14] = SelfBaoJian_ShenQi_tips
	g_SelfBaoJian_PageMask[15] = SelfBaoJian_Armor_tips
	g_SelfBaoJian_PageMask[16] = SelfBaoJian_CangPin_tips
	g_SelfBaoJian_PageMask[17] = SelfBaoJian_OtherInfo_tips
	
	g_PageButtonTipsPos[1] = "{0.000000,28.000000}" 
	g_PageButtonTipsPos[2] = "{0.000000,64.000000}" 
	g_PageButtonTipsPos[3] = "{0.000000,100.000000}"
	g_PageButtonTipsPos[4] = "{0.000000,136.000000}"
	g_PageButtonTipsPos[5] = "{0.000000,172.000000}"
	g_PageButtonTipsPos[6] = "{0.000000,208.000000}"
	g_PageButtonTipsPos[7] = "{0.000000,244.000000}"
	g_PageButtonTipsPos[8] = "{0.000000,280.000000}"
	g_PageButtonTipsPos[9] = "{0.000000,316.000000}" 
	g_PageButtonTipsPos[10] = "{0.000000,352.000000}" 
	g_PageButtonTipsPos[11] = "{0.000000,388.000000}" 
	g_PageButtonTipsPos[12] = "{0.000000,424.000000}" 
	g_PageButtonTipsPos[13] = "{0.000000,460.000000}" 
	g_PageButtonTipsPos[14] = "{0.000000,496.000000}"
	g_PageButtonTipsPos[15] = "{0.000000,532.000000}"
	g_PageButtonTipsPos[16] = "{0.000000,568.000000}"
	g_PageButtonTipsPos[17] = "{0.000000,604.000000}"
	
end

function SelfBaoJian_OnEvent(event)

	if event == "SELF_FIVE_ELEMENTS_OPEN" then
		this:Show()
		SelfBaoJian_Update()
		SelfBaoJian_Refresh_Page_Button()
		SelfBaoJian_ShowPage()
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "FIVEELEMENTS_UPDATE"  and this:IsVisible() then
		SelfBaoJian_Update()
		return
	end

	if event == "REFRESH_EQUIP" and this:IsVisible() then

		SelfBaoJian_Update()
		return
	end

	if event == "ADJEST_UI_POS" and this:IsVisible() then
		SelfBaoJian_Frame_On_ResetPos()
		return
	end

	if event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible() then
		SelfBaoJian_Frame_On_ResetPos()
		return
	end
	
	if(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		SelfBaoJian_RefreshWuYiTip()
		return
	end

	if event == "UPDATE_TOY_TIP" then
		SelfBaoJian_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SelfBaoJian_RefreshCangPinTip()
	end
end

-- 刷新
function SelfBaoJian_Update()

	local selfUnionPos = Variable:GetVariable("SelfUnionPos")
	if(selfUnionPos ~= nil) then
		SelfBaoJian_Frame:SetProperty("UnifiedPosition", selfUnionPos)
	end

	SelfBaoJian_BaoJian:SetCheck(1)

	for i = 1 , 5 do

		local bElementsActive 	= Player:IsFiveElements_ElementsActive( i - 1 )
		local bElementsLevel	= Player:GetFiveElements_ElementsLevel( i - 1 )
		local bElementsType		= Player:GetFiveElements_ElementsType( i - 1 )

		if bElementsLevel > 0 then
			g_ElementsCtrl[ i ]:SetProperty("Image" , g_ElementsImage[ i ])
			local szStr = ScriptGlobal_Format( "#{ZZZB_150811_139}", g_ElementsName[ i ], tostring(bElementsLevel) )
			g_ElementsNameTextCtrl[ i ]:SetText(szStr)

			if i == 3 or i == 5 then

				local nElementsValue = DataPool:Lua_GetFiveElementsValueWithEquipAndJade( i - 1 )

				local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_141}", g_ElementsValueName[ i ][ 1 ] , nElementsValue )
				g_ElementsValueTextCtrl[ i ]:SetText(nValueText)

				if bElementsActive == 1 then
					local nAllExtendValue = 0
					for j = 0 , 4 do

						local bJadeType = Player:GetFiveElements_JadeType( i - 1  , j )
						local nExtendValue = Player:GetFiveElements_JadeExtend( i - 1 ,  bJadeType)
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

				local nEquipExtend_1 = DataPool:Lua_GetEquipZhiZunExtend(1)
				local nEquipExtend_2 = DataPool:Lua_GetEquipZhiZunExtend(2)
				g_ElementsEquipExtendCtrl[ i ]:SetText("#c00ccff+"..tostring(nEquipExtend_1 + nEquipExtend_2).."%" )
				g_ElementsEquipExtendCtrl[ i ]:SetToolTip("#{ZZZB_150811_143}")

			end

			if i == 1 or i == 2 or i == 4 then
				if g_ElementsValueName[ i ][ bElementsType ] ~= nil then

					local nElementsValue = DataPool:Lua_GetFiveElementsValueWithEquipAndJade( i - 1 )

					local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_141}", g_ElementsValueName[ i ][ bElementsType ] , nElementsValue )
					g_ElementsValueTextCtrl[ i ]:SetText(nValueText)

					if bElementsActive == 1 then
						local nAllExtendValue = 0
						for j = 0 , 4 do

							local bJadeType = Player:GetFiveElements_JadeType( i - 1  , j )
							local nExtendValue = Player:GetFiveElements_JadeExtend( i - 1 ,  bJadeType)
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

					local nEquipExtend_1 = DataPool:Lua_GetEquipZhiZunExtend(1)
					local nEquipExtend_2 = DataPool:Lua_GetEquipZhiZunExtend(2)
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

				local bJadeType = Player:GetFiveElements_JadeType( i - 1  , j - 1 )
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

	SelfBaoJian_UpdateEquipExtend()

end


function SelfBaoJian_UpdateEquipExtend()

	local nExtendLevel_1 = DataPool:Lua_GetEquipZhiZunExtendLevel( 1 )
	local nExtendLevel_2 = DataPool:Lua_GetEquipZhiZunExtendLevel( 2 )

	--荣耀1
	if nExtendLevel_1 == 1 then

		SelfBaoJian_Frame_Bk9_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk9_Icon1:SetToolTip("#{ZZZB_150811_145}" )

		SelfBaoJian_Frame_Bk10_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk10_Icon1:SetToolTip("#{ZZZB_150811_146}")

		SelfBaoJian_Frame_Bk11_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk11_Icon1:SetToolTip("#{ZZZB_150811_148}")

	elseif nExtendLevel_1 == 2 then

		SelfBaoJian_Frame_Bk9_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk9_Icon1:SetToolTip("#{ZZZB_150811_147}")

		SelfBaoJian_Frame_Bk10_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk10_Icon1:SetToolTip("#{ZZZB_150811_147}")

		SelfBaoJian_Frame_Bk11_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk11_Icon1:SetToolTip("#{ZZZB_150811_148}")

	elseif nExtendLevel_1 == 3 then

		SelfBaoJian_Frame_Bk9_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk9_Icon1:SetToolTip("#{ZZZB_150811_149}")

		SelfBaoJian_Frame_Bk10_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk10_Icon1:SetToolTip("#{ZZZB_150811_149}")

		SelfBaoJian_Frame_Bk11_Icon1:SetProperty("Image" , g_RightThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk11_Icon1:SetToolTip("#{ZZZB_150811_149}")

	else

		SelfBaoJian_Frame_Bk9_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk9_Icon1:SetToolTip("#{ZZZB_150811_144}")

		SelfBaoJian_Frame_Bk10_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk10_Icon1:SetToolTip("#{ZZZB_150811_146}")

		SelfBaoJian_Frame_Bk11_Icon1:SetProperty("Image" , g_RightThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk11_Icon1:SetToolTip("#{ZZZB_150811_148}")

	end

	if nExtendLevel_2 == 1 then

		SelfBaoJian_Frame_Bk8_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk8_Icon1:SetToolTip("#{ZZZB_150811_151}")

		SelfBaoJian_Frame_Bk7_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk7_Icon1:SetToolTip("#{ZZZB_150811_152}")

		SelfBaoJian_Frame_Bk6_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk6_Icon1:SetToolTip("#{ZZZB_150811_154}")

	elseif nExtendLevel_2 == 2 then

		SelfBaoJian_Frame_Bk8_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk8_Icon1:SetToolTip("#{ZZZB_150811_153}")

		SelfBaoJian_Frame_Bk7_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk7_Icon1:SetToolTip("#{ZZZB_150811_153}")

		SelfBaoJian_Frame_Bk6_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk6_Icon1:SetToolTip("#{ZZZB_150811_154}")

	elseif nExtendLevel_2 == 3 then

		SelfBaoJian_Frame_Bk8_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk8_Icon1:SetToolTip("#{ZZZB_150811_155}")

		SelfBaoJian_Frame_Bk7_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk7_Icon1:SetToolTip("#{ZZZB_150811_155}")

		SelfBaoJian_Frame_Bk6_Icon1:SetProperty("Image" , g_LeftThreeImage[ 2 ])
		SelfBaoJian_Frame_Bk6_Icon1:SetToolTip("#{ZZZB_150811_155}")

	else

		SelfBaoJian_Frame_Bk8_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk8_Icon1:SetToolTip("#{ZZZB_150811_150}")

		SelfBaoJian_Frame_Bk7_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk7_Icon1:SetToolTip("#{ZZZB_150811_152}")

		SelfBaoJian_Frame_Bk6_Icon1:SetProperty("Image" , g_LeftThreeImage[ 1 ])
		SelfBaoJian_Frame_Bk6_Icon1:SetToolTip("#{ZZZB_150811_154}")

	end

end


function SelfBaoJian_UpdateText()

end

function SelfBaoJian_OnClose()

	this:Hide()

end

function SelfBaoJian_Elements_MouseLeave(nIndex)

	Lua_CloseFiveElementsTip(0 , nIndex)
end

function SelfBaoJian_Elements_MouseEnter(nIndex)

	if SystemSetup:IsClassic() == 1 then
		local SetX= g_ElementsCtrl[nIndex]:GetProperty("AbsoluteXPosition")
			+ g_ElementsCtrl_Parent[nIndex]:GetProperty("AbsoluteXPosition") + SelfBaoJian_Frame_Part:GetProperty("AbsoluteXPosition")
			+ SelfBaoJian_Client:GetProperty("AbsoluteXPosition") + SelfBaoJian_Frame_Client:GetProperty("AbsoluteXPosition")
			+ SelfBaoJian_Frame:GetProperty("AbsoluteXPosition")

		local SetY = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteYPosition")
			+ g_ElementsCtrl_Parent[nIndex]:GetProperty("AbsoluteYPosition")	+ SelfBaoJian_Frame_Part:GetProperty("AbsoluteYPosition")
			+ SelfBaoJian_Client:GetProperty("AbsoluteYPosition") + SelfBaoJian_Frame_Client:GetProperty("AbsoluteYPosition")
			+ SelfBaoJian_Frame:GetProperty("AbsoluteYPosition")

		local SetWidth = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteWidth")
		local SetHeight = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteHeight")
		Lua_OpenFiveElementsTip(0 , nIndex , SetX ,SetY ,tonumber(SetWidth) ,tonumber(SetHeight))
	else
		local SetX= g_ElementsCtrl[nIndex]:GetProperty("AbsoluteXPosition")
			+ g_ElementsCtrl_Parent[nIndex]:GetProperty("AbsoluteXPosition")	+ SelfBaoJian_Frame_Part:GetProperty("AbsoluteXPosition")
			+ SelfBaoJian_Client:GetProperty("AbsoluteXPosition") + SelfBaoJian_Frame_Client:GetProperty("AbsoluteXPosition")
			+ SelfBaoJian_Frame:GetProperty("AbsoluteXPosition")

		local SetY = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteYPosition")
			+ g_ElementsCtrl_Parent[nIndex]:GetProperty("AbsoluteYPosition")	+ SelfBaoJian_Frame_Part:GetProperty("AbsoluteYPosition")
			+ SelfBaoJian_Client:GetProperty("AbsoluteYPosition") + SelfBaoJian_Frame_Client:GetProperty("AbsoluteYPosition")
			+ SelfBaoJian_Frame:GetProperty("AbsoluteYPosition")

		local SetWidth = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteWidth")
		local SetHeight = g_ElementsCtrl[nIndex]:GetProperty("AbsoluteHeight")
		Lua_OpenFiveElementsTip(0 , nIndex , SetX ,SetY ,tonumber(SetWidth) ,tonumber(SetHeight))
	end


end

--装备
function SelfBaoJian_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	OpenEquip(1)
end

--珍兽
function SelfBaoJian_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	TogglePetPage()
end

--资料
function SelfBaoJian_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPrivatePage("self")
end

--子女
function SelfBaoJian_Infant_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Infant:ToggleInfantPage()
	if bRet == 1 then
		this:Hide()
	else
		SelfBaoJian_Infant:SetCheck(0)
	end
end

--武魂
function SelfBaoJian_Wuhun_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	ToggleWuhunPage()
end

--修炼
function SelfBaoJian_Xiulian_Page_Switch()
    local nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
		XiuLianPage()
	else
	    SelfBaoJian_Xiulian:SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

--秘籍
function SelfBaoJian_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenMijiPage()
	if nRet ~= 1 then
		SelfBaoJian_Miji:SetCheck(0)
	end
end

--真元
function SelfBaoJian_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Pneuma:ToggleZhenYuanPage()
	if bRet ~= 1 then
		SelfBaoJian_ZhenYuan:SetCheck(0)
	end
end

--经脉
function SelfBaoJian_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenJingMaiPage()
	if nRet ~= 1 then
		SelfBaoJian_JingMai:SetCheck(0)
	end
end

--神鼎
function  SelfBaoJian_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenShenDingPage()
	if nRet ~= 1 then
		SelfBaoJian_ShenDing:SetCheck(0)
	end
end

--侠印
function  SelfBaoJian_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" )
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = OpenJunXianPage()
	if ( bRet == 1 ) then
		this:Hide()
	else
		SelfBaoJian_JunXian:SetCheck(0)
	end
end

--骑乘
function SelfBaoJian_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	OpenRidePage()
end

--其他
function SelfBaoJian_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	OtherInfoPage()
end

function SelfBaoJian_Refresh_Page_Button()

	if 1 == 1 then
		return
	end
	
	local nLevel =Player:GetLevel()

	--神鼎
	if ( nLevel < 15 ) then
		SelfBaoJian_ShenDing:Disable()
		SelfBaoJian_ShenDing_tips:Show()
	else
		SelfBaoJian_ShenDing:Enable()
		SelfBaoJian_ShenDing_tips:Hide()
	end

	--子女
	local InfantCount = Infant:GetInfantCount()
	if ( nLevel < 50 ) or InfantCount<=0 then
		SelfBaoJian_Infant:Disable()
		SelfBaoJian_Infant_tips:Show()
	else
		SelfBaoJian_Infant:Enable()
		SelfBaoJian_Infant_tips:Hide()
	end

	--武魂
--	if ( nLevel < 65 ) then
--		SelfBaoJian_Wuhun:Disable()
--		SelfBaoJian_Wuhun_tips:Show()
--	else
		SelfBaoJian_Wuhun:Enable()
		SelfBaoJian_Wuhun_tips:Hide()
--	end

	--修炼
	if ( nLevel < 70 ) then
		SelfBaoJian_Xiulian:Disable()
		SelfBaoJian_Xiulian_tips:Show()
	else
		SelfBaoJian_Xiulian:Enable()
		SelfBaoJian_Xiulian_tips:Hide()
	end

	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		SelfBaoJian_Miji:Disable()
		SelfBaoJian_Miji_tips:Show()
	else
		SelfBaoJian_Miji:Enable()
		SelfBaoJian_Miji_tips:Hide()
	end

	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		SelfBaoJian_ZhenYuan:Disable()
		SelfBaoJian_ZhenYuan_tips:Show()
	else
		SelfBaoJian_ZhenYuan:Enable()
		SelfBaoJian_ZhenYuan_tips:Hide()
	end

	--侠印
	if ( nLevel < 85 ) then
		SelfBaoJian_JunXian:Disable()
		SelfBaoJian_JunXian_tips:Show()
	else
		SelfBaoJian_JunXian:Enable()
		SelfBaoJian_JunXian_tips:Hide()
	end

	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		SelfBaoJian_JingMai:Disable()
		SelfBaoJian_JingMai_tips:Show()
	else
		SelfBaoJian_JingMai:Enable()
		SelfBaoJian_JingMai_tips:Hide()
	end

	--五行宝鉴
	if ( nLevel < 85 ) then
		SelfBaoJian_BaoJian:Disable()
		SelfBaoJian_BaoJian_tips:Show()
	else
		SelfBaoJian_BaoJian:Enable()
		SelfBaoJian_BaoJian_tips:Hide()
	end
	
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		SelfBaoJian_WuYi:Enable()
		SelfBaoJian_WuYi_tips:Hide()
	else
		SelfBaoJian_WuYi:Disable()
		SelfBaoJian_WuYi_tips:Show()
	end
	SelfBaoJian_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		SelfBaoJian_ShenQi:Enable()
		SelfBaoJian_ShenQi_tips:Hide()
	else
		SelfBaoJian_ShenQi:Disable()
		SelfBaoJian_ShenQi_tips:Show()
	end
	SelfBaoJian_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		SelfBaoJian_Armor:Enable()
		SelfBaoJian_Armor_tips:Hide()
	else
		SelfBaoJian_Armor:Disable()
		SelfBaoJian_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		SelfBaoJian_CangPin:Enable()
		SelfBaoJian_CangPin_tips:Hide()
	else
		SelfBaoJian_CangPin:Disable()
		SelfBaoJian_CangPin_tips:Show()
	end
	
	SelfBaoJian_RefreshCangPinTip()
end

function SelfBaoJian_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

function SelfBaoJian_Frame_On_ResetPos()

	SelfBaoJian_Frame:SetProperty("UnifiedXPosition", g_SelfBaoJian_Frame_UnifiedXPosition)
	SelfBaoJian_Frame:SetProperty("UnifiedYPosition", g_SelfBaoJian_Frame_UnifiedYPosition)

end

-- 九星神器DIY技能
function SelfBaoJian_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function SelfBaoJian_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfBaoJian_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfBaoJian_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		SelfBaoJian_WuYi_Buttontips:Show()
	else
		SelfBaoJian_WuYi_Buttontips:Hide()
	end
end

function SelfBaoJian_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfBaoJian_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfBaoJian_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		SelfBaoJian_OtherInfo_ButtonTips:Show()
	else
		SelfBaoJian_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function SelfBaoJian_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function SelfBaoJian_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfBaoJian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SelfBaoJian_RefreshCangPinTip()
	local CangPinClassCount = 4
	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	local bTip = 0
	for i = 1, CangPinClassCount do
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			bTip = 1
		end
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 16 and g_PageButtonTipsPos[idx] then -- 名物
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfBaoJian_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfBaoJian_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SelfBaoJian_CangPin_Buttontips:Show()
	else
		SelfBaoJian_CangPin_Buttontips:Hide()
	end
end

function SelfBaoJian_ShowPage()

	for i = 1, table.getn(g_SelfBaoJian_Page) do
		g_SelfBaoJian_PageButton[i]:Hide()
		g_SelfBaoJian_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SelfBaoJian_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SelfBaoJian_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SelfBaoJian_Page) do
			if i ~= nPageNumber then
				g_SelfBaoJian_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SelfBaoJian_Page) do
		if SelfBaoJian_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SelfBaoJian_PageButton[g_PageCount]:Show()
			g_SelfBaoJian_PageButton[g_PageCount]:SetText(g_SelfBaoJian_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SelfBaoJian_IsPageEnable(i) == 1 then
				g_SelfBaoJian_PageButton[g_PageCount]:Enable()
				g_SelfBaoJian_PageMask[g_PageCount]:Hide()
			else
				g_SelfBaoJian_PageButton[g_PageCount]:Disable()
				g_SelfBaoJian_PageMask[g_PageCount]:Show()
				if g_SelfBaoJian_Page[i].Tip ~= "" then
					g_SelfBaoJian_PageMask[g_PageCount]:SetToolTip(g_SelfBaoJian_Page[i].Tip)
				end
			end
		end
	end
	
	SelfBaoJian_RefreshWuYiTip()
	SelfBaoJian_RefreshOtherInfoTip()
	SelfBaoJian_RefreshCangPinTip()
	
end

function SelfBaoJian_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		SelfBaoJian_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		SelfBaoJian_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		SelfBaoJian_Pet_Page_Switch()
	elseif idx == 4 then--子女
		SelfBaoJian_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		SelfBaoJian_Wuhun_Page_Switch()
	elseif idx == 6 then--修炼
		SelfBaoJian_Xiulian_Page_Switch()
	elseif idx == 7 then--秘籍
		SelfBaoJian_Miji_Page_Switch()
	elseif idx == 8 then--真元
		SelfBaoJian_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		SelfBaoJian_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		SelfBaoJian_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		SelfBaoJian_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		--SelfData_OpenBaoJian()
	elseif idx == 13 then--武意
		SelfBaoJian_OpenWuYi()
	elseif idx == 14 then--神器
		SelfBaoJian_OpenShenQi()
	elseif idx == 15 then--星盘
		SelfBaoJian_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SelfBaoJian_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		SelfBaoJian_OtherInfo_Page_Switch()
	end
end

function SelfBaoJian_CheckPage(idx)
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
	elseif idx == 6 then--修炼
		return 1
	elseif idx == 7 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 9 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 16 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function SelfBaoJian_IsPageEnable(idx)
	
	local nLevel = Player:GetLevel()
	
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		local InfantCount = Infant:GetInfantCount();
		if ( nLevel < 50 ) or ( InfantCount <= 0 ) then
			return 0
		end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--修炼
		if ( nLevel < 70 ) then
			return 0
		end
		return 1
	elseif idx == 7 then--秘籍
		local ret = DataPool:Lua_IsMissionHaveDone(1651)
		if ( nLevel < 75 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		local ret = DataPool:Lua_IsMissionHaveDone(1600)
		if ( nLevel < 80 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 9 then--经脉
		local ret = DataPool:Lua_IsMissionHaveDone(1554)
		if ( nLevel < 90 ) or ( ret == 0 )  then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if ( nLevel < 15 ) then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if (MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
			return 1
		end
		return 0
	elseif idx == 14 then--神器
		if (DataPool:Lua_IsMissionHaveDone(1950) == 1) then
			return 1
		end
		return 0
	elseif idx == 15 then--星盘
		if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
			return 1
		end
		return 0
	elseif idx == 16 then--名物
		if nLevel < 30 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function SelfBaoJian_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end

