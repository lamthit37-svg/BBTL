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
local ShowColor = "#H";
local TargetPet2SKILL_BUTTONS_NUM = 12;
local TargetPet2SKILL_BUTTONS = {};
local Currend_Pet = -1;
local PET_AITYPE = {};

local OpenPetBank = 0	-- 是否是从珍兽银行点击"查看"打开的界面, 如果是, 就显示桃心, 如果不是就不显示.
----------------------------
--珍兽装备按钮数据定义 zchw
local g_Pet_Head; 		--头
local g_Pet_Claw;			--爪
local g_Pet_Body; 		--躯干
local g_Pet_Neck;			--项圈
local g_Pet_Charm;		--护符

----------------------------

--珍兽进阶 限制可携带等级55级以上的珍兽才可以进阶
local PET_JINJIE_LIMIT_BYTLVL = 55
local PET_JINJIELVL_PERGRADE	= 10
local PET_JINJIELVL_MAXGRADE	= 10
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

function TargetPet2_PreLoad()

	this:RegisterEvent("SHOW_CONTEXT_SEL_PET");
	this:RegisterEvent("CLOSE_PET_FRAME")
	this:RegisterEvent("TOGLE_OPEN_PET_PETBANK")

end

function TargetPet2_OnLoad()
	TargetPet2SKILL_BUTTONS[1] = TargetPet2_Skill1;
	TargetPet2SKILL_BUTTONS[2] = TargetPet2_Skill2;
	TargetPet2SKILL_BUTTONS[3] = TargetPet2_Skill3;
	TargetPet2SKILL_BUTTONS[4] = TargetPet2_Skill4;
	TargetPet2SKILL_BUTTONS[5] = TargetPet2_Skill5;
	TargetPet2SKILL_BUTTONS[6] = TargetPet2_Skill6;
	TargetPet2SKILL_BUTTONS[7] = TargetPet2_Skill7;
	TargetPet2SKILL_BUTTONS[8] = TargetPet2_Skill8;
	TargetPet2SKILL_BUTTONS[9] = TargetPet2_Skill9;
	TargetPet2SKILL_BUTTONS[10] = TargetPet2_Skill10;
	TargetPet2SKILL_BUTTONS[11] = TargetPet2_Skill11;
	TargetPet2SKILL_BUTTONS[12] = TargetPet2_Skill12;

	PET_AITYPE[0] = "胆小";
	PET_AITYPE[1] = "谨慎";
	PET_AITYPE[2] = "忠诚";
	PET_AITYPE[3] = "精明";
	PET_AITYPE[4] = "勇猛";

	--------------------------
	-- 珍兽装备与全局变量关联 zchw
	g_Pet_Head = TargetPetEquip_1;
	g_Pet_Claw = TargetPetEquip_2;
	g_Pet_Body = TargetPetEquip_3;
	g_Pet_Neck = TargetPetEquip_4;
	g_Pet_Charm = TargetPetEquip_5;
	---------------------------
end

local TARGETPET2_TYPE = {
[1] = {image = "set:CommonFrame2 image:ZhenShouHeart_Hui", tooltip1 = "#{FZDJ_120717_1}", tooltip2 = "#{FZDJ_120717_2}", tooltip3 = "#{FZDJ_120717_3}", tooltip4 = "#{FZDJ_120717_4}", tooltip5 = "#{FZDJ_120717_5}" },
[2] = {image = "set:CommonFrame2 image:ZhenShouHeart_Hong", tooltip1 = "#{FZDJ_120717_6}", tooltip2 = "#{FZDJ_120717_7}", tooltip3 = "#{FZDJ_120717_8}" } };

function TargetPet2_OnEvent(event)

	--交易过程中的珍兽显示
	if (event == "SHOW_CONTEXT_SEL_PET")  then
		if(IsWindowShow("OtherPet")) then
			CloseWindow("OtherPet", true);
		end
		if IsWindowShow("TargetPet") then
			CloseWindow("TargetPet", true);
		end
		TargetPet2_FakeObject : SetFakeObject( "" );
		TargetPet : SetModel2();
		TargetPet2_FakeObject : SetFakeObject( "My_TargetPet2" );
		TargetPet2_Update();
		TargetPet2_SetStateTooltip();
		this:Show();
	elseif ( event == "CLOSE_PET_FRAME" and this:IsVisible() ) then
		this:Hide();
		return
			--珍兽银行珍兽显示
	elseif (event == "TOGLE_OPEN_PET_PETBANK")  then
		if(IsWindowShow("OtherPet")) then
			CloseWindow("OtherPet", true);
		end
		--zchw
		if IsWindowShow("TargetPet") then
			CloseWindow("TargetPet", true);
		end
		OpenPetBank = 1;	-- 是珍兽银行打开的UI
	  TargetPet2_FakeObject : SetFakeObject( "" );
		TargetPet : SetModel2();
		TargetPet2_FakeObject : SetFakeObject( "My_TargetPet2" );
		TargetPet2_Update();
		TargetPet2_SetStateTooltip();
		this:Show();
	end

end

--zchw
function TargetPet2_Refresh_Equip()

	--  清空按钮显示图标
	g_Pet_Head : SetActionItem(-1);
	g_Pet_Claw : SetActionItem(-1);
	g_Pet_Body : SetActionItem(-1);
	g_Pet_Neck : SetActionItem(-1);
	g_Pet_Charm : SetActionItem(-1);

	local ActionClaw 		= EnumAction(0, "target_pet_equip");
	local ActionHead		= EnumAction(1, "target_pet_equip");
	local ActionBody  	= EnumAction(2, "target_pet_equip");
	local ActionNeck   	= EnumAction(3, "target_pet_equip");
	local ActionCharm   = EnumAction(4, "target_pet_equip");

	g_Pet_Head : SetActionItem(ActionHead : GetID());
	g_Pet_Claw : SetActionItem(ActionClaw : GetID());
	g_Pet_Body : SetActionItem(ActionBody : GetID());
	g_Pet_Neck : SetActionItem(ActionNeck : GetID());
	g_Pet_Charm : SetActionItem(ActionCharm : GetID());

end

--zchw
function TargetPetEquip_Equip_Click(num, type)
end

function TargetPet2_OnShown()

	TargetPet2_Page_Clear();

	if( TargetPet:IsPresent() ) then
		TargetPet2_Update();
		return;
	end;

end

function TargetPet2_Page_Clear()

--	TargetPet2_PetName : SetText( "" );
	TargetPet2_PageHeader : SetText( "#gFF0FA0" );
	TargetPet2_ConsortID : SetText( "" );
	TargetPet2_Model_Protect_Text : SetText( "" );
	TargetPet2_TargetPetID : SetText( "" );
	TargetPet2_Sex : SetText("");
	TargetPet2_Life : SetText( "" );
	TargetPet2_Happy : SetText("");
--	Pet_LoyalgGade : SetText( "" );
	TargetPet2_Level : SetText( "" );
--	Pet_Type : SetText( "" );
	TargetPet2_StrAptitude : SetText( "" );
	TargetPet2_PhysicalStrengthAptitude : SetText( "" );
	TargetPet2_DexterityAptitude : SetText( "" );
	TargetPet2_NimbusAptitude : SetText( "" );
	TargetPet2_StabilityAptitude : SetText( "" );
	TargetPet2_Exp : SetText( "" );
	TargetPet2_Blood : SetText( "" .. "  " .. "" );
--	Pet_MP : SetText( "" .. " / " .. "" );
	TargetPet2_Str : SetText( "" );
	TargetPet2_Str : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	TargetPet2_Nimbus : SetText( "" );
	TargetPet2_Nimbus : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	TargetPet2_Dexterity : SetText( "" );
	TargetPet2_Dexterity : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	TargetPet2_PhysicalStrength : SetText( "" );
	TargetPet2_PhysicalStrength : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	TargetPet2_Stability : SetText( "" );
	TargetPet2_Stability : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	TargetPet2_GenGu : SetText( "" );
	TargetPet2_WuXing : SetText( "" );
	TargetPet2_Ronghedu : SetText("")
	TargetPet2_Potential : SetText( "" );
	TargetPet2_Potential : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	TargetPet2_PhysicsAttack : SetText( "" );
	TargetPet2_MagicAttack : SetText( "" );
	TargetPet2_PhysicsRecovery : SetText( "" );
	TargetPet2_MagicRecovery : SetText( "" );
	TargetPet2_Miss : SetText( "" );
	TargetPet2_ShootProbability : SetText( "" );
	TargetPet2_CriticalAttack:SetText("");
	TargetPet2_CriticalDefence:SetText("");
	TargetPet2_Growth:SetText("")
	TargetPet2_Lingxing : SetText("")
	TargetPet2_Lingxing_Info:SetText("")
	--TargetPet2_FakeObject : SetFakeObject( "" );

	g_Pet_Head : SetActionItem(-1);
	g_Pet_Claw : SetActionItem(-1);
	g_Pet_Body : SetActionItem(-1);
	g_Pet_Neck : SetActionItem(-1);
	g_Pet_Charm : SetActionItem(-1);
	for i=1, TargetPet2SKILL_BUTTONS_NUM do
		TargetPet2SKILL_BUTTONS[i]:SetActionItem(-1);
	end
	TargetPet2Food_Type : Hide()
	TargetPet2_NeedLevel : SetText("")
	TargetPet2_Proficient_Text: Hide()
	TargetPet2_lock:Hide();
	TargetPet2Attack_Type:Hide();
	TargetPet2_Jian : Hide();
	TargetPet2_ClearStateTooltip();

	TargetPet2_Str_jieduan : SetText("")
	TargetPet2_Nimbus_jieduan : SetText( "" );
	TargetPet2_Dexterity_jieduan : SetText( "" );
	TargetPet2_PhysicalStrength_jieduan : SetText( "" );
	TargetPet2_Stability_jieduan : SetText( "" );
	TargetPet2_jieduan : SetText("");

	TargetPet2_Peach : Hide()
	TargetPet2_HuanLing : Hide()
	TargetPet2_Quality_Text : SetText("")
end

function TargetPet2_Update()

	local i;

	if(not (TargetPet:IsPresent()) ) then
		return;
	end

	TargetPet2_Page_Clear();
	strName = TargetPet:GetAIType(nIndex);

	local strAI,strIcon;
	if(strName>4 or strName <0) then
		strAI = "错误的";
	else
		strAI =	PET_AITYPE[strName];
	end

 	strName,strName2 = TargetPet:GetName();
	local nEra, strTypeName = TargetPet:GetPetTypeName(nIndex);
 	if( 1 == nEra ) then
 	    strName2 = "二代"..strTypeName
 	end
	TargetPet2_PetName : SetText( strName );
	TargetPet2_PageHeader : SetText( "#gFF0FA0"..strName2 );
	TargetPet2_Type : SetText("#gFF8E92"..strAI)

	strName,strName2,sex = TargetPet : GetID();
	TargetPet2_TargetPetID : SetText( "珍兽ID:"..strName2 );


	strName = TargetPet : GetConsort();
	if tonumber(strName) == 0 then
		TargetPet2_ConsortID : SetText( "尚无配偶" );
	else
		TargetPet2_ConsortID : SetText( "配偶ID:".. strName );
	end

	if TargetPet : GetGoodsProtect_Pet() == 1 then
		TargetPet2_Model_Protect_Text : SetText( "#{GDWPBH_090507_4}" );
	else
		TargetPet2_Model_Protect_Text : SetText( "" );
	end

	--品质
	local nQuality = TargetPet:GetPetQuality();
	if nQuality > 0 and nQuality <= 7 then
		TargetPet2_Quality_Text:SetText( g_Quality_Str[nQuality]  )
	end
	
	if(sex == 1) then
		strName = "雄性";
	else
		strName = "雌性";
	end

	local nGeneration  = TargetPet : GetGeneration()
	if nGeneration ~= nil and nGeneration >= 100 then
		strName = "#{RXZS_XML_35}";
	end

	TargetPet2_Sex : SetText( strName );

	if ( OpenPetBank == 1 ) then
		TargetPet2_Peach : Show();
		local nPetType = TargetPet : GetPetType();
		local nColor = 1;
		if ( nGeneration == 1 ) then
			--1: 二代
			nColor = 1;
			TargetPet2_Peach : SetToolTip( TARGETPET2_TYPE[ 1 ].tooltip4 );
		elseif ( nGeneration >= 100 ) then
			-->=100:幻化
			nColor = 1;
			TargetPet2_Peach : SetToolTip( TARGETPET2_TYPE[ 1 ].tooltip1 );
		else
			if ( nPetType == 0 ) then
				--0:宝宝 2022年6月 修改 由记录 上次繁殖等级 改成记录 已经繁殖次数
			--由于要兼容之前的数据，再更新后没繁殖之前 这个数值仍然记录上次繁殖等级，繁殖之后记录已经繁殖次数
				local nLevel = TargetPet:GetLevel();
				local nLastProcreateLevel = TargetPet:GetLastProcreateLevel(nIndex);
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
				TargetPet2_Peach : SetToolTip(ScriptGlobal_Format("#{ZSFZYH_220606_01}", nRemainCounts));
			elseif (nPetType == 1 ) then
				--1:变异
				nColor = 1;
				TargetPet2_Peach : SetToolTip(TARGETPET2_TYPE[1].tooltip3);
			elseif ( nPetType == 2 ) then
				--2:成年
				nColor = 1;
				TargetPet2_Peach : SetToolTip(TARGETPET2_TYPE[1].tooltip2);
			else
				TargetPet2_Peach : Hide();
			end
		end
		TargetPet2_Peach : SetProperty("Image", TARGETPET2_TYPE[nColor].image);
		OpenPetBank = 0;	-- 置为0
	end

	strName = TargetPet : GetNaturalLife();
	TargetPet2_Life : SetText( "寿命:"..strName );

	strName = TargetPet : GetLevel();
	TargetPet2_Level : SetText( "等级:"..strName.."级" );

	strName = TargetPet : GetHappy();
	TargetPet2_Happy : SetText( "快乐:"..strName );

	strName = TargetPet : GetBasic();
	TargetPet2_GenGu : SetText( "根骨:"..strName );

	strName = TargetPet : GetLixing(nIndex);
	TargetPet2_Lingxing : SetText("#{RXZS_XML_28}"..strName)

	strName = TargetPet : GetPercent_Lx()
	if tonumber(strName) ~= nil and tonumber(strName) > 0 then
		local rateStr = string.format("%0.1f" , strName / 10.0)
		TargetPet2_Lingxing_Info:SetText("#cFF00FF(+"..rateStr.."%)")
	end

	-- 注意, 必须把悟性放在最后, 因为后面计算珍兽一级属性加成的时候要用到, 并且直接用的 strName
	strName = TargetPet : GetFitValue()
	TargetPet2_Ronghedu : SetText("#{ZSHT_XML_04}:" .. strName)

	strName = TargetPet : GetSavvy();

	TargetPet2_WuXing : SetText( "悟性:".. strName);

	local WuXingVal = tonumber(strName);
	strName = TargetPet : GetStrAptitude();
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end
	
	if TargetPet:IsPetMasterEffectActive(1) == 1 or TargetPet:GetPetMasterTotalEffect(9) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(9)
		TargetPet2_StrAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			TargetPet2_StrAptitude:SetToolTip("#{YSSJ_140818_59}")
			TargetPet2_StrAptitude_Text:SetToolTip("#{YSSJ_140818_59}")
		else
			TargetPet2_StrAptitude:SetToolTip("#{YSSJ_140818_103}")
			TargetPet2_StrAptitude_Text:SetToolTip("#{YSSJ_140818_103}")
		end
	else
		TargetPet2_StrAptitude:SetText( strName )
		TargetPet2_StrAptitude:SetToolTip("")
		TargetPet2_StrAptitude_Text:SetToolTip("")
	end
	
	strName = TargetPet : GetIntAptitude();
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end
	
	if TargetPet:IsPetMasterEffectActive(1) == 1 or TargetPet:GetPetMasterTotalEffect(10) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(10)
		TargetPet2_NimbusAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")"  )
		if(WuXingTbl[WuXingVal])then
			TargetPet2_NimbusAptitude:SetToolTip("#{YSSJ_140818_60}")
			TargetPet2_NimbusAptitude_Text:SetToolTip("#{YSSJ_140818_60}")
		else
			TargetPet2_NimbusAptitude:SetToolTip("#{YSSJ_140818_104}")
			TargetPet2_NimbusAptitude_Text:SetToolTip("#{YSSJ_140818_104}")
		end
	else
		TargetPet2_NimbusAptitude:SetText( strName )
		TargetPet2_NimbusAptitude:SetToolTip("")
		TargetPet2_NimbusAptitude_Text:SetToolTip("")
	end
	
	strName = TargetPet : GetPFAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end

	if TargetPet:IsPetMasterEffectActive(1) == 1 or TargetPet:GetPetMasterTotalEffect(11) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(11)
		TargetPet2_PhysicalStrengthAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			TargetPet2_PhysicalStrengthAptitude:SetToolTip("#{YSSJ_140818_61}")
			TargetPet2_PhysicalStrengthAptitude_Text:SetToolTip("#{YSSJ_140818_61}")
		else
			TargetPet2_PhysicalStrengthAptitude:SetToolTip("#{YSSJ_140818_105}")
			TargetPet2_PhysicalStrengthAptitude_Text:SetToolTip("#{YSSJ_140818_105}")
		end
	else
		TargetPet2_PhysicalStrengthAptitude:SetText( strName )
		TargetPet2_PhysicalStrengthAptitude:SetToolTip("")
		TargetPet2_PhysicalStrengthAptitude_Text:SetToolTip("")
	end

	strName = TargetPet : GetStaAptitude();
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end
	TargetPet2_StabilityAptitude : SetText( strName );
	
	if TargetPet:IsPetMasterEffectActive(1) == 1 or TargetPet:GetPetMasterTotalEffect(12) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(12)
		TargetPet2_StabilityAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			TargetPet2_StabilityAptitude:SetToolTip("#{YSSJ_140818_62}")
			TargetPet2_StabilityAptitude_Text:SetToolTip("#{YSSJ_140818_62}")
		else
			TargetPet2_StabilityAptitude:SetToolTip("#{YSSJ_140818_106}")
			TargetPet2_StabilityAptitude_Text:SetToolTip("#{YSSJ_140818_106}")
		end
	else
		TargetPet2_StabilityAptitude:SetText( strName )
		TargetPet2_StabilityAptitude:SetToolTip("")
		TargetPet2_StabilityAptitude_Text:SetToolTip("")
	end
	
	strName = TargetPet : GetDexAptitude();
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end
	
	if TargetPet:IsPetMasterEffectActive(1) == 1 or TargetPet:GetPetMasterTotalEffect(13) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(13)
		TargetPet2_DexterityAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			TargetPet2_DexterityAptitude:SetToolTip("#{YSSJ_140818_63}")
			TargetPet2_FootworkAptitude_Text:SetToolTip("#{YSSJ_140818_63}")
		else
			TargetPet2_DexterityAptitude:SetToolTip("#{YSSJ_140818_107}")
			TargetPet2_FootworkAptitude_Text:SetToolTip("#{YSSJ_140818_107}")
		end
	else
		TargetPet2_DexterityAptitude:SetText( strName )
		TargetPet2_DexterityAptitude:SetToolTip("")
		TargetPet2_FootworkAptitude_Text:SetToolTip("")
	end

	strName = TargetPet : GetExp();
	TargetPet2_Exp : SetText( "经验:"..strName );

	strName = TargetPet : GetHP(nIndex);
	strName2 = TargetPet:	GetMaxHP(nIndex);
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(0) + TargetPet:GetPetCangpinEffect(0)
		TargetPet2_Blood:SetText( "血:"..strName .."/".. strName2.."#G(+"..tostring(effectStr)..")" )
		TargetPet2_Blood:SetToolTip("#{YSSJ_140818_64}")
	else
		TargetPet2_Blood:SetText( "血:"..strName .."/".. strName2)
		TargetPet2_Blood:SetToolTip("")
	end

		local nTakeLevel = TargetPet:GetTakeLevel();
	--珍兽进阶 废除传承标志
	--local bJinJieImpact = TargetPet : GetJinJieImpact(nIndex);
	local nJinJieGrade = TargetPet : GetJinJieGrade(nIndex);
	local nJinJieLevel = TargetPet : GetJinJieLvl(nIndex);
	if nTakeLevel < PET_JINJIE_LIMIT_BYTLVL then
		TargetPet2_jieduan:SetText("#{JJKHD_120808_21}");
		TargetPet2_jieduan:SetToolTip("#{JJKHD_120808_35}");
	elseif nJinJieGrade == PET_JINJIELVL_MAXGRADE then
		TargetPet2_jieduan:SetText("#{JJKHD_120808_24}");
		TargetPet2_jieduan:SetToolTip("#{JJKHD_120808_37}");
	elseif nJinJieGrade < PET_JINJIELVL_MAXGRADE then
		if g_NumToStrTable[nJinJieGrade + 1] ~= nil and g_NumToStrTable[nJinJieLevel + 1] ~= nil then
			local szCurJinJieInfo = ScriptGlobal_Format("#{JJKHD_120808_22}", g_NumToStrTable[nJinJieGrade + 1], g_NumToStrTable[nJinJieLevel + 1])
			TargetPet2_jieduan:SetText(szCurJinJieInfo);
		end
		TargetPet2_jieduan:SetToolTip("#{JJKHD_120808_36}");
	end

	local strJinJie = 0
	local SprJinJie = 0
	local DexJinJie = 0
	local ConJinJie = 0
	local IntJinJie = 0
	if(nJinJieGrade > 0 or nJinJieLevel > 0) then
		TargetPet2_Str_jieduan:Show()
		TargetPet2_Nimbus_jieduan:Show()
		TargetPet2_Dexterity_jieduan:Show()
		TargetPet2_PhysicalStrength_jieduan:Show()
		TargetPet2_Stability_jieduan:Show()

		strJinJie = TargetPet : GetJinJieStr();	--力量
		TargetPet2_Str_jieduan : SetText("+"..tonumber(strJinJie))

		SprJinJie = TargetPet : GetJinJieSpr();	--灵气
		TargetPet2_Nimbus_jieduan : SetText("+"..tonumber(SprJinJie))

		DexJinJie = TargetPet : GetJinJieDex();	--身法
		TargetPet2_Dexterity_jieduan : SetText("+"..tonumber(DexJinJie))

		ConJinJie = TargetPet : GetJinJieCon();	--体力
		TargetPet2_PhysicalStrength_jieduan : SetText("+"..tonumber(ConJinJie))

		IntJinJie = TargetPet : GetJinJieINT();	--定力
		TargetPet2_Stability_jieduan : SetText("+"..tonumber(IntJinJie))
	else
		TargetPet2_Str_jieduan:Hide()
		TargetPet2_Nimbus_jieduan:Hide()
		TargetPet2_Dexterity_jieduan:Hide()
		TargetPet2_PhysicalStrength_jieduan:Hide()
		TargetPet2_Stability_jieduan:Hide()
	end

	strName = TargetPet : GetStr();
	TargetPet2_Str : SetText( strName - strJinJie );
	TargetPet2_Str : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = TargetPet : GetInt();
	TargetPet2_Nimbus : SetText( tonumber(strName - SprJinJie) );
	TargetPet2_Nimbus : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = TargetPet : GetDex();
	TargetPet2_Dexterity : SetText( tonumber(strName - DexJinJie) );
	TargetPet2_Dexterity : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = TargetPet : GetPF();
	TargetPet2_PhysicalStrength : SetText( tonumber(strName - ConJinJie) );
	TargetPet2_PhysicalStrength : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = TargetPet : GetSta();
	TargetPet2_Stability : SetText( tonumber(strName - IntJinJie) );
	TargetPet2_Stability : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

--	strName = TargetPet : GetBasic();
--	TargetPet2_Basic : SetText( tonumber(strName) );

	strName = TargetPet : GetCriticalAttack();
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(7) + TargetPet:GetPetCangpinEffect(7)
		TargetPet2_CriticalAttack : SetText( strName.."#G(+"..tostring(effectStr)..")"   )
		TargetPet2_CriticalAttack:SetToolTip("#{YSSJ_140818_71}")
		TargetPet2_CriticalAttack_Text:SetToolTip("#{YSSJ_140818_71}")
	else
		TargetPet2_CriticalAttack:SetText( strName )
		TargetPet2_CriticalAttack:SetToolTip("")
		TargetPet2_CriticalAttack_Text:SetToolTip("")
	end

	strName = TargetPet : GetCriticalDefence();
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(8) + TargetPet:GetPetCangpinEffect(8)
		TargetPet2_CriticalDefence : SetText(strName.."#G(+"..tostring(effectStr)..")" )
		TargetPet2_CriticalDefence:SetToolTip("#{YSSJ_140818_72}")
		TargetPet2_CriticalDefence_Text:SetToolTip("#{YSSJ_140818_72}")
	else
		TargetPet2_CriticalDefence : SetText( strName )
		TargetPet2_CriticalDefence:SetToolTip("")
		TargetPet2_CriticalDefence_Text:SetToolTip("")
	end

	strName = TargetPet : GetPotential();
	strName2 = tonumber(strName);
	TargetPet2_Potential : SetText( strName2 );
	TargetPet2_Potential : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = TargetPet : GetPhysicsAttack();
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(1) + TargetPet:GetPetCangpinEffect(1)
		TargetPet2_PhysicsAttack : SetText( strName.."#G(+"..tostring(effectStr)..")" )
		TargetPet2_PhysicsAttack:SetToolTip("#{YSSJ_140818_65}")
		TargetPet2_PhysicsAttack_Text:SetToolTip("#{YSSJ_140818_65}")
	else
		TargetPet2_PhysicsAttack : SetText( strName )
		TargetPet2_PhysicsAttack:SetToolTip("")
		TargetPet2_PhysicsAttack_Text:SetToolTip("")
	end

	strName = TargetPet : GetMagicAttack();
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(2) + TargetPet:GetPetCangpinEffect(2)
		TargetPet2_MagicAttack : SetText( strName.."#G(+"..tostring(effectStr)..")" )
		TargetPet2_MagicAttack:SetToolTip("#{YSSJ_140818_66}")
		TargetPet2_MagicAttack_Text:SetToolTip("#{YSSJ_140818_66}")
	else
		TargetPet2_MagicAttack : SetText( strName )
		TargetPet2_MagicAttack:SetToolTip("")
		TargetPet2_MagicAttack_Text:SetToolTip("")
	end

	strName = TargetPet : GetPhysicsRecovery();
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(3) + TargetPet:GetPetCangpinEffect(3)
		TargetPet2_PhysicsRecovery:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		TargetPet2_PhysicsRecovery:SetToolTip("#{YSSJ_140818_67}")
		TargetPet2_PhysicsRecovery_Text:SetToolTip("#{YSSJ_140818_67}")
	else
		TargetPet2_PhysicsRecovery:SetText( strName)
		TargetPet2_PhysicsRecovery:SetToolTip("")
		TargetPet2_PhysicsRecovery_Text:SetToolTip("")
	end

	strName = TargetPet : GetMagicRecovery ();
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(4) + TargetPet:GetPetCangpinEffect(4)
		TargetPet2_MagicRecovery:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		TargetPet2_MagicRecovery:SetToolTip("#{YSSJ_140818_68}")
		TargetPet2_MagicRecovery_Text:SetToolTip("#{YSSJ_140818_68}")
	else
		TargetPet2_MagicRecovery:SetText( strName )
		TargetPet2_MagicRecovery:SetToolTip("")
		TargetPet2_MagicRecovery_Text:SetToolTip("")
	end

	--闪避率
	strName = TargetPet : GetMiss();
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(5) + TargetPet:GetPetCangpinEffect(5)
		TargetPet2_Miss : SetText( strName.."#G(+"..tostring(effectStr)..")" )
		TargetPet2_Miss:SetToolTip("#{YSSJ_140818_69}")
		TargetPet2_Miss_Text:SetToolTip("#{YSSJ_140818_69}")
	else
		TargetPet2_Miss : SetText( strName )
		TargetPet2_Miss:SetToolTip("")
		TargetPet2_Miss_Text:SetToolTip("")
	end

	--命中率
	strName = TargetPet : GetShootProbability();
	if TargetPet:IsPetMasterEffectActive(0) == 1 or TargetPet:GetPetCangpinEffect(3) > 0 then
		effectStr = TargetPet:GetPetMasterTotalEffect(6) + TargetPet:GetPetCangpinEffect(6)
		TargetPet2_ShootProbability : SetText( strName.."#G(+"..tostring(effectStr)..")"  )
		TargetPet2_ShootProbability:SetToolTip("#{YSSJ_140818_70}")
		TargetPet2_ShootProbability_Text:SetToolTip("#{YSSJ_140818_70}")
	else
		TargetPet2_ShootProbability:SetText( strName)
		TargetPet2_ShootProbability:SetToolTip("")
		TargetPet2_ShootProbability_Text:SetToolTip("")
	end

	local SumPetSkill = GetActionNum("petskill");
	local k=1;

	for i=1, SumPetSkill+TargetPet2SKILL_BUTTONS_NUM do
		local theSkillAction = Pet : EnumPetSkill( 100, i-1, "petskill");
		if( theSkillAction ~= nil and (theSkillAction : GetPetSkillOwner() == 100) and (k <= TargetPet2SKILL_BUTTONS_NUM ) ) then
			TargetPet2SKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID());
			k = k + 1;
		end
	end

	--zchw
	TargetPet2_Refresh_Equip();

	local strNeedLevel;
	local strNeedLevelColor;
	local nIsBaiShou = Pet:GetIsBaiShou()
	local nTakeLevel_BaiShou = nTakeLevel
	if(nIsBaiShou == 1) then
		nTakeLevel_BaiShou = nTakeLevel - 10
	    if nTakeLevel_BaiShou < 1 then
			nTakeLevel_BaiShou = 1
		end
	end
	
	if( nTakeLevel_BaiShou > Player:GetData( "LEVEL" ) )then
		strNeedLevelColor="#cFF0000";
	else
		strNeedLevelColor="#c00FF00";
	end
	strNeedLevel = strNeedLevelColor..tostring( nTakeLevel ).."级#W可携带";

	TargetPet2_NeedLevel : SetText(strNeedLevel)
	local targetIsBaiShou = TargetPet:GetIsBaiShou()
	if (nIsBaiShou == 1) then
		TargetPet2_Proficient_Text : Show()
		TargetPet2_Proficient_Text : SetToolTip("#{BSJT_130114_04}")
	else
		if targetIsBaiShou == 1 then
			TargetPet2_Proficient_Text : Show()
			TargetPet2_Proficient_Text : SetToolTip("#{BSJT_130114_05}")
		else
			TargetPet2_Proficient_Text : Hide()
		end
	end
	--幻灵
	local nHuanlingId = TargetPet : GetPetHuanlingID()
	if nHuanlingId >= 0 then
		local strName = Pet:Lua_GetPetHuanLingInfo(nHuanlingId, "Name")
		local strStyle = Pet:Lua_GetPetHuanLingInfo(nHuanlingId, "ExText")
		TargetPet2_HuanLing : SetText("#{ZSHP_180814_05}")
		TargetPet2_HuanLing : SetToolTip(ScriptGlobal_Format("#{ZSHP_180814_06}", strName, strStyle))
		TargetPet2_HuanLing : Show()
	end
	strName = TargetPet : GetGrowRate();
	TargetPet2_Growth : SetText("#G未知")
	local nGrowLevel = TargetPet : GetPetGrowLevel(tonumber(strName));
	local strTbl = {"普通","优秀","杰出","卓越","完美"};

	if(nGrowLevel >= 0) then
		nGrowLevel = nGrowLevel + 1;	--c里是从0开始的枚举
		local nGrowRate = TargetPet : GetGrowRate();
		if(strTbl[nGrowLevel]) then
			TargetPet2_Growth : SetText("#G"..strTbl[nGrowLevel]..nGrowRate)
		end
	end

	local food = TargetPet : GetFoodType();

	local strFoodName = ""
	local strFoodType = ""

	if(food >= 1000) then
		strFoodName = strFoodName .. g_PetFoodType1[1];
		strFoodType = strFoodType .. g_PetFoodType2[1];
		food = food - 1000;
		if food > 0 then
			strFoodName = strFoodName .. "、";
			strFoodType = strFoodType .. "、";
		end
	end
	if(food >= 100) then
		strFoodName = strFoodName .. g_PetFoodType1[2];
		strFoodType = strFoodType .. g_PetFoodType2[2];
		food = food - 100;
		if food > 0 then
			strFoodName = strFoodName .. "、";
			strFoodType = strFoodType .. "、";
		end
	end
	if(food >= 10) then
		strFoodName = strFoodName .. g_PetFoodType1[3];
		strFoodType = strFoodType .. g_PetFoodType2[3];
		food = food - 10;
		if food > 0 then
			strFoodName = strFoodName .. "、";
			strFoodType = strFoodType .. "、";
		end
	end

	if(food >= 1) then
		strFoodName = strFoodName .. g_PetFoodType1[4];
		strFoodType = strFoodType .. g_PetFoodType2[4];
	end
	local strToShow = "";
	strToShow = ScriptGlobal_Format("#{XSLC_121220_10}", strFoodName, strFoodType)
	TargetPet2Food_Type : Show();
	TargetPet2Food_Type : SetToolTip( strToShow );

	strName,strIcon = TargetPet : GetAttackTrait();


	if strIcon ~= "" then
		TargetPet2Attack_Type : SetProperty( "Image", "set:Button6 image:"..strIcon )
		TargetPet2Attack_Type : SetToolTip(strName)
		TargetPet2Attack_Type : Show();
	end

	TargetPet2_Jian : Show();

end

function TargetPet2_Skill_Button_Clicked(nIndex)
--将来主动技能和被动技能，可以在表里查到。
--	if(nIndex < 3) then

--	end

--	PETSKILL_BUTTONS[nIndex] : DoAction();

--	local SumPetSkill = GetActionNum("petskill");
--	local k=1;
--	for i=1, SumPetSkill do
--		local theSkillAction = EnumAction( i-1, "petskill");
--		if( (theSkillAction : GetPetSkillOwner() == nIndex) and (k <= TargetPet2SKILL_BUTTONS_NUM ) ) then
--			PETSKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID());
--			k = k + 1;
--		end
--	end
end

----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function TargetPet2_Modle_TurnLeft(start)
	--向左旋转开始
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			TargetPet2_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			TargetPet2_FakeObject:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function TargetPet2_Modle_TurnRight(start)
	--向右旋转开始
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			TargetPet2_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			TargetPet2_FakeObject:RotateEnd();
		end
	end
end

function TargetPet2_Jian_Clicked()
	if(not (TargetPet:IsPresent()) ) then
		return;
	end
	Pet:PetOpenPetJian(-1,"target");
end

function TargetPet2_SetStateTooltip( )

	-- 得到状态属性
	local iIceAttack  		= TargetPet : GetAttackCold( nIndex );
	local iFireAttack 		= TargetPet : GetAttackFire( nIndex );
	local iThunderAttack	= TargetPet : GetAttackLight( nIndex );
	local iPoisonAttack		= TargetPet : GetAttackPoison( nIndex );

	local iIceDefine  		= TargetPet : GetDefenceCold( nIndex );
	local iFireDefine 		= TargetPet : GetDefenceFire( nIndex );
	local iThunderDefine	= TargetPet : GetDefenceLight( nIndex );
	local iPoisonDefine		= TargetPet : GetDefencePoison( nIndex );

	local iIceResistOther		= TargetPet : GetResistCold( nIndex );
	local iFireResistOther		= TargetPet : GetResistFire( nIndex );
	local iThunderResistOther	= TargetPet : GetResistLight( nIndex );
	local iPoisonResistOther	= TargetPet : GetResistPoison( nIndex );

	------------------------------
	if( iIceAttack == nil ) then
		iIceAttack = 0;
	end
	if( iFireAttack == nil ) then
		iFireAttack = 0;
	end
	if( iThunderAttack == nil ) then
		iThunderAttack = 0;
	end
	if( iPoisonAttack == nil ) then
		iPoisonAttack = 0;
	end
	------------------------------
	if( iIceDefine == nil ) then
		iIceDefine = 0;
	end

	if( iFireDefine == nil ) then
		iFireDefine = 0;
	end

	if( iPoisonDefine == nil ) then
		iPoisonDefine = 0;
	end
	if( iThunderDefine == nil ) then
		iThunderDefine = 0;
	end
	------------------------------
	if( iIceResistOther == nil ) then
		iIceResistOther = 0;
	end
	if( iFireResistOther == nil ) then
		iFireResistOther = 0;
	end
	if( iThunderResistOther == nil ) then
		iThunderResistOther = 0;
	end
	if( iPoisonResistOther == nil ) then
		iPoisonResistOther = 0;
	end


	Pet2_IceFastness:SetToolTip("冰攻:"..tostring(iIceAttack).."#r冰抗:"..tostring(iIceDefine).."#r减冰抗:"..tostring(iIceResistOther) );
	Pet2_FireFastness:SetToolTip("火攻:"..tostring(iFireAttack).."#r火抗:"..tostring(iFireDefine).."#r减火抗:"..tostring(iFireResistOther) );
	Pet2_ThunderFastness:SetToolTip("玄攻:"..tostring(iThunderAttack).."#r玄抗:"..tostring(iThunderDefine).."#r减玄抗:"..tostring(iThunderResistOther) );
	Pet2_PoisonFastness:SetToolTip("毒攻:"..tostring(iPoisonAttack).."#r毒抗:"..tostring(iPoisonDefine).."#r减毒抗:"..tostring(iPoisonResistOther) );

end

function TargetPet2_ClearStateTooltip()
	-- 得到状态属性
	local iIceAttack  		= 0;
	local iFireAttack 		= 0;
	local iThunderAttack	= 0;
	local iPoisonAttack		= 0;

	local iIceDefine  		= 0;
	local iFireDefine 		= 0;
	local iThunderDefine	= 0;
	local iPoisonDefine		= 0;

	local iIceResistOther		= 0;
	local iFireResistOther		= 0;
	local iThunderResistOther	= 0;
	local iPoisonResistOther	= 0;

	Pet2_IceFastness:SetToolTip("冰攻:"..tostring(iIceAttack).."#r冰抗:"..tostring(iIceDefine).."#r减冰抗:"..tostring(iIceResistOther) );
	Pet2_FireFastness:SetToolTip("火攻:"..tostring(iFireAttack).."#r火抗:"..tostring(iFireDefine).."#r减火抗:"..tostring(iFireResistOther) );
	Pet2_ThunderFastness:SetToolTip("玄攻:"..tostring(iThunderAttack).."#r玄抗:"..tostring(iThunderDefine).."#r减玄抗:"..tostring(iThunderResistOther) );
	Pet2_PoisonFastness:SetToolTip("毒攻:"..tostring(iPoisonAttack).."#r毒抗:"..tostring(iPoisonDefine).."#r减毒抗:"..tostring(iPoisonResistOther) );

end
