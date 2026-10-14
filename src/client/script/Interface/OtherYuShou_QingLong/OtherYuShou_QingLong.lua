
local m_PointArray_NoActived = {}
local m_PointArray_Button = {}
local m_PointArray_Actived_Possession = {}

local m_pmPointIndex = {58,59,60,61,62, 63,64,65,66,67, 68,69,70,71,72, 73,74,75,76,77,
78,79,80,81,82, 83,84,85,86}

local m_pmEffectString = { 
	"#{YSSJ_140818_81}#{YSSJ_140818_83}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_84}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_85}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_86}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_87}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_88}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_89}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_90}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_91}" ,
	
	"#{YSSJ_140818_82}#{YSSJ_140818_92}" ,
	"#{YSSJ_140818_82}#{YSSJ_140818_93}" ,
	"#{YSSJ_140818_82}#{YSSJ_140818_94}" ,
	"#{YSSJ_140818_82}#{YSSJ_140818_95}" ,
	"#{YSSJ_140818_82}#{YSSJ_140818_96}" ,
}

local m_ButtonFightImage_Small = { 

	"set:ButtonYuShou01 image:ButtonYuShouCZX_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouCZX_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouCZX_Pushed",		--pushed

}

local m_ButtonFightImage_Big = { 

	"set:ButtonYuShou01 image:ButtonYuShouCZD_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouCZD_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouCZD_Pushed",		--pushed

}

local m_ButtonPossessionImage_Small = { 

	"set:ButtonYuShou01 image:ButtonYuShouFTX_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouFTX_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouFTX_Pushed",		--pushed

}

local m_ButtonPossessionImage_Big = { 

	"set:ButtonYuShou01 image:ButtonYuShouFTD_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouFTD_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouFTD_Pushed",		--pushed

}

local m_ButtonUnActiveImage_Small = { 

	"set:ButtonYuShou01 image:ButtonYuShouFTX_Disabled" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouFTX_Disabled",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouFTX_Disabled",		--pushed

}

local m_ButtonUnActiveImage_Big = { 

	"set:ButtonYuShou01 image:ButtonYuShouFTD_Disabled" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouFTD_Disabled",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouFTD_Disabled",		--pushed

}

local m_TextCtr_TotalEffect = {}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_OtherYuShou_QingLong_Page = {
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

local g_OtherPageButton = {}
local g_OtherPageCount = 0
local g_OtherPageOrder = {}

function OtherYuShou_QingLong_PreLoad()

	this:RegisterEvent("OPEN_OTHER_PETMASTER") 
	this:RegisterEvent("OTHER_PETMASTER_UPDATE")
	
end

function OtherYuShou_QingLong_OnLoad()
	--未激活
	m_PointArray_NoActived[1]	 = OtherYuShou_QingLong_PointA01
	m_PointArray_NoActived[2]	 = OtherYuShou_QingLong_PointA02
	m_PointArray_NoActived[3]	 = OtherYuShou_QingLong_PointA03
	m_PointArray_NoActived[4]	 = OtherYuShou_QingLong_PointA04
	m_PointArray_NoActived[5]	 = OtherYuShou_QingLong_PointA05
	m_PointArray_NoActived[6]	 = OtherYuShou_QingLong_PointA06
	m_PointArray_NoActived[7]	 = OtherYuShou_QingLong_PointA07
	m_PointArray_NoActived[8]	 = OtherYuShou_QingLong_PointA08
	m_PointArray_NoActived[9]	 = OtherYuShou_QingLong_PointA09
	m_PointArray_NoActived[10]	 = OtherYuShou_QingLong_PointA10
	m_PointArray_NoActived[11]	 = OtherYuShou_QingLong_PointA11
	m_PointArray_NoActived[12]	 = OtherYuShou_QingLong_PointA12
	m_PointArray_NoActived[13]	 = OtherYuShou_QingLong_PointA13
	m_PointArray_NoActived[14]	 = OtherYuShou_QingLong_PointA14
	m_PointArray_NoActived[15]	 = OtherYuShou_QingLong_PointA15
	m_PointArray_NoActived[16]	 = OtherYuShou_QingLong_PointA16
	m_PointArray_NoActived[17]	 = OtherYuShou_QingLong_PointA17
	m_PointArray_NoActived[18]	 = OtherYuShou_QingLong_PointA18
	m_PointArray_NoActived[19]	 = OtherYuShou_QingLong_PointA19
	m_PointArray_NoActived[20]	 = OtherYuShou_QingLong_PointA20
	m_PointArray_NoActived[21]	 = OtherYuShou_QingLong_PointA21
	m_PointArray_NoActived[22]	 = OtherYuShou_QingLong_PointA22
	m_PointArray_NoActived[23]	 = OtherYuShou_QingLong_PointA23
	m_PointArray_NoActived[24]	 = OtherYuShou_QingLong_PointA24
	m_PointArray_NoActived[25]	 = OtherYuShou_QingLong_PointA25
	m_PointArray_NoActived[26]	 = OtherYuShou_QingLong_PointA26
	m_PointArray_NoActived[27]	 = OtherYuShou_QingLong_PointA27
	m_PointArray_NoActived[28]	 = OtherYuShou_QingLong_PointA28
	m_PointArray_NoActived[29]	 = OtherYuShou_QingLong_PointA29
	--已激活出战
	m_PointArray_Button[1] = OtherYuShou_QingLong_Point01
	m_PointArray_Button[2] =	OtherYuShou_QingLong_Point02
	m_PointArray_Button[3] =	OtherYuShou_QingLong_Point03
	m_PointArray_Button[4] =	OtherYuShou_QingLong_Point04
	m_PointArray_Button[5] =	OtherYuShou_QingLong_Point05
	m_PointArray_Button[6] =	OtherYuShou_QingLong_Point06
	m_PointArray_Button[7] =	OtherYuShou_QingLong_Point07
	m_PointArray_Button[8] =	OtherYuShou_QingLong_Point08
	m_PointArray_Button[9] =	OtherYuShou_QingLong_Point09
	m_PointArray_Button[10] =	OtherYuShou_QingLong_Point10
	m_PointArray_Button[11] =	OtherYuShou_QingLong_Point11
	m_PointArray_Button[12] =	OtherYuShou_QingLong_Point12
	m_PointArray_Button[13] =	OtherYuShou_QingLong_Point13
	m_PointArray_Button[14] =	OtherYuShou_QingLong_Point14
	m_PointArray_Button[15] =	OtherYuShou_QingLong_Point15
	m_PointArray_Button[16] =	OtherYuShou_QingLong_Point16
	m_PointArray_Button[17] =	OtherYuShou_QingLong_Point17
	m_PointArray_Button[18] =	OtherYuShou_QingLong_Point18
	m_PointArray_Button[19] =	OtherYuShou_QingLong_Point19
	m_PointArray_Button[20] =	OtherYuShou_QingLong_Point20
	m_PointArray_Button[21] =	OtherYuShou_QingLong_Point21
	m_PointArray_Button[22] =	OtherYuShou_QingLong_Point22
	m_PointArray_Button[23] =	OtherYuShou_QingLong_Point23
	m_PointArray_Button[24] =	OtherYuShou_QingLong_Point24
	m_PointArray_Button[25] =	OtherYuShou_QingLong_Point25
	m_PointArray_Button[26] =	OtherYuShou_QingLong_Point26
	m_PointArray_Button[27] =	OtherYuShou_QingLong_Point27
	m_PointArray_Button[28] =	OtherYuShou_QingLong_Point28
	m_PointArray_Button[29] =	OtherYuShou_QingLong_Point29
	--已激活附体
	m_PointArray_Actived_Possession[1]	 = OtherYuShou_QingLong_Point01_T
	m_PointArray_Actived_Possession[2]	 = OtherYuShou_QingLong_Point02_T
	m_PointArray_Actived_Possession[3]	 = OtherYuShou_QingLong_Point03_T
	m_PointArray_Actived_Possession[4]	 = OtherYuShou_QingLong_Point04_T
	m_PointArray_Actived_Possession[5]	 = OtherYuShou_QingLong_Point05_T
	m_PointArray_Actived_Possession[6]	 = OtherYuShou_QingLong_Point06_T
	m_PointArray_Actived_Possession[7]	 = OtherYuShou_QingLong_Point07_T
	m_PointArray_Actived_Possession[8]	 = OtherYuShou_QingLong_Point08_T
	m_PointArray_Actived_Possession[9]	 = OtherYuShou_QingLong_Point09_T
	m_PointArray_Actived_Possession[10]	 = OtherYuShou_QingLong_Point10_T
	m_PointArray_Actived_Possession[11]	 = OtherYuShou_QingLong_Point11_T
	m_PointArray_Actived_Possession[12]	 = OtherYuShou_QingLong_Point12_T
	m_PointArray_Actived_Possession[13]	 = OtherYuShou_QingLong_Point13_T
	m_PointArray_Actived_Possession[14]	 = OtherYuShou_QingLong_Point14_T
	m_PointArray_Actived_Possession[15]	 = OtherYuShou_QingLong_Point15_T
	m_PointArray_Actived_Possession[16]	 = OtherYuShou_QingLong_Point16_T
	m_PointArray_Actived_Possession[17]	 = OtherYuShou_QingLong_Point17_T
	m_PointArray_Actived_Possession[18]	 = OtherYuShou_QingLong_Point18_T
	m_PointArray_Actived_Possession[19]	 = OtherYuShou_QingLong_Point19_T
	m_PointArray_Actived_Possession[20]	 = OtherYuShou_QingLong_Point20_T
	m_PointArray_Actived_Possession[21]	 = OtherYuShou_QingLong_Point21_T
	m_PointArray_Actived_Possession[22]	 = OtherYuShou_QingLong_Point22_T
	m_PointArray_Actived_Possession[23]	 = OtherYuShou_QingLong_Point23_T
	m_PointArray_Actived_Possession[24]	 = OtherYuShou_QingLong_Point24_T
	m_PointArray_Actived_Possession[25]	 = OtherYuShou_QingLong_Point25_T
	m_PointArray_Actived_Possession[26]	 = OtherYuShou_QingLong_Point26_T
	m_PointArray_Actived_Possession[27]	 = OtherYuShou_QingLong_Point27_T
	m_PointArray_Actived_Possession[28]	 = OtherYuShou_QingLong_Point28_T
	m_PointArray_Actived_Possession[29]	 = OtherYuShou_QingLong_Point29_T
	
	m_TextCtr_TotalEffect[1] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_002
	m_TextCtr_TotalEffect[2] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_003
	m_TextCtr_TotalEffect[3] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_004
	m_TextCtr_TotalEffect[4] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_005
	m_TextCtr_TotalEffect[5] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_006
	m_TextCtr_TotalEffect[6] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_007
	m_TextCtr_TotalEffect[7] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_008
	m_TextCtr_TotalEffect[8] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_009
	m_TextCtr_TotalEffect[9] = OtherYuShou_QingLong_Frame_Client2_Client_Text01_010
	
	m_TextCtr_TotalEffect[10] = OtherYuShou_QingLong_Frame_Client2_Client_Text03_002
	m_TextCtr_TotalEffect[11] = OtherYuShou_QingLong_Frame_Client2_Client_Text03_003
	m_TextCtr_TotalEffect[12] = OtherYuShou_QingLong_Frame_Client2_Client_Text03_004
	m_TextCtr_TotalEffect[13] = OtherYuShou_QingLong_Frame_Client2_Client_Text03_005
	m_TextCtr_TotalEffect[14] = OtherYuShou_QingLong_Frame_Client2_Client_Text03_006
	
	g_OtherPageButton[1] = OtherYuShou_QingLong_Equip
	g_OtherPageButton[2] = OtherYuShou_QingLong_Data
	g_OtherPageButton[3] = OtherYuShou_QingLong_Pet
	g_OtherPageButton[4] = OtherYuShou_QingLong_Infant
	g_OtherPageButton[5] = OtherYuShou_QingLong_Wuhun
	g_OtherPageButton[6] = OtherYuShou_QingLong_Miji
	g_OtherPageButton[7] = OtherYuShou_QingLong_ZhenYuan
	g_OtherPageButton[8] = OtherYuShou_QingLong_JingMai
	g_OtherPageButton[9] = OtherYuShou_QingLong_ShenDing
	g_OtherPageButton[10] = OtherYuShou_QingLong_JueWei
	g_OtherPageButton[11] = OtherYuShou_QingLong_BaoJian
	g_OtherPageButton[12] = OtherYuShou_QingLong_WuYi
	g_OtherPageButton[13] = OtherYuShou_QingLong_ShenQi
	g_OtherPageButton[14] = OtherYuShou_QingLong_Armor
	g_OtherPageButton[15] = OtherYuShou_QingLong_CangPin
	
end

function OtherYuShou_QingLong_OnEvent(event)
	
	if( event == "OPEN_OTHER_PETMASTER" ) then
		
		if Player:GetData("Is2606S") == 1 then
			return
		end
		
		if tonumber(arg0) == 2 then
		
			local obj_id = CachedTarget:GetData("NPCID", 1)
			if (type(obj_id) ~= "number") then
				PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
				return
			end
			this:CareObject(obj_id , 1)
			
			OtherYuShou_QingLong_Init()
			OtherYuShou_QingLong_ShowPage()
			this:Show()
		end
	end
	
	if( event == "OTHER_PETMASTER_UPDATE" ) then
		if this:IsVisible() then	
			OtherYuShou_QingLong_Update()
		end
	end

end

function OtherYuShou_QingLong_Reset()
	
	OtherYuShou_QingLong_Equip:SetCheck(0)
	OtherYuShou_QingLong_Data:SetCheck(0)
	OtherYuShou_QingLong_Pet:SetCheck(1)
	OtherYuShou_QingLong_Infant:SetCheck(0)
	OtherYuShou_QingLong_Wuhun:SetCheck(0)
	OtherYuShou_QingLong_Miji:SetCheck(0)
	OtherYuShou_QingLong_ZhenYuan:SetCheck(0)
	OtherYuShou_QingLong_JingMai:SetCheck(0)
	OtherYuShou_QingLong_ShenDing:SetCheck(0)
	OtherYuShou_QingLong_Ride:SetCheck(0)
	
	OtherYuShou_QingLong_Frame_Client_Button01:SetCheck(0)
	OtherYuShou_QingLong_Frame_Client_Button02:SetCheck(1)
	OtherYuShou_QingLong_Frame_Client_Button03:SetCheck(0)

	OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button01:SetCheck(0)
	OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button02:SetCheck(0)
	OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button03:SetCheck(1)
	OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button04:SetCheck(0)
	
	for i = 1 , 29 do
	
		m_PointArray_NoActived[i]:Hide()
		m_PointArray_Button[i]:Show()
		m_PointArray_Actived_Possession[i]:Hide()
		
	end

end

function OtherYuShou_QingLong_Adjust_Position()

	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		OtherYuShou_QingLong_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
	
end

function OtherYuShou_QingLong_Init()
	
	OtherYuShou_QingLong_Reset()
	OtherYuShou_QingLong_Adjust_Position()
	
	OtherYuShou_QingLong_UpdatePoint()
	
	for i = 1 , 14 do
	
		local effectStr = Player:GetOtherPetMasterTotalEffect( i - 1)
		if effectStr ~= nil then
		
			m_TextCtr_TotalEffect[i]:SetText(tostring(effectStr).." ")
		end
	
	end
	
	if Player:GetData("IsOriginalJD") == 1 or Player : GetData("Is2606S") == 1 then
		OtherYuShou_QingLong_Frame_Client_Button04:Hide()
	else
		OtherYuShou_QingLong_Frame_Client_Button04:Show()
	end
	
	OtherYuShou_QingLong_UpdatePageButton()
	
end

function OtherYuShou_QingLong_Update()
	
	OtherYuShou_QingLong_UpdatePoint()
	
	for i = 1 , 14 do
	
		local effectStr = Player:GetOtherPetMasterTotalEffect( i - 1)
		if effectStr ~= nil then
		
			m_TextCtr_TotalEffect[i]:SetText(tostring(effectStr).." ")
		end
	
	end
	
	OtherYuShou_QingLong_UpdatePageButton()
	
end

function OtherYuShou_QingLong_UpdatePoint()

	for i = 1, table.getn(m_pmPointIndex) do
		
		local pointState = Player:GetOtherPetMasterPointState(m_pmPointIndex[i] , "State")
		local petFlag = Player:GetOtherPetMasterPointState(m_pmPointIndex[i] , "PetFlag")
		if pointState ~= nil and petFlag ~= nil then
			
			local strTip = ""
			local strTipTail = ""
			if pointState == 0 or pointState == 1 then			--未激活 或者 待激活
				
				if m_pmPointIndex[i] == 86 then
					m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonUnActiveImage_Big[1])
					m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonUnActiveImage_Big[2])
					m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonUnActiveImage_Big[3])
				else
					m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonUnActiveImage_Small[1])
					m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonUnActiveImage_Small[2])
					m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonUnActiveImage_Small[3])
				end
				
				strTip = strTip.."#{YSSJ_140818_80}#r"
				
			elseif pointState == 2 then 	--已激活
				
				if petFlag == 0 then
					if m_pmPointIndex[i] == 86 then
						m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonFightImage_Big[1])
						m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonFightImage_Big[2])
						m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonFightImage_Big[3])
					else
						m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonFightImage_Small[1])
						m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonFightImage_Small[2])
						m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonFightImage_Small[3])
					end
				else
					if m_pmPointIndex[i] == 86 then
						m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonPossessionImage_Big[1])
						m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonPossessionImage_Big[2])
						m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonPossessionImage_Big[3])
					else
						m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonPossessionImage_Small[1])
						m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonPossessionImage_Small[2])
						m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonPossessionImage_Small[3])
					end
				end
				
				strTip = strTip.."#{YSSJ_140818_98}#r"
			end
			
			local nEffectEnum , strEffect = Player:GetPetMasterPointEffect(m_pmPointIndex[i] ,0)
			if nEffectEnum ~= nil and m_pmEffectString[nEffectEnum + 1] ~= nil then
				strTip = strTip..m_pmEffectString[nEffectEnum + 1]..tostring(strEffect)
			end
			
			nEffectEnum , strEffect = Player:GetPetMasterPointEffect(m_pmPointIndex[i] ,1)
			if nEffectEnum ~= nil and m_pmEffectString[nEffectEnum + 1] ~= nil then
				strTip = strTip.."#r"..m_pmEffectString[nEffectEnum + 1]..tostring(strEffect)
			end
			
			nEffectEnum , strEffect = Player:GetPetMasterPointEffect(m_pmPointIndex[i] ,2)
			if nEffectEnum ~= nil and m_pmEffectString[nEffectEnum + 1] ~= nil then
				strTip = strTip.."#r"..m_pmEffectString[nEffectEnum + 1]..tostring(strEffect)
			end
			
			m_PointArray_Button[i]:SetToolTip(strTip)
			
		end
		
	end

end

function OtherYuShou_QingLong_UpdatePageButton()

	local p3_LastPointState = Player:GetOtherPetMasterPointState(86 , "State")
	if p3_LastPointState ~= nil and p3_LastPointState == 2 then 
		OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button04:Enable()
		OtherYuShou_QingLong_Frame_Client2_Client_Image0ImageDB:SetProperty("Image", "set:YuShou_DiBanJH image:YuShou_DiBanJH_Picture")
	else
		OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button04:Disable()	
		OtherYuShou_QingLong_Frame_Client2_Client_Image0ImageDB:SetProperty("Image", "set:YuShou_DiBan image:YuShou_DiBan_Picture")
	end
	
end


function OtherYuShou_QingLong_Close()
	
	OtherYuShou_QingLong_Reset()
	this:Hide()
	
end

function OtherYuShou_QingLong_OnHidden()

	OtherYuShou_QingLong_Reset()
	
end

function OtherYuShou_QingLong_Point_Clicked(nIndex)

end

--装备
function OtherYuShou_QingLong_Equip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenEquipFrame("other")
end

--资料
function OtherYuShou_QingLong_Data_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPrivatePage("other")
end

--子女
function OtherYuShou_QingLong_Infant_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Infant:Other_ToggleInfantPage()
	if bRet ~= 1 then
		OtherYuShou_QingLong_Infant:SetCheck(0)
	end
end

--武魂
function OtherYuShou_QingLong_Wuhun_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherWuhun()
end

--秘籍
function OtherYuShou_QingLong_Miji_Page_Down()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherMiji()
	this:Hide()
end

--真元
function OtherYuShou_QingLong_ZhenYuan_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Pneuma:ToggleTargetZhenYuanPage()
	if bRet ~= 1 then
		OtherYuShou_QingLong_ZhenYuan:SetCheck(0)
	end
end

--经脉
function OtherYuShou_QingLong_JingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherJingMai()
end

--神鼎
function  OtherYuShou_QingLong_ShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local nLevel = CachedTarget:GetData("LEVEL",1)
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" )
	else
		local bRet = SystemSetup:OpenOtherShenDing()
		if nRet ~= 1 then
			OtherYuShou_QingLong_ShenDing:SetCheck(0)
		end
	end
end

--侠印
function  OtherYuShou_QingLong_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	else
		OtherYuShou_QingLong_JueWei:SetCheck(0)
	end
end

--骑乘
function OtherYuShou_QingLong_Ride_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenRidePage("other")
end

--五行宝鉴
function OtherYuShou_QingLong_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

--珍兽
function OtherYuShou_QingLong_Pet_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPetFrame("other")
end

--朱雀诀
function OtherYuShou_QingLong_ZhuQue_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local ret = Lua_OpenOtherPetMasterPage(0) 
	if ret ~= 1 then
		OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button01:SetCheck(0)
	end
end

--玄武诀
function OtherYuShou_QingLong_XuanWu_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local ret = Lua_OpenOtherPetMasterPage(1) 
	if ret ~= 1 then
		OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button02:SetCheck(0)
	end
end

--白虎诀
function OtherYuShou_QingLong_BaiHu_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local ret = Lua_OpenOtherPetMasterPage(3) 
	if ret ~= 1 then
		OtherYuShou_QingLong_Frame_Client2_Client_Image01_Button04:SetCheck(0)
	end
end

function OtherYuShou_QingLong_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function OtherYuShou_QingLong_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function OtherYuShou_QingLong_PetNeiDan_Page_Switch()

	if Player:GetData("IsOriginalJD") == 1 then
		return
	end
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	Pet:LuaFnOpenPetNeiDan("other")
end

function OtherYuShou_QingLong_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function OtherYuShou_QingLong_TargetHuanLing_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherHuanLing();
end

function OtherYuShou_QingLong_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherYuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end


function OtherYuShou_QingLong_ShowPage()

	for i = 1, table.getn(g_OtherYuShou_QingLong_Page) do
		g_OtherPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	OtherYuShou_QingLong_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_OtherPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_OtherYuShou_QingLong_Page) do
			if i ~= nOtherPageNumber then
				g_OtherPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_OtherPageOrder = {}
	g_OtherPageCount = 0
	for i = 1, table.getn(g_OtherYuShou_QingLong_Page) do
		if OtherYuShou_QingLong_CheckPage(i) == 1 then
			g_OtherPageCount = g_OtherPageCount + 1
			g_OtherPageButton[g_OtherPageCount]:Show()
			g_OtherPageButton[g_OtherPageCount]:SetText(g_OtherYuShou_QingLong_Page[i].Text)	
			g_OtherPageOrder[g_OtherPageCount] = i
		end
	end
	
end

function OtherYuShou_QingLong_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_OtherPageOrder[idx]
	
	if idx == 1 then--装备
		OtherYuShou_QingLong_Equip_Page_Switch();
	elseif idx == 2 then--资料
		OtherYuShou_QingLong_Data_Page_Switch()
	elseif idx == 3 then--珍兽
		--OtherMartial_WuYi_Pet_Switch()
	elseif idx == 4 then--子女
		OtherYuShou_QingLong_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		OtherYuShou_QingLong_Wuhun_Page_Switch()
	elseif idx == 6 then--秘籍
		OtherYuShou_QingLong_Miji_Page_Down()
	elseif idx == 7 then--真元
		OtherYuShou_QingLong_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		OtherYuShou_QingLong_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		OtherYuShou_QingLong_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		OtherYuShou_QingLong_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		OtherYuShou_QingLong_OpenBaoJian()
	elseif idx == 12 then--武意
		OtherYuShou_QingLong_OpenWuYi()
	elseif idx == 13 then--神器
		OtherYuShou_QingLong_OpenShenQi()
	elseif idx == 14 then--星盘
		OtherYuShou_QingLong_Armor_Page_Switch()
	elseif idx == 15 then--名物
		OtherYuShou_QingLong_CangPin_Page_Switch()
	end
end

function OtherYuShou_QingLong_CheckPage(idx)
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

function OtherYuShou_QingLong_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


