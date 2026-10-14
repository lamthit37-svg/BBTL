local WuXingTbl = {
			{level =1,	per = "1.0%" ,	maxlevel=1,	color = "#c00D000"},
			{level =2,	per = "1.5%" ,	maxlevel=1,	color = "#c00D000"},
			{level =3,	per = "2.1%" ,	maxlevel=2,	color = "#c00D000"},
			{level =4,	per = "3.0%" ,	maxlevel=2,	color = "#c00D000"},
			{level =5,	per = "8.0%" ,	maxlevel=3,	color = "#c43DBFF"},
			{level =6,	per = "11.0%" ,	maxlevel=3,	color = "#c43DBFF"},
			{level =7,	per = "14.5%" ,	maxlevel=4,	color = "#c43DBFF"},
			{level =8,	per = "23.5%" ,	maxlevel=4,	color = "#cFF8001"},
			{level =9,	per = "30.0%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =10,	per = "39.3%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =11,	per = "42.3%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =12,	per = "46.0%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =13,	per = "50.2%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =14,	per = "54.7%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =15,	per = "59.5%", maxlevel=5,	color = "#cFF8001"},
}

local ShowColor = "#H"
local TARGETPETSKILL_BUTTONS_NUM = 12
local TARGETPETSKILL_BUTTONS = {}
local Currend_Pet = -1
local PET_AITYPE = {}

--珍兽进阶 限制可携带等级55级以上的珍兽才可以进阶
local PET_JINJIE_LIMIT_BYTLVL = 55
local PET_JINJIELVL_PERGRADE = 10
local PET_JINJIELVL_MAXGRADE = 10
local g_NumToStrTable =
{
	"#{JJKHD_120808_64}",		--零
	"#{JJKHD_120808_65}",		--一
	"#{JJKHD_120808_66}",		--二
	"#{JJKHD_120808_67}",
	"#{JJKHD_120808_68}",		--四
	"#{JJKHD_120808_69}",
	"#{JJKHD_120808_70}",
	"#{JJKHD_120808_71}",
	"#{JJKHD_120808_72}",
	"#{JJKHD_120808_73}",
	"#{JJKHD_120808_74}",
}

local g_PetFoodType1 =
{
	"肉食",
	"草食",
	"虫食",
	"谷食"
}
local g_PetFoodType2 =
{
	"肉",
	"草",
	"虫",
	"谷"
}

--品质
local g_Quality_Str = {
	"#{ZSHP_180814_156}", 
	"#{ZSHP_180814_155}",
	"#{ZSHP_180814_154}",
	"#{ZSHP_180814_153}",
	"#{ZSHP_180814_152}",
	"#{ZSHP_180814_151}",
	"#{ZSHP_180814_150}",
}
local PET_TYPE = {
	[1] = {image = "set:CommonFrame2 image:ZhenShouHeart_Hui", tooltip1 = "#{FZDJ_120717_1}", tooltip2 = "#{FZDJ_120717_2}", tooltip3 = "#{FZDJ_120717_3}", tooltip4 = "#{FZDJ_120717_4}", tooltip5 = "#{FZDJ_120717_5}" },
	[2] = {image = "set:CommonFrame2 image:ZhenShouHeart_Hong", tooltip1 = "#{FZDJ_120717_6}", tooltip2 = "#{FZDJ_120717_7}", tooltip3 = "#{FZDJ_120717_8}" } 
}
local g_isShowPeach = 0


--!!!reloadscript =TargetPet
function TargetPet_PreLoad()
	this:RegisterEvent("UPDATE_TARGETPET_PAGE", true)
	this:RegisterEvent("VIEW_EXCHANGE_PET", true)
	this:RegisterEvent("UPDATE_PETINVITEFRIEND", true)
	this:RegisterEvent("CLOSE_PET_FRAME", false)
	this:RegisterEvent("TOGLE_PET_PAGE", false)
	this:RegisterEvent("YBMARKET_PETVIEW", true)
	this:RegisterEvent("UPDATE_PETMAILITEM", true)
end

function TargetPet_OnLoad()
	TARGETPETSKILL_BUTTONS[1] = TargetPet_Skill1
	TARGETPETSKILL_BUTTONS[2] = TargetPet_Skill2
	TARGETPETSKILL_BUTTONS[3] = TargetPet_Skill3
	TARGETPETSKILL_BUTTONS[4] = TargetPet_Skill4
	TARGETPETSKILL_BUTTONS[5] = TargetPet_Skill5
	TARGETPETSKILL_BUTTONS[6] = TargetPet_Skill6
	TARGETPETSKILL_BUTTONS[7] = TargetPet_Skill7
	TARGETPETSKILL_BUTTONS[8] = TargetPet_Skill8
	TARGETPETSKILL_BUTTONS[9] = TargetPet_Skill9
	TARGETPETSKILL_BUTTONS[10] = TargetPet_Skill10
	TARGETPETSKILL_BUTTONS[11] = TargetPet_Skill11
	TARGETPETSKILL_BUTTONS[12] = TargetPet_Skill12

	PET_AITYPE[0] = "胆小"
	PET_AITYPE[1] = "谨慎"
	PET_AITYPE[2] = "忠诚"
	PET_AITYPE[3] = "精明"
	PET_AITYPE[4] = "勇猛"
end

function TargetPet_OnEvent(event)

	if event == "UPDATE_TARGETPET_PAGE" then
		if tonumber(arg0) >= 0 then
			Currend_Pet = tonumber(arg0)
			TargetPet:CopyMyPet(Currend_Pet)
		end
		
		--关闭冲突界面
		TargetPet_CloseConflictWindow()
		
		if not this:IsVisible() then
			need_attach = 1
		end
		g_isShowPeach = 0
		TargetPet_Update()
		this:Show()
		TargetPet_SetPosition()
		if need_attach == 1 then
			TargetPet_FakeObject:AttachWindowEx("My_TargetPet")
		end
		TargetPet:SetModelAboutHuanLing()
		

	--交易过程中的珍兽显示
	elseif event == "VIEW_EXCHANGE_PET" then
		--关闭冲突界面
		TargetPet_CloseConflictWindow()	
		local need_attach = 0
		if not this:IsVisible() then
			need_attach = 1
		end
		
		g_isShowPeach = 1
		TargetPet_Update()
		this:Show()
		if need_attach == 1 then
			TargetPet_FakeObject:AttachWindowEx("My_TargetPet")
		end
		TargetPet:SetModel()

	elseif event == "UPDATE_PETINVITEFRIEND" then
		if "target" == tostring(arg0) then
			--关闭冲突界面
			TargetPet_CloseConflictWindow()	
			local need_attach = 0
			if not this:IsVisible() then
				need_attach = 1
			end
		
			g_isShowPeach = 0
			TargetPet_Update()
			this:Show()
			
			if need_attach == 1 then
				TargetPet_FakeObject:AttachWindowEx("My_TargetPet")
			end
			TargetPet:SetModel()
		end

	elseif event == "CLOSE_PET_FRAME" and this:IsVisible() then
		this:Hide()
		return
	elseif event == "TOGLE_PET_PAGE" and this:IsVisible() then
		this:Hide()
		return
	elseif event == "YBMARKET_PETVIEW" then
		--关闭冲突界面
		TargetPet_CloseConflictWindow()
		
		g_isShowPeach = 1
		TargetPet_Update()

		if this:IsVisible() then
			TargetPet:SetModel()
			this:Activate()
		else
			this:Show()
			TargetPet_FakeObject:AttachWindowEx("My_TargetPet")			
			TargetPet:SetModel()			
		end
	elseif event == "UPDATE_PETMAILITEM" then -- 邮件cys
		--关闭冲突界面
		TargetPet_CloseConflictWindow()
		local need_attach = 0
		if not this:IsVisible() then
			need_attach = 1
		end
		
		g_isShowPeach = 0
		TargetPet_Update()
		this:Show()
		if need_attach == 1 then
			TargetPet_FakeObject:AttachWindowEx("My_TargetPet")
		end
		TargetPet:SetModel()
	end

end

function TargetPet_OnShown()

	TargetPet_Page_Clear()

	if TargetPet:IsPresent() then
		TargetPet_Update()
		return
	end
end

function TargetPet_Page_Clear()
	
	TargetPet_Client_Button01:SetCheck(1)
	TargetPet_Client_Button02:SetCheck(0)

	if Player:GetData("IsOriginalJD") == 1 then
		TargetPet_Client_Button02:Hide()
	else
		TargetPet_Client_Button02:Show()
	end
	
	if Player:GetData("Is2606S") == 1 then
		TargetPet_Client_Button02:Hide()
	else
		TargetPet_Client_Button02:Show()
	end
	
	TargetPet_PageHeader:SetText("#gFF0FA0")
	TargetPet_ConsortID:SetText("")
	TargetPet_Model_Protect_Text:SetText("")
	TargetPet_TargetPetID:SetText("")
	TargetPet_Sex:SetText("")
	TargetPet_Proficient_Text:Hide()
	TargetPet_Life:SetText("")
	TargetPet_Happy:SetText("")
--	Pet_LoyalgGade:SetText("")
	TargetPet_Level:SetText("")
--	Pet_Type:SetText("")
	TargetPet_StrAptitude:SetText("")
	TargetPet_PhysicalStrengthAptitude:SetText("")
	TargetPet_DexterityAptitude:SetText("")
	TargetPet_NimbusAptitude:SetText("")
	TargetPet_StabilityAptitude:SetText("")
--	TargetPet_Exp:SetText("")
	TargetPet_Blood:SetText("" .. "  " .. "")
--	Pet_MP:SetText("" .. " / " .. "")
	TargetPet_Str:SetText("")
	TargetPet_Str:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")
	TargetPet_Nimbus:SetText("")
	TargetPet_Nimbus:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")
	TargetPet_Dexterity:SetText("")
	TargetPet_Dexterity:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")
	TargetPet_PhysicalStrength:SetText("")
	TargetPet_PhysicalStrength:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")
	TargetPet_Stability:SetText("")
	TargetPet_Stability:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")
	TargetPet_GenGu:SetText("")
	TargetPet_WuXing:SetText("")
	TargetPet_Ronghedu:SetText("")
	TargetPet_Potential:SetText("")
	TargetPet_Potential:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")
	TargetPet_PhysicsAttack:SetText("")
	TargetPet_MagicAttack:SetText("")
	TargetPet_PhysicsRecovery:SetText("")
	TargetPet_MagicRecovery:SetText("")
	TargetPet_Miss:SetText("")
	TargetPet_ShootProbability:SetText("")
	TargetPet_CriticalAttack:SetText("")
	TargetPet_CriticalDefence:SetText("")
	TargetPet_Growth:SetText("")
	TargetPet_Lingxing:SetText("")

	for i = 1, TARGETPETSKILL_BUTTONS_NUM do
		TARGETPETSKILL_BUTTONS[i]:SetActionItem(-1)
	end
	TargetPetFood_Type:Hide()
	TargetPet_NeedLevel:SetText("")
	TargetPet_lock:Hide()
	TargetPetAttack_Type:Hide()
	TargetPet_Jian:Hide()

	TargetPet_Str_jieduan:SetText("")
	TargetPet_Nimbus_jieduan:SetText("")
	TargetPet_Dexterity_jieduan:SetText("")
	TargetPet_PhysicalStrength_jieduan:SetText("")
	TargetPet_Stability_jieduan:SetText("")
	TargetPet_jieduan:SetText("")
	TargetPet_HuanLing:Hide()
	TargetPet_Quality_Text:SetText("")
	TargetPet_Peach:Hide()
end

function TargetPet_Update()
	
	local i

	if not TargetPet:IsPresent() then
		return
	end

	local strName, strName2, sex
	TargetPet_Page_Clear()
	strName = TargetPet:GetAIType(nIndex)

	local strAI, strIcon
	if strName > 4 or strName < 0  then
		strAI = "错误的"
	else
		strAI =	PET_AITYPE[strName]
	end

 	strName, strName2 = TargetPet:GetName()
	local nEra, strTypeName = TargetPet:GetPetTypeName(nIndex)
 	if 1 == nEra then
 	    strName2 = "二代"..strTypeName
 	end
	TargetPet_PetName:SetText(strName2)
	TargetPet_PageHeader:SetText("#gFF0FA0"..strName2)
	TargetPet_Type:SetText("#gFF8E92"..strAI)

	strName, strName2, sex = TargetPet:GetID()
	TargetPet_TargetPetID:SetText("珍兽ID:"..strName2)

	strName = TargetPet:GetConsort()
	if tonumber(strName) == 0 then
		TargetPet_ConsortID:SetText("尚无配偶")
	else
		TargetPet_ConsortID:SetText("配偶ID:".. strName)
	end

	if TargetPet:GetGoodsProtect_Pet() == 1 then
		TargetPet_Model_Protect_Text:SetText("#{GDWPBH_090507_4}")
	else
		TargetPet_Model_Protect_Text:SetText("")
	end

	--品质
	local nQuality = TargetPet:GetPetQuality()
	if nQuality > 0 and nQuality <= 7 then
		TargetPet_Quality_Text:SetText(g_Quality_Str[nQuality])
	end
	
	if sex == 1 then
		strName = "雄性"
	else
		strName = "雌性"
	end

	local nGeneration = TargetPet:GetGeneration()
	if nGeneration ~= nil and nGeneration >= 100 then
		strName = "#{RXZS_XML_35}"
	end

	TargetPet_Sex:SetText(strName)

	if g_isShowPeach == 1 then
		TargetPet_Peach:Show()
		--该珍兽的繁殖情况
		local nPetType = TargetPet:GetPetType()
		local nColor = 1
		if nGeneration == 1 then
		--1:二代
			nColor = 1
			TargetPet_Peach:SetToolTip(PET_TYPE[1].tooltip4)
		elseif nGeneration >= 100 then
		-->=100:幻化
			nColor = 1
			TargetPet_Peach:SetToolTip(PET_TYPE[1].tooltip1)
		else
			if nPetType == 0 then
			--0:宝宝 2022年6月 修改 由记录 上次繁殖等级 改成记录 已经繁殖次数
			--由于要兼容之前的数据，再更新后没繁殖之前 这个数值仍然记录上次繁殖等级，繁殖之后记录已经繁殖次数
				local nLevel = TargetPet:GetLevel()
				local nLastProcreateLevel = TargetPet:GetLastProcreateLevel()
				if nLastProcreateLevel < 0 then
					nLastProcreateLevel = 0
				end
				local nTarget = {30, 50, 70, 90, 110}
				local nTimes = 0
				local nCounts = 0
				local nRemainCounts = 0
				if nLastProcreateLevel >= 30 then --没修改过之前
					if nLastProcreateLevel >= nTarget[5] then
						nRemainCounts = 0
					else
						for i = 1, table.getn(nTarget) do
							if nLastProcreateLevel < nTarget[i] then
								nTimes = i - 1
								break
							end
						end
						for i = 1, table.getn(nTarget) do
							if nLevel < nTarget[i] then
								nCounts = i - 1
								break
							end
						end
						if nLevel >= nTarget[5] then
							nCounts = 5
						end

						nRemainCounts = nCounts - nTimes
					end
				else
					if nLevel >= nTarget[5] then
						nCounts = 5
					else
						for i = 1, table.getn(nTarget) do
							if nLevel < nTarget[i] then
								nCounts = i - 1
								break
							end
						end
					end
					nRemainCounts = nCounts - nLastProcreateLevel
				end

				if nRemainCounts > 0 or nLevel < nTarget[5] then
					nColor = 2
				else
					nColor = 1
				end
				TargetPet_Peach:SetToolTip(ScriptGlobal_Format("#{ZSFZYH_220606_01}", nRemainCounts))

			elseif nPetType == 1 then
			--1:变异
				nColor = 1
				TargetPet_Peach:SetToolTip(PET_TYPE[1].tooltip3)
			elseif nPetType == 2 then
			--2:成年
				nColor = 1
				TargetPet_Peach:SetToolTip(PET_TYPE[1].tooltip2)
			end
		end
		TargetPet_Peach:SetProperty("Image", PET_TYPE[nColor].image)
	end

	strName = TargetPet:GetNaturalLife()
	TargetPet_Life:SetText("寿命:"..strName)

	strName = TargetPet:GetLevel()
	TargetPet_Level:SetText("等级:"..strName.."级")

	strName = TargetPet:GetHappy()
	TargetPet_Happy:SetText("快乐:"..strName)

	strName = TargetPet:GetBasic()
	TargetPet_GenGu:SetText("根骨:"..strName)

	strName = TargetPet:GetLixing(nIndex)
	TargetPet_Lingxing:SetText("#{RXZS_XML_28}"..strName)

	-- 注意, 必须把悟性放在最后, 因为后面计算珍兽一级属性加成的时候要用到, 并且直接用的 strName
	strName = TargetPet:GetFitValue()
	TargetPet_Ronghedu:SetText("#{ZSHT_XML_04}:" .. strName)

	strName = TargetPet:GetSavvy()

	TargetPet_WuXing:SetText("悟性:".. strName)

	local WuXingVal = tonumber(strName)
	strName = TargetPet:GetStrAptitude()
	if WuXingTbl[WuXingVal] ~= nil then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")"
	end
	TargetPet_StrAptitude:SetText(strName)

	strName = TargetPet:GetPFAptitude(nIndex)
	if WuXingTbl[WuXingVal] ~= nil then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")"
	end
	TargetPet_PhysicalStrengthAptitude:SetText(strName)

	strName = TargetPet:GetDexAptitude()
	if WuXingTbl[WuXingVal] ~= nil then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")"
	end
	TargetPet_DexterityAptitude:SetText(strName)

	strName = TargetPet:GetIntAptitude()
	if WuXingTbl[WuXingVal] ~= nil then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")"
	end
	TargetPet_NimbusAptitude:SetText(strName)

	strName = TargetPet:GetStaAptitude()
	if WuXingTbl[WuXingVal] ~= nil then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")"
	end
	TargetPet_StabilityAptitude:SetText(strName)

--	strName = TargetPet:GetExp()
--	TargetPet_Exp:SetText("经验:"..strName)

	strName = TargetPet:GetHP(nIndex)
	strName2 = TargetPet:GetMaxHP(nIndex)
	TargetPet_Blood:SetText("血:"..strName .." / ".. strName2)
	local nTakeLevel = TargetPet:GetTakeLevel()
	--珍兽进阶 --废除传承标志
	--local bJinJieImpact = TargetPet:GetJinJieImpact(nIndex)
	local nJinJieGrade = TargetPet:GetJinJieGrade(nIndex)
	local nJinJieLevel = TargetPet:GetJinJieLvl(nIndex)
	if nTakeLevel < PET_JINJIE_LIMIT_BYTLVL then
		TargetPet_jieduan:SetText("#{JJKHD_120808_21}")
		TargetPet_jieduan:SetToolTip("#{JJKHD_120808_35}")
	elseif nJinJieGrade == PET_JINJIELVL_MAXGRADE then
		TargetPet_jieduan:SetText("#{JJKHD_120808_24}")
		TargetPet_jieduan:SetToolTip("#{JJKHD_120808_37}")
	elseif nJinJieGrade < PET_JINJIELVL_MAXGRADE then
		if g_NumToStrTable[nJinJieGrade + 1] ~= nil and g_NumToStrTable[nJinJieLevel + 1] ~= nil then
			local szCurJinJieInfo = ScriptGlobal_Format("#{JJKHD_120808_22}", g_NumToStrTable[nJinJieGrade + 1], g_NumToStrTable[nJinJieLevel + 1])
			TargetPet_jieduan:SetText(szCurJinJieInfo)
		end
		TargetPet_jieduan:SetToolTip("#{JJKHD_120808_36}")
	end

	local strJinJie = 0
	local SprJinJie = 0
	local DexJinJie = 0
	local ConJinJie = 0
	local IntJinJie = 0
	if nJinJieGrade > 0 or nJinJieLevel > 0 then
		TargetPet_Str_jieduan:Show()
		TargetPet_Nimbus_jieduan:Show()
		TargetPet_Dexterity_jieduan:Show()
		TargetPet_PhysicalStrength_jieduan:Show()
		TargetPet_Stability_jieduan:Show()

		strJinJie = TargetPet:GetJinJieStr()	--力量
		TargetPet_Str_jieduan:SetText("+"..tonumber(strJinJie))

		SprJinJie = TargetPet:GetJinJieSpr()	--灵气
		TargetPet_Nimbus_jieduan:SetText("+"..tonumber(SprJinJie))

		DexJinJie = TargetPet:GetJinJieDex()	--身法
		TargetPet_Dexterity_jieduan:SetText("+"..tonumber(DexJinJie))

		ConJinJie = TargetPet:GetJinJieCon()	--体力
		TargetPet_PhysicalStrength_jieduan:SetText("+"..tonumber(ConJinJie))

		IntJinJie = TargetPet:GetJinJieINT()	--定力
		TargetPet_Stability_jieduan:SetText("+"..tonumber(IntJinJie))
	else
		TargetPet_Str_jieduan:Hide()
		TargetPet_Nimbus_jieduan:Hide()
		TargetPet_Dexterity_jieduan:Hide()
		TargetPet_PhysicalStrength_jieduan:Hide()
		TargetPet_Stability_jieduan:Hide()
	end

	strName = TargetPet:GetStr()
	TargetPet_Str:SetText(tonumber(strName - strJinJie))
	TargetPet_Str:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")

	strName = TargetPet:GetInt()
	TargetPet_Nimbus:SetText(tonumber(strName - SprJinJie))
	TargetPet_Nimbus:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")

	strName = TargetPet:GetDex()
	TargetPet_Dexterity:SetText(tonumber(strName - DexJinJie))
	TargetPet_Dexterity:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")

	strName = TargetPet:GetPF()
	TargetPet_PhysicalStrength:SetText(tonumber(strName - ConJinJie))
	TargetPet_PhysicalStrength:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")

	strName = TargetPet:GetSta()
	TargetPet_Stability:SetText(tonumber(strName - IntJinJie))
	TargetPet_Stability:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")

--	strName = TargetPet:GetBasic()
--	TargetPet_Basic:SetText(tonumber(strName))

	strName = TargetPet:GetCriticalAttack()
	TargetPet_CriticalAttack:SetText(tonumber(strName))

	strName = TargetPet:GetCriticalDefence()
	TargetPet_CriticalDefence:SetText(tonumber(strName))

	strName = TargetPet:GetPotential()
	strName2 = tonumber(strName)
	TargetPet_Potential:SetText(strName2)
	TargetPet_Potential:SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF")

	strName = TargetPet:GetPhysicsAttack()
	TargetPet_PhysicsAttack:SetText(strName)

	strName = TargetPet:GetMagicAttack()
	TargetPet_MagicAttack:SetText(strName)

	strName = TargetPet:GetPhysicsRecovery()
	TargetPet_PhysicsRecovery:SetText(strName)

	strName = TargetPet:GetMagicRecovery ()
	TargetPet_MagicRecovery:SetText(strName)

	--闪避率
	strName = TargetPet:GetMiss()
	TargetPet_Miss:SetText(strName)

	--命中率
	strName = TargetPet:GetShootProbability()
	TargetPet_ShootProbability:SetText(strName)

	local SumPetSkill = GetActionNum("petskill")
	local k = 1 

	for i = 1, SumPetSkill + TARGETPETSKILL_BUTTONS_NUM do
		local theSkillAction = Pet:EnumPetSkill(100, i-1, "petskill")
		if theSkillAction ~= nil and theSkillAction:GetPetSkillOwner() == 100 and k <= TARGETPETSKILL_BUTTONS_NUM then
			TARGETPETSKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID())
			k = k + 1
		end
	end

	local strNeedLevel
	local strNeedLevelColor
	local nIsBaiShou = Pet:GetIsBaiShou()
	local nTakeLevel_BaiShou = nTakeLevel
	if nIsBaiShou == 1 then
		nTakeLevel_BaiShou = nTakeLevel - 10
	    if nTakeLevel_BaiShou < 1 then
			nTakeLevel_BaiShou = 1
		end
	end

	if nTakeLevel_BaiShou > Player:GetData("LEVEL") then
		strNeedLevelColor ="#cFF0000"
	else
		strNeedLevelColor ="#c00FF00"
	end
	strNeedLevel = strNeedLevelColor..tostring(nTakeLevel).."级#W可携带"

	TargetPet_NeedLevel:SetText(strNeedLevel)
	if nIsBaiShou == 1 then
		TargetPet_Proficient_Text:Show()
	else
		TargetPet_Proficient_Text:Hide()	
	end

	--幻灵
	local nHuanlingId = TargetPet:GetPetHuanlingID(nIndex)
	if nHuanlingId >= 0 then
		local strName = Pet:Lua_GetPetHuanLingInfo(nHuanlingId, "Name")
		local strStyle = Pet:Lua_GetPetHuanLingInfo(nHuanlingId, "ExText")
		TargetPet_HuanLing:SetText("#{ZSHP_180814_05}")
		TargetPet_HuanLing:SetToolTip(ScriptGlobal_Format("#{ZSHP_180814_06}", strName, strStyle))
		TargetPet_HuanLing:Show()
	end
	
	strName = TargetPet:GetGrowRate()
	TargetPet_Growth:SetText("#G未知")
	local nGrowLevel = TargetPet:GetPetGrowLevel(tonumber(strName))
	local strTbl = {"普通","优秀","杰出","卓越","完美"}

	if nGrowLevel >= 0 then
		nGrowLevel = nGrowLevel + 1	--c里是从0开始的枚举
		local nGrowRate = TargetPet:GetGrowRate()
		if strTbl[nGrowLevel] ~= nil then
			TargetPet_Growth:SetText("#G"..strTbl[nGrowLevel]..nGrowRate)
		end
	end

	local food = TargetPet:GetFoodType()
	local strFoodName = ""
	local strFoodType = ""

	if food >= 1000 then
		strFoodName = strFoodName .. g_PetFoodType1[1]
		strFoodType = strFoodType .. g_PetFoodType2[1]
		food = food - 1000
		if food > 0 then
			strFoodName = strFoodName .. "、"
			strFoodType = strFoodType .. "、"
		end
	end
	if food >= 100 then
		strFoodName = strFoodName .. g_PetFoodType1[2]
		strFoodType = strFoodType .. g_PetFoodType2[2]
		food = food - 100
		if food > 0 then
			strFoodName = strFoodName .. "、"
			strFoodType = strFoodType .. "、"
		end
	end
	if food >= 10 then
		strFoodName = strFoodName .. g_PetFoodType1[3]
		strFoodType = strFoodType .. g_PetFoodType2[3]
		food = food - 10
		if food > 0 then
			strFoodName = strFoodName .. "、"
			strFoodType = strFoodType .. "、"
		end
	end

	if food >= 1 then
		strFoodName = strFoodName .. g_PetFoodType1[4]
		strFoodType = strFoodType .. g_PetFoodType2[4]
	end
	local strToShow = ""
	strToShow = ScriptGlobal_Format("#{XSLC_121220_10}", strFoodName, strFoodType)
	TargetPetFood_Type:Show()
	TargetPetFood_Type:SetToolTip(strToShow)

	strName,strIcon = TargetPet:GetAttackTrait()

	if strIcon ~= "" then
		TargetPetAttack_Type:SetProperty("Image", "set:Button6 image:"..strIcon)
		TargetPetAttack_Type:SetToolTip(strName)
		TargetPetAttack_Type:Show()
	end

	TargetPet_Jian:Show()
end

----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function TargetPet_Modle_TurnLeft(start)
	--向左旋转开始
	local mouse_button = CEArg:GetValue("MouseButton")
	if mouse_button == "LeftButton" then
		--向左旋转开始
		if start == 1 then
			TargetPet_FakeObject:RotateBeginEx("My_TargetPet", -0.3)
		--向左旋转结束
		else
			TargetPet_FakeObject:RotateEndEx()
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function TargetPet_Modle_TurnRight(start)
	--向右旋转开始
	local mouse_button = CEArg:GetValue("MouseButton")
	if mouse_button == "LeftButton" then
		--向右旋转开始
		if start == 1 then
			TargetPet_FakeObject:RotateBeginEx("My_TargetPet", 0.3)
		--向右旋转结束
		else
			TargetPet_FakeObject:RotateEndEx()
		end
	end
end

function TargetPet_Jian_Clicked()
	if not TargetPet:IsPresent() then
		return
	end
	Pet:PetOpenPetJian(-1, "target")
end

function TargetPet_PetNeiDan_Switch()
	
	if Player:GetData("IsOriginalJD") == 1 then
		return
	end
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("TargetPetUnionPos", TargetPet_Frame:GetProperty("UnifiedPosition"), 1)
	Pet:LuaFnOpenPetNeiDan("target")
end

function TargetPet_CloseConflictWindow()
	if IsWindowShow("OtherPet") then
		CloseWindow("OtherPet", true)
	end
	
	if IsWindowShow("OtherYuShou_BaiHu") then
		CloseWindow("OtherYuShou_BaiHu", true)
	end
	
	if IsWindowShow("OtherYuShou_QingLong") then
		CloseWindow("OtherYuShou_QingLong", true)
	end
	
	if IsWindowShow("OtherYuShou_XuanWu") then
		CloseWindow("OtherYuShou_XuanWu", true)
	end
	
	if IsWindowShow("OtherYuShou_ZhuQue") then
		CloseWindow("OtherYuShou_ZhuQue", true)
	end
	
	if IsWindowShow("OtherHuanLing") then
		CloseWindow("OtherHuanLing", true)
	end
	
	if IsWindowShow("OtherPetNeidan") then
		CloseWindow("OtherPetNeidan", true)
	end

	if IsWindowShow("TargetPet2") then
		CloseWindow("TargetPet2", true)
	end
	
	if IsWindowShow("TargetPetNeidan") then
		CloseWindow("TargetPetNeidan", true)
	end
end

function TargetPet_SetPosition()
	local targetPetUnionPos = Variable:GetVariable("TargetPetUnionPos")
	if targetPetUnionPos ~= nil then
		TargetPet_Frame:SetProperty("UnifiedPosition", targetPetUnionPos)
	end
end

function TargetPet_OnHidden()
	TargetPet_FakeObject:DetachWindowEx("My_TargetPet")
end