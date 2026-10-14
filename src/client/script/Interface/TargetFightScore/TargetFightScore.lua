
local g_setting = {}
local g_data = {}
local g_fixchain = {}

g_setting["MainTypeData"] = {
--	标题(string), 图标(string),开放等级(number)
	{ "#{PFZY_140613_03}", "set:Shoulder2 image:Shoulder2_16", 0, 1 },	--装备
	{ "#{PFZY_140613_04}", "set:Gem6_2 image:Gem6_2_2", 0, 1 },	--宝石
	{ "#{PFZY_140613_05}", "set:CircularTaskTool47 image:CircularTaskTool47_12", 0, 1 },	--强化
	{ "#{PFZY_140613_06}", "set:Fabao image:Fabao_1", 0, 1 },	--暗器
	{ "#{PFZY_140613_175}", "set:SMWD_Icon image:SMWD_Icon_9", 0, 0 },	--神鼎
	{ "#{PFZY_140613_07}", "set:Charm5 image:Charm5_8", 0, 1 },	--资质
	{ "#{PFZY_140613_08}", "set:Charm3 image:Charm3_2", 0, 1 },	--刻铭
	{ "#{PFZY_140613_09}", "set:FightSkillXinShou image:FightSkillXinShou_11", 0, 1 },	--附体
	{ "#{PFZY_140613_10}", "set:Tattoo image:Tattoo_13", 0, 1 },	--雕纹
	{ "#{PFZY_140613_11}", "set:IMShow image:IMShow_13", 0, 1 },	--子女
	{ "#{PFZY_140613_12}", "set:Fabao image:Fabao_4", 0, 1 },	--武魂
	{ "#{PFZY_140613_13}", "set:CircularTaskTool33 image:CircularTaskTool33_6", 0, 0 },	--龙纹
	{ "#{PFZY_140613_14}", "set:CircularTaskTool49 image:CircularTaskTool49_6", 0, 0 },	--精通
	{ "#{PFZY_140613_15}", "set:ZhenYuan1 image:ZhenYuan1_15", 0, 1 },	--真元
	{ "#{PFZY_140613_16}", "set:EquipLingPai image:EquipLingPai_5", 0, 1 },	--令牌
	{ "#{PFZY_140613_220}", "set:HaoXiaYin image:HaoXiaYin_8", 0, 0}, --豪侠印
	{ "#gFF0FA0武意","set:Ach_Icon image:Ach_Icon_14",85, 0},--武意
	{"#{PFZY_200424_01}", "set:Rune01 image:Rune01_8", 75, 0},--无字谱
	{"#{PFZY_220915_01}", "set:Armor1 image:Armor1_6", 85, 0},--星盘
	{"#{PFZY_230830_01}", "set:ZongMenToken2 image:ZongMenToken2_14", 0, 1},--宗门装备
}

local ZhenYuan2Equip = {7,6,11,14,12,13,2,5,3,4,1,15} --真元装备位顺序

g_setting["EquipBasicInfo"] = {
	{ back="set:UIIcons image:Equip_Weapon",index=0,name="#{PFZY_140613_20}",gemConIndex=0, level = 0 },    --武器
	{ back="set:UIIcons image:Equip_Cap",index=1,name="#{PFZY_140613_21}",gemConIndex=1, level = 0, ZhenYuanIndex = 10 },       --帽子
	{ back="set:UIIcons image:Equip_Sash",index=5,name="#{PFZY_140613_22}",gemConIndex=5, level = 0, ZhenYuanIndex = 7 },      --腰带
	{ back="set:UIIcons image:Equip_Shot",index=4,name="#{PFZY_140613_23}",gemConIndex=4, level = 0, ZhenYuanIndex = 9 },      --鞋
	{ back="set:UIIcons image:Equip_Ring",index=6,name="#{PFZY_140613_24}",gemConIndex=6, level = 0, ZhenYuanIndex = 1 },	     --戒指1
	{ back="set:UIIcons image:Equip_Ring",index=11,name="#{PFZY_140613_25}",gemConIndex=8, level = 0, ZhenYuanIndex = 2 },     --戒指2
	{ back="set:UIIcons image:Equip_Pifeng",index=12,name="#{PFZY_140613_26}",gemConIndex=9, level = 0, ZhenYuanIndex = 4 },   --护符1
	{ back="set:UIIcons image:Equip_Pifeng",index=13,name="#{PFZY_140613_27}",gemConIndex=10, level = 0, ZhenYuanIndex = 5 },  --护符2
	{ back="set:UIIcons image:Equip_Wrist",index=14,name="#{PFZY_140613_28}",gemConIndex=11, level = 0, ZhenYuanIndex = 3 },   --护腕
	{ back="set:UIIcons image:Equip_Hand",index=3,name="#{PFZY_140613_29}",gemConIndex=3, level = 0, ZhenYuanIndex = 8 },     --手套
	{ back="set:UIIcons image:Equip_Nacket",index=7,name="#{PFZY_140613_30}",gemConIndex=7, level = 0, ZhenYuanIndex = 0 },   --项链
	{ back="set:UIIcons image:Equip_Armo",index=2,name="#{PFZY_140613_31}",gemConIndex=2, level = 0, ZhenYuanIndex = 6 },     --衣服
	{ back="set:UIIcons image:Equip_Shoulder",index=15,name="#{PFZY_140613_32}",gemConIndex=12, level = 0, ZhenYuanIndex = 11 }, -- 护肩
	{ back="set:UIIcons image:Equip_Anqi",index=17,name="#{PFZY_140613_33}",gemConIndex=13, level = 30 },     --暗器
	{ back="set:CommonFrame7 image:WuhunEquip",index=18,name="#{PFZY_140613_34}",gemConIndex=14, level = 65, testMaster = true, back2= {"set:Fabao image:Fabao_4","set:Fabao image:Fabao_5" } },--武魂
	{ back="set:MiniMap image:LongWen",index=19,name="#{PFZY_140613_35}",gemConIndex=15, level = 80, testMaster = true, back2= "set:CircularTaskTool33 image:CircularTaskTool33_6"   },        --龙纹
	{ back="set:UIIcons image:Equip_LingPai",index=20,name="#{PFZY_140613_36}",gemConIndex=16, level = 80,back2="set:EquipLingPai image:EquipLingPai_5" },  --令牌
	{ back="set:JunXian_04 image:JunXian_Equip",index=21,name="#{HXYSJ_141031_21}",gemConIndex=17, level = 85,back2="set:HaoXiaYin image:HaoXiaYin_8" },  --侠印
--	{ back="set:ZongMenSkill image:ZongMenSkill_ItemBK",index=23,name="#{PFZY_230830_17}",gemConIndex=18, level = 60,back2="set:ZongMenToken2 image:ZongMenToken2_14" },  --宗门装备
}

g_setting["ZiZhiRateInfo"] = {
	{ rate=1,str="#{GMItem_Equip_22}"},	--	普通
	{ rate=64,str="#{GMItem_Equip_21}"},	--	中等
	{ rate=126,str="#{GMItem_Equip_20}"},	--	优秀
	{ rate=189,str="#{GMItem_Equip_19}"},	--	完美
}


g_setting["ColorRed"] = "#cFF0000"
g_setting["ColorGreen"] = "#G"

g_data["CompareState"] = 1
g_data["CurrentMainType"] = 1
g_data["LeftItems"] = {}
g_data["RightItems"] = {}
g_data["ButtonIndexMap"] = {}

local g_LYProType = {"#{AQJJ_160127_147}","#{AQJJ_160127_148}","#{AQJJ_160127_149}","#{AQJJ_160127_150}"}

local g_EquipMax = 18

local g_TargetFightScore_2606SValid = { -- 开启功能配置
	[1] = 1, -- 装备 Equip
	[2] = 1, -- 宝石 Gem
	[3] = 1, -- 强化 Strength
	[4] = 1, -- 暗器 Dark
	[5] = 0, -- 神木王鼎，神鼎，SMWD
	[6] = 1, -- 资质 ZiZhi
	[7] = 1, -- 刻铭 KeMing
	[8] = 1, -- 附体 FuTi
	[9] = 1, -- 雕纹 DiaoWen
	[10] = 1, -- 子女 Infant
	[11] = 1, -- 武魂 WuHun
	[12] = 0, -- 龙纹 LongWen
	[13] = 0, -- 精通 JingTong
	[14] = 1, -- 真元 ZhenYuan
	[15] = 1, -- 令牌 LingPai
	[16] = 0, -- 侠印 XiaYin
	[17] = 0, -- 武意 Material
	[18] = 0, -- 无字谱 xingzhen
	[19] = 0, -- 星盘 UnderArmour
	[20] = 1, -- 秘宝 ZongMen
}

function TargetFightScore_PreLoad()
	this:RegisterEvent("TARGETEQUIP_FIGHTSCORE_SHOW")
	this:RegisterEvent("TARGETEQUIP_FIGHTSCORE_DATA")
	this:RegisterEvent("REFRESH_EQUIP")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("CLOSE_TARGET_EQUIP")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("OTHERPLAYER_UPDATE_EQUIP")
	this:RegisterEvent("OTHERPLAYER_UPDATE_COMPAREEQUIP")
end

function TargetFightScore_OnLoad()
	g_setting["sdMap"] = {}
	local sdStage,sdStep = 1, 1
	for i=1,45 do
		table.insert(g_setting.sdMap,{sdStage,sdStep})
		if sdStep == sdStage then
			sdStage = sdStage + 1
			sdStep = 1
		else
			sdStep = sdStep + 1
		end
	end
	g_data["LeftFrame"] = TargetFightScore_Charts
	g_data["DetailFrame"] = TargetFightScore_Detail
	g_data["CompareDetailFrame"] = TargetFightScore_CompareDetail
	g_data["RightFrame"] = TargetFightScore_Frame
	g_data["RightSubTitle"] = TargetFightScore_Right_TargetTitle
	g_data["RightSubTitle2"] = TargetFightScore_Right_OwnTitle
	g_data["pos"]  = TargetFightScore_Frame:GetProperty("UnifiedPosition")
end

local g_objCared = -1

function TargetFightScore_OnEvent(event)
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		if TargetFightScore_Frame:IsVisible() then
			TargetFightScore_Frame:Hide()
			TargetFightScore_Frame:SetProperty("UnifiedPosition", g_data.pos)
			TargetFightScore_Frame:Show()
		end
	elseif event == "TARGETEQUIP_FIGHTSCORE_SHOW" then
		TargetFightScore_BeginCareObject( CachedTarget:GetData("NPCID", 1) )
		TargetFightScore_ShowTarget()
	elseif event == "OTHERPLAYER_UPDATE_COMPAREEQUIP" then
		Target:Close_Before_TargetEquip_UI();
		if not CachedTarget:IsPresent(1) then
			return;
		end
		if not CachedTarget:CanGetTargetEquip() then
			PushDebugMessage ("#{JSCK_90507_1}")
			return
		end
		TargetFightScore_BeginCareObject( CachedTarget:GetData("NPCID", 1) )
		if type(g_objCared) ~="number" then
			PushDebugMessage ("#{JSCK_90507_1}")
			return
		end
		TargetFightScore_ShowTarget()
	elseif event == "REFRESH_EQUIP" and this:IsVisible() == 1 then
		TargetFightScore_UpdateRightList()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		TargetFightScore_Close()
	elseif event == "OBJECT_CARED_EVENT" then
		if(tonumber(arg0) ~= g_objCared) then
			return;
		end
		if( arg1=="destroy") then
			TargetFightScore_Close()
			return;
		end
	end
end

function TargetFightScore_BeginCareObject( objCaredId )
	if type(objCaredId) == "number" then
		g_objCared = objCaredId;
		this:CareObject( g_objCared, 1, "TargetFightScore" )
	end
end

function TargetFightScore_StopCareObject()
	this:CareObject( g_objCared, 0, "TargetFightScore" )
	g_objCared = -1;
end

function TargetFightScore_Close()
	TargetFightScore_StopCareObject()
	g_data.CompareState = 1
	g_data.CurrentMainType = 1
	g_data.LeftItems = {}
	g_data.ButtonIndexMap = {}
	TargetFightScore_CleanUpRightItems()
	this:Hide()
end

function TargetFightScore_GetWindowWidth( sizestr )
	local s1,s2
	s1 = string.find( sizestr, "," )
	if s1 then
		s2 = string.find( sizestr, "}", s1 )
	end
	if s1 and s2 then
		return tonumber( string.sub( sizestr, s1 + 1, s2 - 1 ) )
	end
	return nil
end

function TargetFightScore_UpdateSelected()
	for i,v in g_data.LeftItems do
		if g_data.ButtonIndexMap[i] == g_data.CurrentMainType then
			v:SetBarButtonSelected(true)
		else
			v:SetBarButtonSelected(false)
		end
	end
end

local TargetFightScore_GetAttackType,TargetFightScore_GetTargetAttackType = (function()
	local attack_type_table = {
		[0]		= 1,	--少林
		[1]		= 1,	--明教
		[2]		= 1,	--丐帮
		[3]		= 2,	--武当
		[4]		= 2,	--峨眉
		[5]		= 2,	--星宿
		[6]		= 2,	--天龙
		[7]		= 1,	--天山
		[8]		= 2,	--逍遥
		[9]		= 0,	--无门派
		[10]	= 2,	--慕容
		[11]	= 1,	--唐门
	}
	return function()
		return attack_type_table[Player:GetData('MEMPAI')] or 0
	end,
	function()
		return attack_type_table[CachedTarget:GetData('MEMPAI')] or 0
	end
end)()

function TargetFightScore_ReplaceWidth( sizestr, newwidth )
	local s1,s2
	s1 = string.find( sizestr, "," )
	if s1 then
		s2 = string.find( sizestr, "}", s1 )
	end
	if s1 and s2 then
		return string.format( "%s%d%s",string.sub( sizestr, 1, s1 ), newwidth, string.sub( sizestr, s2 )  )
	else
		return sizestr
	end
end

function TargetFightScore_ShowTarget()
	TargetFightScore_UpdateTitleName()
	TargetFightScore_UpdateLeftList()
	TargetFightScore_UpdateSelected()
	TargetFightScore_UpdateRightList()
	this:Show()
end

function TargetFightScore_ShowCompare()
	g_data.CompareState = 1 - g_data.CompareState
	TargetFightScore_UpdateRightList()
end

function TargetFightScore_UpdateTitleName()
	TargetFightScore_Title:SetText( "#{PFBJ_160106_3}" )
end

function TargetFightScore_AddLeftItem(sTitle, sSubTitle, strIcon)
	local ItemBar = TargetFightScore_Charts:AddItemElement( "FightScoreCompare", "LEFT", "TargetFightScore","" ,"")
	if ItemBar == nil then
		return nil
	end
	ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
	ItemBar:SetAchvGetedHide()
	ItemBar:SetAchievementBarIconDisImageHide()
	ItemBar:SetAchievementBarPointDisImageHide()
	ItemBar:SetAchievementBarPointImageHide()
	ItemBar:SetAchvGetHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarDateHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarProgressNameHide()
	if strIcon ~= nil and strIcon ~= "" then
		local sPos,_ = string.find(strIcon," ");
		local IconImageSet = string.sub(strIcon,5,sPos-1);
		local IconIamge = string.sub(strIcon,sPos+7)
		if nil ~= IconImageSet and nil ~= IconIamge then
			ItemBar:AddBarIconImage(IconImageSet,IconIamge)
		end
	end
	if sTitle ~= nil then
		ItemBar:AddBarText(sTitle)
	end
	return ItemBar
end

function TargetFightScore_UpdateLeftList()
	this:Show()
	g_data.LeftItems = {}
	TargetFightScore_Charts:CleanAllElement("TargetFightScore")

	local sTitle, sSubTitle, strIcon, Score = "#{PFZY_140613_03}", nil, "set:Shoulder2 image:Shoulder2_16", 1

	for i,v in g_setting.MainTypeData do
		local iconname = v[2]
		if i == 11 then
			local menpaiID = CachedTarget:GetData("MEMPAI")
			--menpai15
			if menpaiID==0 or menpaiID==7 or menpaiID==2 or menpaiID==1 or menpaiID == 14 or menpaiID == 13 then --少林、天山、丐帮、明教
				iconname="set:Fabao image:Fabao_4"
			else
				iconname="set:Fabao image:Fabao_5"
			end
		end
		
		local addFlag = 1
		if Player:GetData("Is2606S") == 1 then
			addFlag = v[4]
		end
		if addFlag == 1 then
			table.insert(g_data.LeftItems, TargetFightScore_AddLeftItem( v[1], nil, iconname ))
			table.insert(g_data.ButtonIndexMap, i)
		end
	end
	TargetFightScore_Charts:Flash()
	TargetFightScore_Charts:SetElementsInView(1)
end

function TargetFightScore_UpdateRightList()
	local pos = g_data.LeftFrame:GetVertScrollbarPosition()
	g_data.LeftFrame:SetVertScrollbarPosition(0)
	TargetFightScore_CleanUpRightItems()
	if g_data.CompareState == 0 then
		g_data.DetailFrame:Show()
		g_data.CompareDetailFrame:Hide()
		g_data.RightSubTitle2:Hide()
	else
		g_data.DetailFrame:Hide()
		g_data.CompareDetailFrame:Show()
		g_data.RightSubTitle2:Show()
	end
	g_data.LeftFrame:SetVertScrollbarPosition(pos)
	
	TargetFightScore_Right_TargetHead:SetProperty("Image", Target:GetData("PORTRAIT") )
	TargetFightScore_Right_TargetName:SetText("#cfff263"..CachedTarget:GetData("NAME"))
	TargetFightScore_Right_TargetFenShu:SetText("#{PFBJ_160106_88}"..CachedTarget:GetData("BATTLESCORE",1))
	TargetFightScore_Right_Targethistory:SetText("#{PFBJ_160106_89}"..CachedTarget:GetData("EQUIPSCOREHH"))
	TargetFightScore_Right_OwnHead:SetProperty("Image", Player:GetData( "PORTRAIT" ) )
	TargetFightScore_Right_OwnName:SetText("#cfff263"..Player:GetName())
	TargetFightScore_Right_OwnFenShu:SetText("#{PFBJ_160106_88}"..Player:GetData("BATTLESCORE"))
	TargetFightScore_Right_Ownhistory:SetText("#{PFBJ_160106_89}"..Player:GetData("EQUIPSCOREHH"))

	if g_data.CurrentMainType == 1 then
		TargetFightScore_UpdateRightEquip()
	elseif g_data.CurrentMainType == 2 then
		TargetFightScore_UpdateRightGem()
	elseif g_data.CurrentMainType == 3 then
		TargetFightScore_UpdateRightEnhance()
	elseif g_data.CurrentMainType == 4 then
		TargetFightScore_UpdateRightAnqi()
	elseif g_data.CurrentMainType == 5 then
		TargetFightScore_UpdateRightShenDing()
	elseif g_data.CurrentMainType == 6 then
		TargetFightScore_UpdateRightZiZhi()
	elseif g_data.CurrentMainType == 7 then
		TargetFightScore_UpdateRightKeMing()
	elseif g_data.CurrentMainType == 8 then
		TargetFightScore_UpdateRightFuti()
	elseif g_data.CurrentMainType == 9 then
		TargetFightScore_UpdateRightDiaowen()
	elseif g_data.CurrentMainType == 10 then
		TargetFightScore_UpdateRightInfant()
	elseif g_data.CurrentMainType == 11 then
		TargetFightScore_UpdateRightWuhun()
	elseif g_data.CurrentMainType == 12 then
		TargetFightScore_UpdateRightLongWen()
	elseif g_data.CurrentMainType == 13 then
		TargetFightScore_UpdateRightJingTong()
	elseif g_data.CurrentMainType == 14 then
		TargetFightScore_UpdateRightZhenYuan()
	elseif g_data.CurrentMainType == 15 then
		TargetFightScore_UpdateRightLingPai()
	elseif g_data.CurrentMainType == 16 then
		TargetFightScore_UpdateRightXiaYin()
	elseif g_data.CurrentMainType == 17 then
		TargetFightScore_UpdateRightMartial()
	elseif g_data.CurrentMainType == 18 then
		TargetFightScore_UpdateRightXingZhen()
	elseif g_data.CurrentMainType == 19 then
		TargetFightScore_UpdateRightUnderArmour()
	elseif g_data.CurrentMainType == 20 then
		TargetFightScore_UpdateRightZongMenEquip()
	end
end

function TargetFightScore_OnLeftItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1
	if nIndex < 0 or not g_data.ButtonIndexMap[nIndex] then
		return
	end
	g_data.CurrentMainType = g_data.ButtonIndexMap[nIndex]
	TargetFightScore_UpdateSelected()
	TargetFightScore_CleanUpRightItems()
	TargetFightScore_UpdateRightList()
end

function TargetFightScore_NewRightItem()
	local ItemBar = nil
	if 	g_data.CompareState == 0 then
		ItemBar = g_data.DetailFrame:AddItemElement( "FightScoreCompareDetail", "LEFT", "TargetFightScore","" ,"")
	else
		ItemBar = g_data.CompareDetailFrame:AddItemElement( "FightScoreCompareBar", "LEFT", "TargetFightScore","" ,"")
	end
	if ItemBar == nil then
		return nil
	end
	ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
	--先隐藏掉图片
	ItemBar:SetAchvGetedHide()
	ItemBar:SetAchievementBarIconDisImageHide()
	ItemBar:SetAchievementBarPointDisImageHide()
	ItemBar:SetAchievementBarPointImageHide()
	ItemBar:SetAchvGetHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarDateHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarProgressNameHide()
	for i = 1, 10 do
		nChildSlot = ItemBar:GetLuaActionButton(i,"TargetFightScore")
		if nChildSlot ~= nil then
			nChildSlot:Hide()
		end
	end
	for j=1,16 do
		ItemBar:Setm_newImageHide(j)
	end
	return ItemBar
end

function TargetFightScore_MakeEquipStr( actionItem, actionItemToCmp, nPos, hascmp )
	local LevelStr,QualStr, nAttrStr = "","",""
	
	local EquipLevel = actionItem:GetEquipLevel()
	if not EquipLevel or EquipLevel < 1 then
		EquipLevel = 1
	end
	LevelStr = g_setting.ColorGreen..EquipLevel
	if hascmp == 1 and actionItemToCmp:GetID() > 0 then
		local EquipLevel2 = actionItemToCmp:GetEquipLevel()
		if EquipLevel2 and EquipLevel < EquipLevel2 then
			LevelStr = g_setting.ColorRed..EquipLevel
		end
	end
	
	local EquipQual = actionItem:GetEquipQuality()
	if EquipQual and EquipQual>100 then
		EquipQual = 8
	elseif EquipQual and EquipQual > 10 then
		EquipQual = math.floor(EquipQual/10)
	end
	if EquipQual and EquipQual < 0 then
		EquipQual = 0
	end
	QualStr = g_setting.ColorGreen..EquipQual
	if hascmp == 1 and actionItemToCmp:GetID() > 0 then
		local EquipQual2 = actionItemToCmp:GetEquipQuality()
		if EquipQual2 and EquipQual2>100 then
			EquipQual2 = 8
		elseif EquipQual2 and EquipQual2 > 10 then
			EquipQual2 = math.floor(EquipQual2/10)
		end
		if EquipQual2 and EquipQual2 < 0 then
			EquipQual2 = 0
		end
		if EquipQual2 and EquipQual < EquipQual2 then
			QualStr = g_setting.ColorRed..EquipQual
		end
	end
	
	local EquipAttrNum = actionItem:GetEquipAttrCount()
	if not EquipAttrNum or EquipAttrNum < 0 then
		EquipAttrNum = 0
	end
	nAttrStr = g_setting.ColorGreen..EquipAttrNum
	if hascmp == 1 and actionItemToCmp:GetID() > 0 then
		local EquipAttrNum2 = actionItemToCmp:GetEquipAttrCount()
		if EquipAttrNum2 and EquipAttrNum < EquipAttrNum2 then
			nAttrStr = g_setting.ColorRed..EquipAttrNum
		end
	end
	
	local isSuperWeapon = actionItem:GetEquipIsSuperWeapon()
	local isSuperWeapon9 = DataPool:IsSuperWeapon9()
	if nPos == 0 and ((isSuperWeapon and isSuperWeapon == 1) or isSuperWeapon9 == 1) then
		return ScriptGlobal_Format("#{PFZY_140613_60}", LevelStr, QualStr )
	else
		return ScriptGlobal_Format("#{PFZY_140613_62}", LevelStr, QualStr, nAttrStr )
	end
end

function TargetFightScore_NewTargetEquipItem( actionItem, actionItemMy, nImageListIndex )
	local ItemBar = TargetFightScore_NewRightItem()
	local nPos = g_setting.EquipBasicInfo[nImageListIndex].index
	local levelTar,levelMy = CachedTarget:GetData("LEVEL"), Player:GetLevel()
	local hasEm1,hasEm2 = CachedTarget:GetEquipMasterFlag(), CachedTarget:GetMySelfEquipMasterFlag()
	local itemButton1, itemButton2 = ItemBar:GetLuaActionButton( 1, "TargetFightScore" ), nil
	
	itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
	local actionId1, actionId2, StrContent1, StrContent2 = actionItem:GetID(), nil, "", ""
	if g_data.CompareState == 1 then
		itemButton2 = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
		itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
		actionId2 = actionItemMy:GetID()
	end
	
	local limitLevel, limitLevel2, testMaster, partName = 
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].testMaster,
		g_setting.EquipBasicInfo[nImageListIndex].name
	
	if hasEm1 == 1 and testMaster then
		limitLevel = limitLevel - 10
	end
	if hasEm2 == 1 and testMaster then
		limitLevel2 = limitLevel2 - 10
	end

	if actionId1 > 0 then
		itemButton1:SetActionItem(actionId1)
		StrContent1 = TargetFightScore_MakeEquipStr( actionItem, actionItemMy, nPos, g_data.CompareState  )
	elseif levelTar < limitLevel then
		StrContent1 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel )
		itemButton1:SetToolTip( ScriptGlobal_Format("#{PFZY_140613_39}", partName ) )
	else
		StrContent1 = ScriptGlobal_Format( "#{PFZY_140613_54}", g_setting.EquipBasicInfo[nImageListIndex].name )
		itemButton1:SetToolTip( ScriptGlobal_Format("#{PFZY_140613_39}", partName ) )
	end
	itemButton1:Show()
	ItemBar:Setm_newText(1, StrContent1)
	ItemBar:Setm_newTextShow(1)
	
	if g_data.CompareState == 1 then
		if actionId2 > 0 then
			itemButton2:SetActionItem(actionId2)
			StrContent2 = TargetFightScore_MakeEquipStr( actionItemMy, actionItem, nPos, g_data.CompareState )
		elseif levelMy < limitLevel2 then
			StrContent2 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel2 )
			itemButton2:SetToolTip( ScriptGlobal_Format("#{PFZY_140613_39}", partName ) )
		else
			StrContent2 = ScriptGlobal_Format("#{PFZY_140613_54}", partName)
			itemButton2:SetToolTip( ScriptGlobal_Format("#{PFZY_140613_39}", partName ) )
		end
		itemButton2:Show()
		ItemBar:Setm_newText(22, StrContent2)
		ItemBar:Setm_newTextShow(22)
	end
	
	table.insert( g_data.RightItems, ItemBar )
end

function TargetFightScore_AddGenericItem1( ItemBar, strBackImage, bActionItem, itemID, strText, strToolTips )
	if not ItemBar then
		return nil
	end
	local ItemButton  = ItemBar:GetLuaActionButton(1,"TargetFightScore")
	if ItemButton == nil then
		return ItemBar
	end
	ItemButton:SetProperty("BackImage", strBackImage)
	local nActionID = -1
	--	设置ActionButton
	if bActionItem > 0 then
		local nListIndex = table.getn(g_data.RightItems)
		oActionItem = LifeAbility:CreateVirtualActionItem(itemID, nListIndex)
		nActionID = oActionItem:GetID()
	else
		nActionID = itemID
	end
	ItemButton:SetActionItem(nActionID)
	if strToolTips ~= "" then
		ItemButton:SetToolTip(strToolTips)
	end
	ItemButton:Show()
	ItemBar:Setm_newText(1, strText)
	ItemBar:Setm_newTextShow(1)
	return ItemBar
end

function TargetFightScore_AddGenericItem2( ItemBar, strBackImage, bActionItem, itemID, strText, strToolTips )
	if not ItemBar then
		return
	end
	local ItemButton  = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
	if ItemButton == nil then
		return ItemBar
	end
	ItemButton:SetProperty("BackImage", strBackImage)
	local nActionID = -1
	--	设置ActionButton
	if bActionItem > 0 then
		local nListIndex = table.getn(g_data.RightItems)
		oActionItem = LifeAbility:CreateVirtualActionItem(itemID, nListIndex)
		nActionID = oActionItem:GetID()
	else
		nActionID = itemID
	end
	ItemButton:SetActionItem(nActionID)
	if strToolTips ~= "" then
		ItemButton:SetToolTip(strToolTips)
	end
	ItemButton:Show()
	ItemBar:Setm_newText(22, strText)
	ItemBar:Setm_newTextShow(22)
	return ItemBar
end

function TargetFightScore_NewGenericItem( strBackImage, bActionItem, itemID, strText, strToolTips )
	local ItemBar = TargetFightScore_NewRightItem()
	if ItemBar == nil then
		return nil
	end
	table.insert(g_data.RightItems, ItemBar)
	return TargetFightScore_AddGenericItem1( ItemBar, strBackImage, bActionItem, itemID, strText, strToolTips )
end

function TargetFightScore_CleanUpRightItems()
	for i = 1, table.getn(g_data.RightItems) do
		if nil ~= g_data.RightItems[i] then
			for j = 1, 10 do
				local itemButton = g_data.RightItems[i]:GetLuaActionButton(j,"TargetFightScore")
				if nil ~= itemButton then
					itemButton:SetActionItem(-1)
				end
			end
		end
	end
	g_data.RightItems = {}
	g_data.DetailFrame:CleanAllElement("TargetFightScore")
	g_data.CompareDetailFrame:CleanAllElement("TargetFightScore")
end

function TargetFightScore_FlashRight()
	if 	g_data.CompareState == 0 then
		g_data.DetailFrame:Flash()
	else
		g_data.CompareDetailFrame:Flash()
	end
end

function TargetFightScore_UpdateRightEquip()
	for i=1,13 do
		local tempEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "targetequip" )
		local tempMyEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "equip" )
		TargetFightScore_NewTargetEquipItem( tempEquip, tempMyEquip, i )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_UpdateRightGem()
	for i=1, g_EquipMax do
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_TargetFightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_TargetFightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end
		local tempEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "targetequip" )
		local tempMyEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "equip" )
		TargetFightScore_NewTargetGemItem( tempEquip, tempMyEquip, i )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_NewTargetGemItem( actionItem, actionItemMy, nImageListIndex )
	local ItemBar = TargetFightScore_NewRightItem()
	local nPos = g_setting.EquipBasicInfo[nImageListIndex].index
	local levelTar,levelMy = CachedTarget:GetData("LEVEL"), Player:GetLevel()
	local hasEm1,hasEm2 = CachedTarget:GetEquipMasterFlag(), CachedTarget:GetMySelfEquipMasterFlag()
	local itemButton1, itemButton2 = ItemBar:GetLuaActionButton( 1, "TargetFightScore" ), nil
	
	itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
	local actionId1, actionId2, StrContent1, StrContent2 = actionItem:GetID(), nil, "", ""
	if g_data.CompareState == 1 then
		itemButton2 = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
		itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
		actionId2 = actionItemMy:GetID()
	end
	
	local limitLevel, limitLevel2, testMaster, partName = 
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].testMaster,
		g_setting.EquipBasicInfo[nImageListIndex].name
		
	if hasEm1 == 1 and testMaster then
		limitLevel = limitLevel - 10
	end
	if hasEm2 == 1 and testMaster then
		limitLevel2 = limitLevel2 - 10
	end
	
	itemButton1:Show()
	if actionId1 > 0 then
		itemButton1:SetActionItem(actionId1)
		local g1,g2,g3,g4 = actionItem:GetEquipGemInfo()
		local gems = { g1,g2,g3,g4 }
		local gems2 = { -1, -1, -1, -1 }
		if g_data.CompareState == 1 and actionId2 > 0 then
			local g21,g22,g23,g24 = actionItemMy:GetEquipGemInfo()
			gems2 = { g21,g22,g23,g24 }
		end
		for i,v in gems do
			local gemButton = ItemBar:GetLuaActionButton(i+1,"TargetFightScore")
			if gemButton ~= nil then
				if not v or v < 0 then
					if 1 == SystemSetup:IsClassic() then
						gemButton:SetProperty("BackImage", "set:Agname3 image:BaoShiCheckFeng")
					else
						gemButton:SetProperty("BackImage", "set:WM_CommonFrame1 image:Feng")
					end
					gemButton:SetActionItem(-1)
					gemButton:SetToolTip("#{PFZY_140613_38}")
				elseif v == 0 then
					gemButton:SetActionItem(-1)
					gemButton:SetProperty("BackImage", "set:CommonItem image:ActionBK")
					gemButton:SetToolTip("#{PFZY_140613_37}")
				else
					local nGemAction = LifeAbility:CreateVirtualActionItem( v, (g_setting.EquipBasicInfo[nImageListIndex].index*8) + i - 1 );
					if nGemAction ~= nil then
						gemButton:SetActionItem(nGemAction:GetID())
						if DataPool:GetGemScore_FromGemTableIndex( gems2[i] ) > DataPool:GetGemScore_FromGemTableIndex( v ) then
							nGemAction:SetSelectStatus(0)
							ItemBar:Setm_newImage(6+i,"Face_04", "Remind3_Bak")
							ItemBar:Setm_newImageShow(6+i)
						else
							ItemBar:Setm_newImageHide(6+i)
							nGemAction:SetSelectStatus(1)
						end
					end
				end
				gemButton:Show()
			end
		end
	elseif levelTar < limitLevel then
		local StrContent1 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel )
		itemButton1:SetToolTip( StrContent1 )
		local bk2 = g_setting.EquipBasicInfo[nImageListIndex].back2
		if type(bk2) == "string" then
			itemButton1:SetProperty( "BackImage", bk2 )
		elseif type(bk2) == "table" then
			itemButton1:SetProperty( "BackImage", bk2[TargetFightScore_GetTargetAttackType()] )
		end
		ItemBar:Setm_newText(1, StrContent1 )
		ItemBar:Setm_newTextShow(1)
	else
		local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", g_setting.EquipBasicInfo[nImageListIndex].name)
		local strNoEquipText = "#cFF0000"..strNoEquipToolTips
		itemButton1:SetToolTip(strNoEquipToolTips)
		ItemBar:Setm_newText(1, strNoEquipText)
		ItemBar:Setm_newTextShow(1)
	end
	
	if g_data.CompareState == 1 then
		if actionId2 > 0 then
			itemButton2:SetActionItem(actionId2)
			local g1,g2,g3,g4 = actionItemMy:GetEquipGemInfo()
			local gems = { g1,g2,g3,g4 }
			local gems2 = { -1, -1, -1, -1 }
			if g_data.CompareState == 1 and actionId1> 0 then
				local g21,g22,g23,g24 = actionItem:GetEquipGemInfo()
				gems2 = { g21,g22,g23,g24 }
			end
			for i,v in gems do
				local gemButton = ItemBar:GetLuaActionButton(i+6,"TargetFightScore")
				if gemButton ~= nil then
					if not v or v < 0 then
						if 1 == SystemSetup:IsClassic() then
							gemButton:SetProperty("BackImage", "set:Agname3 image:BaoShiCheckFeng")
						else
							gemButton:SetProperty("BackImage", "set:WM_CommonFrame1 image:Feng")
						end
						gemButton:SetActionItem(-1)
						gemButton:SetToolTip("#{PFZY_140613_38}")
					elseif v == 0 then
						gemButton:SetActionItem(-1)
						gemButton:SetProperty("BackImage", "set:CommonItem image:ActionBK")
						gemButton:SetToolTip("#{PFZY_140613_37}")
					else
						local nGemAction = LifeAbility:CreateVirtualActionItem( v, (g_setting.EquipBasicInfo[nImageListIndex].index* 8) + i + 3 );
						if nGemAction ~= nil then
							gemButton:SetActionItem(nGemAction:GetID())
							if DataPool:GetGemScore_FromGemTableIndex( gems2[i] ) > DataPool:GetGemScore_FromGemTableIndex( v ) then
								nGemAction:SetSelectStatus(0)
								ItemBar:Setm_newImage(16+i,"Face_04", "Remind3_Bak")
								ItemBar:Setm_newImageShow(16+i)
							else
								ItemBar:Setm_newImageHide(16+i)
								nGemAction:SetSelectStatus(1)
							end
						end
					end
					gemButton:Show()
				end
			end
		elseif levelMy < limitLevel2 then
			local StrContent2 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel2 )
			itemButton2:SetToolTip( StrContent2 )
			local bk2 = g_setting.EquipBasicInfo[nImageListIndex].back2
			if type(bk2) == "string" then
				itemButton2:SetProperty( "BackImage", bk2 )
			elseif type(bk2) == "table" then
				itemButton2:SetProperty( "BackImage", bk2[TargetFightScore_GetAttackType()] )
			end
			ItemBar:Setm_newText(22, StrContent2 )
			ItemBar:Setm_newTextShow(22)
		else
			local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", g_setting.EquipBasicInfo[nImageListIndex].name)
			local strNoEquipText = "#cFF0000"..strNoEquipToolTips
			itemButton2:SetToolTip(strNoEquipToolTips)
			ItemBar:Setm_newText(22, strNoEquipText)
			ItemBar:Setm_newTextShow(22)
		end
		if itemButton2 then
			itemButton2:Show()
		end
	end
	table.insert( g_data.RightItems, ItemBar )
end

function TargetFightScore_UpdateRightEnhance()
	for i=1, g_EquipMax do
		if i == 15 then
			continue --武魂木有强化
		end
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_TargetFightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_TargetFightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end
		local tempEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "targetequip" )
		local tempMyEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "equip" )
		TargetFightScore_NewTargetEnhanceItem( tempEquip, tempMyEquip, i )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_NewTargetEnhanceItem( actionItem, actionItemMy, nImageListIndex )
	local ItemBar = TargetFightScore_NewRightItem()
	local itemButton1, itemButton2 = ItemBar:GetLuaActionButton( 1, "TargetFightScore" ), nil
	local levelTar,levelMy = CachedTarget:GetData("LEVEL"), Player:GetLevel()
	local hasEm1,hasEm2 = CachedTarget:GetEquipMasterFlag(), CachedTarget:GetMySelfEquipMasterFlag()
	itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
	local actionId1, actionId2, StrContent1, StrContent2 = actionItem:GetID(), nil, "", ""
	if g_data.CompareState == 1 then
		itemButton2 = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
		itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
		actionId2 = actionItemMy:GetID()
	end
	
	local limitLevel, limitLevel2, testMaster, partName = 
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].testMaster,
		g_setting.EquipBasicInfo[nImageListIndex].name
	local bk2 = g_setting.EquipBasicInfo[nImageListIndex].back2
	
	if hasEm1 == 1 and testMaster then
		limitLevel = limitLevel - 10
	end
	if hasEm2 == 1 and testMaster then
		limitLevel2 = limitLevel2 - 10
	end

	itemButton1:Show()
	if actionId1 > 0 then
		itemButton1:SetActionItem(actionId1)
		local nlevel,_,_ = actionItem:GetStrengthenLevel()
		if g_data.CompareState == 1 and actionId2 > 0 then
			local nlevel2 = actionItemMy:GetStrengthenLevel()
			if nlevel2 > nlevel then
				nlevel = "#cFF0000"..nlevel
			end
		end
		local sTemp = ScriptGlobal_Format("#{PFZY_140613_133}", nlevel)
		ItemBar:Setm_newText( 1, sTemp )
		ItemBar:Setm_newTextShow(1)
	elseif levelTar < limitLevel then
		local StrContent1 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel )
		if type(bk2) == "string" then
			itemButton1:SetProperty( "BackImage", bk2 )
		elseif type(bk2) == "table" then
			itemButton1:SetProperty( "BackImage", bk2[TargetFightScore_GetTargetAttackType()] )
		end
		ItemBar:Setm_newText(1, StrContent1 )
		ItemBar:Setm_newTextShow(1)
	else
		local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", g_setting.EquipBasicInfo[nImageListIndex].name)
		local strNoEquipText = "#cFF0000"..strNoEquipToolTips
		itemButton1:SetToolTip(strNoEquipToolTips)
		ItemBar:Setm_newText( 1, strNoEquipText )
		ItemBar:Setm_newTextShow(1)
	end
	
	if g_data.CompareState == 1 then
		if actionId2 > 0 then
			itemButton2:SetActionItem(actionId2)
			local nlevel,_,_ = actionItemMy:GetStrengthenLevel()
			if actionId1 > 0 then
				local nlevel1 = actionItem:GetStrengthenLevel()
				if nlevel1 > nlevel then
					nlevel = "#cFF0000"..nlevel
				end
			end
			local sTemp = ScriptGlobal_Format( "#{PFZY_140613_133}", nlevel )
			ItemBar:Setm_newText(22, sTemp)
			ItemBar:Setm_newTextShow(22)
		elseif levelMy < limitLevel2 then
			local StrContent2 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel2 )
			if type(bk2) == "string" then
				itemButton2:SetProperty( "BackImage", bk2 )
			elseif type(bk2) == "table" then
				itemButton2:SetProperty( "BackImage", bk2[TargetFightScore_GetAttackType()] )
			end
			ItemBar:Setm_newText(22, StrContent2 )
			ItemBar:Setm_newTextShow(22)
		else
			local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", g_setting.EquipBasicInfo[nImageListIndex].name)
			local strNoEquipText = "#cFF0000"..strNoEquipToolTips
			itemButton2:SetToolTip(strNoEquipToolTips)
			ItemBar:Setm_newText(22, strNoEquipText)
			ItemBar:Setm_newTextShow(22)
		end
		if itemButton2 then
			itemButton2:Show()
		end
	end
	table.insert( g_data.RightItems, ItemBar )
end

function TargetFightScore_GetAnqiQual( q )
	if not q then
		return 0
	end
	if q < 40 then
		return 1
	elseif q < 80 then
		return 2
	elseif q < 120 then
		return 3
	elseif q < 160 then
		return 4
	elseif q < 200 then
		return 5
	else
		return 5
	end
end

function TargetFightScore_UpdateRightAnqi()
	local strBackImage = "set:UIIcons image:Equip_Anqi"
	local darkItem, darkItemMy = EnumAction(17,"targetequip"), EnumAction(17,"equip")
	local nDarkID, nDarkIDMy = darkItem:GetID(), darkItemMy:GetID()
	local darkQuals = {"#{ZSKSSJ_PT}","#{ZSKSSJ_YX}","#{ZSKSSJ_JC}","#{ZSKSSJ_ZY}","#{ZSKSSJ_WM}"}

	if nDarkID > 0 then
		local strDarkName,strDarkName2 = darkItem:GetName(), ""
		local qual, qual2 = darkQuals[ TargetFightScore_GetAnqiQual( darkItem:GetEquipAnqiQuality() ) ] or "", ""
		
		if g_data.CompareState == 1 and nDarkIDMy > 0 then
			local nNeedLevel,nNeedLevel2 = darkItem:GetEquipTableLevel(), darkItemMy:GetEquipTableLevel()
			strDarkName2 = darkItemMy:GetName()
			if nNeedLevel2 > nNeedLevel then
				strDarkName = "#cFF0000"..strDarkName
			elseif nNeedLevel > nNeedLevel2 then
				strDarkName2 = "#cFF0000"..strDarkName2
			end
			local q1,q2 = TargetFightScore_GetAnqiQual( darkItem:GetEquipAnqiQuality() ), TargetFightScore_GetAnqiQual( darkItemMy:GetEquipAnqiQuality() )
			qual2 = darkQuals[ q2 ] or ""
			if q2 > q1 then
				qual = "#cFF0000"..qual
			elseif q1 > q2 then
				qual2 = "#cFF0000"..qual2
			end
		end
		
		local ItemBar = TargetFightScore_NewGenericItem( strBackImage, 0, nDarkID, ScriptGlobal_Format("#{PFZY_140613_109}", strDarkName ), "" )
		if g_data.CompareState == 1 then
			if nDarkIDMy > 0 then
				TargetFightScore_AddGenericItem2( ItemBar, strBackImage, 0, nDarkIDMy, ScriptGlobal_Format("#{PFZY_140613_109}", strDarkName2 ), "" )
			else
				TargetFightScore_AddGenericItem2( ItemBar, strBackImage, 0, -1, "#{PFZY_140613_93}", "" )
			end
		end
		ItemBar = TargetFightScore_NewGenericItem( "set:FabaoDaoju image:FabaoDaoju_4", 0, -1, ScriptGlobal_Format( "#{PFZY_140613_111}", qual ), "")
		if g_data.CompareState == 1 and nDarkIDMy > 0 then
			TargetFightScore_AddGenericItem2( ItemBar, "set:FabaoDaoju image:FabaoDaoju_4", 0, -1, ScriptGlobal_Format( "#{PFZY_140613_111}", qual2 ), "")
		end
	else
		local ItemBar = TargetFightScore_NewRightItem()
		local ItemButton  = ItemBar:GetLuaActionButton(1,"TargetFightScore")
		if ItemButton == nil then
			return
		end
		ItemButton:Show()
		ItemButton:SetProperty("BackImage", strBackImage)
		ItemBar:Setm_newText(1, "#{PFZY_140613_93}")
		ItemBar:Setm_newTextShow(1)
		table.insert( g_data.RightItems, ItemBar )
		
		if g_data.CompareState == 1 then
			if nDarkIDMy > 0 then
				local strDarkName2 = darkItemMy:GetName()
				local qual2 = darkQuals[ TargetFightScore_GetAnqiQual( darkItemMy:GetEquipAnqiQuality() ) ] or ""
				TargetFightScore_AddGenericItem2( ItemBar, strBackImage, 0, nDarkIDMy, ScriptGlobal_Format("#{PFZY_140613_109}", strDarkName2 ), "" )
				ItemBar = TargetFightScore_NewRightItem()
				table.insert( g_data.RightItems, ItemBar )
				TargetFightScore_AddGenericItem2( ItemBar, "set:FabaoDaoju image:FabaoDaoju_4", 0, -1, ScriptGlobal_Format("#{PFZY_140613_111}", qual2 ), "" )
			else
				TargetFightScore_AddGenericItem2( ItemBar, strBackImage, 0, -1, "#{PFZY_140613_93}", "" )
			end
		end
	end
	TargetFightScore_UpdateRightAnqiLY()
	TargetFightScore_FlashRight()
end

function TargetFightScore_UpdateRightAnqiLY()
	local darkItem, darkItemMy = EnumAction(17,"targetequip"), EnumAction(17,"equip")
	local nDarkID, nDarkIDMy = darkItem:GetID(), darkItemMy:GetID()
	local nNeedLevel,nNeedLevel2 = darkItem:GetEquipTableLevel(), darkItemMy:GetEquipTableLevel()
	
	if nDarkID > 0 and nNeedLevel == 90 then		
		local tStarNum = darkItem:GetEquipAnqiLYStar()
		local tCDHP = darkItem:GetEquipAnqiLYCDHP()
		local tCDPro = darkItem:GetEquipAnqiLYCDPro()
		local tCDProType = darkItem:GetEquipAnqiLYCDProType()
		local tCDHit = darkItem:GetEquipAnqiLYCDHit()
		
		if g_data.CompareState == 1 and nDarkIDMy > 0 and nNeedLevel2 == 90 then
			-- 显示双方
			local myStarNum = darkItemMy:GetEquipAnqiLYStar()
			local myCDHP = darkItemMy:GetEquipAnqiLYCDHP()
			local myCDPro = darkItemMy:GetEquipAnqiLYCDPro()
			local myCDProType = darkItemMy:GetEquipAnqiLYCDProType()
			local myCDHit = darkItemMy:GetEquipAnqiLYCDHit()
			 
			if myStarNum < tStarNum then
				local starItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool80 image:CircularTaskTool80_3", 0, -1, "#{PFBJ_160106_61}" .. ScriptGlobal_Format("#{PFBJ_160106_65}", tStarNum ), "" )
				TargetFightScore_AddGenericItem2( starItemBar, "set:CircularTaskTool80 image:CircularTaskTool80_3", 0, -1, "#{PFBJ_160106_61}" .. ScriptGlobal_Format("#{PFBJ_160106_66}", myStarNum ), "" )
			elseif myStarNum > tStarNum then
				local starItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool80 image:CircularTaskTool80_3", 0, -1, "#{PFBJ_160106_61}" .. ScriptGlobal_Format("#{PFBJ_160106_66}", tStarNum ), "" )
				TargetFightScore_AddGenericItem2( starItemBar, "set:CircularTaskTool80 image:CircularTaskTool80_3", 0, -1, "#{PFBJ_160106_61}" .. ScriptGlobal_Format("#{PFBJ_160106_65}", myStarNum ), "" )
			else
				local starItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool80 image:CircularTaskTool80_3", 0, -1, "#{PFBJ_160106_61}" .. ScriptGlobal_Format("#{PFBJ_160106_65}", tStarNum ), "" )
				TargetFightScore_AddGenericItem2( starItemBar, "set:CircularTaskTool80 image:CircularTaskTool80_3", 0, -1, "#{PFBJ_160106_61}" .. ScriptGlobal_Format("#{PFBJ_160106_65}", myStarNum ), "" )
			end
			
			if (tCDHP > 0 and tCDPro > 0 and tCDHit > 0) and (myCDHP > 0 and myCDPro > 0 and myCDHit > 0) then
				if myCDHP < tCDHP then
					local hpItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDHP ), "" )
					TargetFightScore_AddGenericItem2( hpItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_68}", myCDHP ), "" )
				elseif myCDHP > tCDHP then
					local hpItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_68}", tCDHP ), "" )
					TargetFightScore_AddGenericItem2( hpItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDHP ), "" )
				else
					local hpItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDHP ), "" )
					TargetFightScore_AddGenericItem2( hpItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDHP ), "" )
				end
				
				if myCDPro < tCDPro then
					local proItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[tCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDPro ), "" )
					TargetFightScore_AddGenericItem2( proItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[myCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_68}", myCDPro ), "" )
				elseif myCDPro > tCDPro then
					local proItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[tCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_68}", tCDPro ), "" )
					TargetFightScore_AddGenericItem2( proItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[myCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDPro ), "" )
				else
					local proItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[tCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDPro ), "" )
					TargetFightScore_AddGenericItem2( proItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[myCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDPro ), "" )
				end
				
				if myCDHit < tCDHit then
					local hitItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDHit ), "" )
					TargetFightScore_AddGenericItem2( hitItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_68}", myCDHit ), "" )
				elseif myCDHit > tCDHit then
					local hitItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_68}", tCDHit ), "" )
					TargetFightScore_AddGenericItem2( hitItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDHit ), "" )
				else
					local hitItemBar = TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDHit ), "" )
					TargetFightScore_AddGenericItem2( hitItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDHit ), "" )
				end
				
			elseif tCDHP > 0 and tCDPro > 0 and tCDHit > 0 then
				--粹毒血上限
				TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDHP ), "" )
				
				--粹毒属性攻
				TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[tCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDPro ), "" )
			
				--粹毒命中
				TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDHit ), "" )
			elseif myCDHP > 0 and myCDPro > 0 and myCDHit > 0 then
				--粹毒血上限
				hpItemBar = TargetFightScore_NewRightItem()
				TargetFightScore_AddGenericItem2( hpItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDHP ), "" )
				
				--粹毒属性攻
				proItemBar = TargetFightScore_NewRightItem()
				TargetFightScore_AddGenericItem2( proItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[myCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDPro ), "" )
			
				--粹毒命中
				hitItemBar = TargetFightScore_NewRightItem()
				TargetFightScore_AddGenericItem2( hitItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDHit ), "" )
			end	
		else
			-- 显示对方
			TargetFightScore_NewGenericItem( "set:CircularTaskTool80 image:CircularTaskTool80_3", 0, -1, "#{PFBJ_160106_61}" .. ScriptGlobal_Format("#{PFBJ_160106_65}", tStarNum ), "" )		
			if tCDHP > 0 and tCDPro > 0 and tCDHit > 0 then
				--粹毒血上限
				TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDHP ), "" )
				
				--粹毒属性攻
				TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[tCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDPro ), "" )
			
				--粹毒命中
				TargetFightScore_NewGenericItem( "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", tCDHit ), "" )
			end	
		end
		
		
		
	else
		if g_data.CompareState == 1 then
			if nDarkIDMy > 0 and nNeedLevel2 == 90 then
				--星级
				local myStarNum = darkItemMy:GetEquipAnqiLYStar()
				starItemBar = TargetFightScore_NewRightItem()
				TargetFightScore_AddGenericItem2( starItemBar, "set:CircularTaskTool80 image:CircularTaskTool80_3", 0, -1, "#{PFBJ_160106_61}" .. ScriptGlobal_Format("#{PFBJ_160106_65}", myStarNum ), "" )
				local myCDHP = darkItemMy:GetEquipAnqiLYCDHP()
				local myCDPro = darkItemMy:GetEquipAnqiLYCDPro()
				local myCDProType = darkItemMy:GetEquipAnqiLYCDProType()
				local myCDHit = darkItemMy:GetEquipAnqiLYCDHit()
				
				if myCDHP > 0 and myCDPro > 0 and myCDHit > 0 then
					--粹毒血上限
					hpItemBar = TargetFightScore_NewRightItem()
					TargetFightScore_AddGenericItem2( hpItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_10", 0, -1, "#{PFBJ_160106_62}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDHP ), "" )
				
					--粹毒属性攻
					proItemBar = TargetFightScore_NewRightItem()
					TargetFightScore_AddGenericItem2( proItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_12", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_63}",g_LYProType[myCDProType + 1]) .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDPro ), "" )
			
					--粹毒命中
					hitItemBar = TargetFightScore_NewRightItem()
					TargetFightScore_AddGenericItem2( hitItemBar, "set:CircularTaskTool79 image:CircularTaskTool79_11", 0, -1, "#{PFBJ_160106_64}" .. ScriptGlobal_Format("#{PFBJ_160106_67}", myCDHit ), "" )
				end
				
			end 
		end
	end
	
end

function TargetFightScore_GetShenDingActived( objtype )
	if objtype == 0 then
		return CachedTarget:GetData("LianDanCount") or 0, CachedTarget:GetData("Attack_DanYaoCount") or 0
	else
		return Player:GetData("LianDanCount") or 0, Player:GetData("Attack_DanYaoCount") or 0
	end
	return 0,0
end

function TargetFightScore_ShenDingGetSafeItem( n )
	while table.getn( g_data.RightItems ) < n
	do
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	end
	return g_data.RightItems[n]
end

function TargetFightScore_UpdateRightShenDingItem( objtype )
	local showFunc = TargetFightScore_AddGenericItem1
	if objtype ~= 0 then
		showFunc = TargetFightScore_AddGenericItem2
	end
	local i1,i2 = TargetFightScore_GetShenDingActived( objtype )
	local color,color2 = "#G","#G"
	if g_data.CompareState == 1 then
	
	end
	local sdStage,sdStep,sdStage2,sdStep2 = 1, 0, 1, 0
	if i1 > 0 then
		sdStage,sdStep = g_setting.sdMap[i1][1], g_setting.sdMap[i1][2]
	end
	if i2 > 0 then
		sdStage2,sdStep2 = g_setting.sdMap[i2][1], g_setting.sdMap[i2][2]
	end
	if g_data.CompareState == 1 then
		local i3,i4 = TargetFightScore_GetShenDingActived( 1 - objtype )
		if i1 < i3 then
			color = "#cff0000"
		end
		if i2 < i4 then
			color2 = "#cff0000"
		end
	end
	local strTemp = ScriptGlobal_Format("#{PFZY_140613_178}", color..sdStep, color..sdStage )
	showFunc( TargetFightScore_ShenDingGetSafeItem(1), "set:CircularTaskTool79 image:CircularTaskTool79_5", 0, -1, strTemp, "" )
	strTemp = ScriptGlobal_Format("#{PFZY_140613_221}", color2..sdStep2, color2..sdStage2 )
	showFunc( TargetFightScore_ShenDingGetSafeItem(2), "set:CircularTaskTool79 image:CircularTaskTool79_6", 0, -1, strTemp, "" )
end

function TargetFightScore_UpdateRightShenDing()
	TargetFightScore_UpdateRightShenDingItem( 0 )
	if g_data.CompareState == 1 then
		TargetFightScore_UpdateRightShenDingItem( 1 )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_GetItemMaxZiZhi( item )
	local rStr, rRate = "", 0
	local grade, rate = -1, -1
	if item:IsEquipHaveZiZhi() > 0 then
		grade = item:GetEquipMaxAttrByAptValue()
		rate = item:GetEquipMaxAttrByAptRate()
	end
	rRate = rate
	if rate > 0 then
		for _, v in g_setting.ZiZhiRateInfo do
			if v.rate > grade then
				break
			end
			rStr = v.str
		end
	end
	return rStr, rRate
end

function TargetFightScore_NewTargetZiZhiItem( actionItem, actionItemMy, nImageListIndex )
	local ItemBar = TargetFightScore_NewRightItem()
	local itemButton1, itemButton2 = ItemBar:GetLuaActionButton( 1, "TargetFightScore" ), nil
	local levelTar,levelMy = CachedTarget:GetData("LEVEL"), Player:GetLevel()
	local hasEm1,hasEm2 = CachedTarget:GetEquipMasterFlag(), CachedTarget:GetMySelfEquipMasterFlag()
	itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
	local actionId1, actionId2, StrContent1, StrContent2 = actionItem:GetID(), nil, "", ""
	if g_data.CompareState == 1 then
		itemButton2 = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
		itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
		actionId2 = actionItemMy:GetID()
	end
	
	local s1,r1,s2,r2 = "", 0, "", 0
	
	if actionId1 > 0 then
		s1, r1 = TargetFightScore_GetItemMaxZiZhi( actionItem )
	end
	
	if g_data.CompareState == 1 and actionId2 > 0 then
		s2, r2 = TargetFightScore_GetItemMaxZiZhi( actionItemMy )
	end
	
	local limitLevel, limitLevel2, testMaster, partName = 
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].testMaster,
		g_setting.EquipBasicInfo[nImageListIndex].name
	local bk2 = g_setting.EquipBasicInfo[nImageListIndex].back2
	
	if hasEm1 == 1 and testMaster then
		limitLevel = limitLevel - 10
	end
	if hasEm2 == 1 and testMaster then
		limitLevel2 = limitLevel2 - 10
	end
	
	itemButton1:Show()
	if actionId1 > 0 then
		itemButton1:SetActionItem(actionId1)
		local strTemp = ""
		if r1 < 0 then
			strTemp = "#{PFZY_140613_140}"	--	无资质
		elseif r1 == 0 then
			strTemp = "#{PFZY_140613_141}"	--	未鉴定
		elseif r1 > 0 then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_142}", "#G"..s1, "#G"..r1 )
			if g_data.CompareState == 1 and r2 > r1 then
				strTemp = ScriptGlobal_Format("#{PFZY_140613_142}", "#cFF0000"..s1, "#cFF0000"..r1 )
			end
		end
		ItemBar:Setm_newText(1, strTemp )
		ItemBar:Setm_newTextShow(1)
	elseif levelTar < limitLevel then
		local StrContent1 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel )
		if type(bk2) == "string" then
			itemButton1:SetProperty( "BackImage", bk2 )
		elseif type(bk2) == "table" then
			itemButton1:SetProperty( "BackImage", bk2[TargetFightScore_GetTargetAttackType()] )
		else
			itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back  )
		end
		ItemBar:Setm_newText(1, StrContent1 )
		ItemBar:Setm_newTextShow(1)
	else
		local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", partName )
		local strNoEquipText = "#cFF0000"..strNoEquipToolTips
		itemButton1:SetToolTip(strNoEquipToolTips)
		ItemBar:Setm_newText(1, strNoEquipText)
		ItemBar:Setm_newTextShow(1)
	end
	
	if g_data.CompareState == 1 then
		if actionId2 > 0 then
			itemButton2:SetActionItem(actionId2)
			local strTemp = ""
			if r2 < 0 then
				strTemp = "#{PFZY_140613_140}"	--	无资质
			elseif r2 == 0 then
				strTemp = "#{PFZY_140613_141}"	--	未鉴定
			elseif r2 > 0 then
				strTemp = ScriptGlobal_Format("#{PFZY_140613_142}", "#G"..s2, "#G"..r2 )
				if g_data.CompareState == 1 and r1 > r2 then
					strTemp = ScriptGlobal_Format("#{PFZY_140613_142}", "#cFF0000"..s2, "#cFF0000"..r2 )
				end
			end
			ItemBar:Setm_newText(22, strTemp )
			ItemBar:Setm_newTextShow(22)
		elseif levelMy < limitLevel2 then
			local StrContent2 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel2 )
			if type(bk2) == "string" then
				itemButton2:SetProperty( "BackImage", bk2 )
			elseif type(bk2) == "table" then
				itemButton2:SetProperty( "BackImage", bk2[TargetFightScore_GetAttackType()] )
			else
				itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back  )
			end
			ItemBar:Setm_newText(22, StrContent2 )
			ItemBar:Setm_newTextShow(22)
		else
			local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", partName )
			local strNoEquipText = "#cFF0000"..strNoEquipToolTips
			itemButton2:SetToolTip(strNoEquipToolTips)
			ItemBar:Setm_newText(22, strNoEquipText)
			ItemBar:Setm_newTextShow(22)
		end
		itemButton2:Show()
	end
	table.insert( g_data.RightItems, ItemBar )
end

function TargetFightScore_UpdateRightZiZhi()
	for i=1, g_EquipMax do
		if i == 15 then
			continue --武魂木有资质
		end
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_TargetFightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_TargetFightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end
		local tempEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "targetequip" )
		local tempEquipMy = EnumAction( g_setting.EquipBasicInfo[i].index, "equip" )
		TargetFightScore_NewTargetZiZhiItem( tempEquip, tempEquipMy, i )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_NewTargetKeMingItem( actionItem, actionItemMy, nImageListIndex )
	local ItemBar = TargetFightScore_NewRightItem()
	local itemButton1, itemButton2 = ItemBar:GetLuaActionButton( 1, "TargetFightScore" ), nil
	local levelTar,levelMy = CachedTarget:GetData("LEVEL"), Player:GetLevel()
	local hasEm1,hasEm2 = CachedTarget:GetEquipMasterFlag(), CachedTarget:GetMySelfEquipMasterFlag()
	itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
	local actionId1, actionId2, StrContent1, StrContent2 = actionItem:GetID(), nil, "", ""
	if g_data.CompareState == 1 then
		itemButton2 = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
		itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
		actionId2 = actionItemMy:GetID()
	end
	
	local islocked, islocked2 = 0, 0
	if actionId1 > 0 then
		islocked = actionItem:GetEquipIsLocked()
	end
	if g_data.CompareState == 1 and actionId2 > 0 then
		islocked2 = actionItemMy:GetEquipIsLocked()
	end
	
	local limitLevel, limitLevel2, testMaster, partName = 
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].testMaster,
		g_setting.EquipBasicInfo[nImageListIndex].name
	local bk2 = g_setting.EquipBasicInfo[nImageListIndex].back2
	
	if hasEm1 == 1 and testMaster then
		limitLevel = limitLevel - 10
	end
	if hasEm2 == 1 and testMaster then
		limitLevel2 = limitLevel2 - 10
	end
	
	itemButton1:Show()
	if actionId1 > 0 then
		itemButton1:SetActionItem(actionId1)
		if islocked == 1 then
			strTemp = "#{PFZY_140613_135}"
		else
			strTemp = "#{PFZY_140613_136}"
		end
		ItemBar:Setm_newText( 1, strTemp )
		ItemBar:Setm_newTextShow( 1 )
	elseif levelTar < limitLevel then
		local StrContent1 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel )
		if type(bk2) == "string" then
			itemButton1:SetProperty( "BackImage", bk2 )
		elseif type(bk2) == "table" then
			itemButton1:SetProperty( "BackImage", bk2[TargetFightScore_GetTargetAttackType()] )
		else
			itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back  )
		end
		ItemBar:Setm_newText(1, StrContent1 )
		ItemBar:Setm_newTextShow(1)
	else
		local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", partName )
		local strNoEquipText = "#cFF0000"..strNoEquipToolTips
		itemButton1:SetToolTip(strNoEquipToolTips)
		ItemBar:Setm_newText( 1, strNoEquipText )
		ItemBar:Setm_newTextShow(1)
	end
	
	if  g_data.CompareState == 1 then
		if actionId2 > 0 then
			itemButton2:SetActionItem(actionId2)
			if islocked2 == 1 then
				strTemp = "#{PFZY_140613_135}"
			else
				strTemp = "#{PFZY_140613_136}"
			end
			ItemBar:Setm_newText( 22, strTemp )
			ItemBar:Setm_newTextShow( 22 )
		elseif levelMy < limitLevel2 then
			local StrContent2 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel2 )
			if type(bk2) == "string" then
				itemButton2:SetProperty( "BackImage", bk2 )
			elseif type(bk2) == "table" then
				itemButton2:SetProperty( "BackImage", bk2[TargetFightScore_GetAttackType()] )
			else
				itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
			end
			ItemBar:Setm_newText(22, StrContent2 )
			ItemBar:Setm_newTextShow(22)
		else
			local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", partName )
			local strNoEquipText = "#cFF0000"..strNoEquipToolTips
			itemButton2:SetToolTip(strNoEquipToolTips)
			ItemBar:Setm_newText( 22, strNoEquipText )
			ItemBar:Setm_newTextShow(22)
		end
		itemButton2:Show()
	end
	table.insert( g_data.RightItems, ItemBar )
end

function TargetFightScore_UpdateRightKeMing()
	for i=1, g_EquipMax do
		if i == 15 then
			continue --武魂木有刻铭
		end
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_TargetFightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_TargetFightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end
		local tempEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "targetequip" )
		local tempEquipMy = EnumAction( g_setting.EquipBasicInfo[i].index, "equip" )
		TargetFightScore_NewTargetKeMingItem( tempEquip, tempEquipMy, i )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_FutiGetSafeItem( n )
	while table.getn( g_data.RightItems ) < n
	do
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	end
	return g_data.RightItems[n]
end

local ftzzDict = { "普通","优秀","杰出","卓越","完美" }
function TargetFightScore_UpdateRightFutiPart( objtype )
	local showFunc = TargetFightScore_AddGenericItem1
	local TextCtls = { 3, 4, 5 }
	if objtype ~= 0 then
		showFunc = TargetFightScore_AddGenericItem2
		TextCtls = { 23, 24, 25 }
	end
	if TargetFightScore_GetLevel(objtype) < 45 then
		local ItemBar = TargetFightScore_FutiGetSafeItem( 1 )
		showFunc( ItemBar, "", 0, -1, "#{PFBJ_160106_13}", "" )
		return
	end
	if TargetFightScore_FutiCheck(objtype) == 0 then
		local ItemBar = TargetFightScore_FutiGetSafeItem( 1 )
		showFunc( ItemBar, "", 0, -1, "#{PFZY_140613_113}", "" )
		return
	end

	local takeLevel, growRate, wuXing, lingXing, rongHe, level, iconname = TargetFightScore_Info( objtype )
	if not takeLevel or takeLevel < 0 then
		return
	end
	local ItemBar1 = TargetFightScore_FutiGetSafeItem( 1 )
	local colors = { "","","","","","","","","","","" }
	if g_data.CompareState == 1 and TargetFightScore_FutiCheck( 1 - objtype) ~= 0 then
		local takeLevel2, growRate2, wuXing2, lingXing2, rongHe2, level2 = TargetFightScore_Info( 1 - objtype )
		if takeLevel2 and takeLevel2 > 0 then
			if takeLevel2 > takeLevel then
				colors[1] = "#cFF0000"
			end
			if growRate2 > growRate then
				colors[2] = "#cFF0000"
			end
			if wuXing2 > wuXing then
				colors[3] = "#cFF0000"
			end
			if lingXing2 > lingXing then
				colors[4] = "#cFF0000"
			end
			if rongHe2 > rongHe then
				colors[5] = "#cFF0000"
			end
			if level2 > level then
				colors[6] = "#cFF0000"
			end
		end
	end
	
	local iconIndex = 1
	if objtype ~= 0 then
		iconIndex = 6
	end
	--图标，携带等级，以及成长
	local itemButton = ItemBar1:GetLuaActionButton( iconIndex, "TargetFightScore" )
	itemButton:SetProperty( "BackImage", iconname )
	itemButton:Show()
	ItemBar1:Setm_newText( TextCtls[1],"#{PFZY_140613_116}" )
	ItemBar1:Setm_newTextShow( TextCtls[1] )
	ItemBar1:Setm_newText( TextCtls[2], ScriptGlobal_Format("#{PFZY_140613_120}",colors[1]..takeLevel) )
	ItemBar1:Setm_newTextShow( TextCtls[2] )
	if growRate >= 0 then
		ItemBar1:Setm_newText( TextCtls[3], ScriptGlobal_Format("#{PFZY_140613_121}",colors[2]..ftzzDict[growRate+1]) )
	else
		ItemBar1:Setm_newText( TextCtls[3], ScriptGlobal_Format("#{PFZY_140613_118}","未知") )
	end
	ItemBar1:Setm_newTextShow( TextCtls[3] )
	
	--悟性
	showFunc( TargetFightScore_FutiGetSafeItem( 2 ), "set:Cloth4 image:Cloth4_8", 0, -1, ScriptGlobal_Format("#{PFZY_140613_123}", colors[3]..wuXing ), "" )
	--灵性
	showFunc( TargetFightScore_FutiGetSafeItem( 3 ), "set:PetMedicine image:PetMedicine_14", 0, -1, ScriptGlobal_Format("#{PFZY_140613_125}", colors[4]..lingXing ), "" )
	--融合度
	showFunc( TargetFightScore_FutiGetSafeItem( 4 ), "set:PetMedicine image:PetMedicine_16", 0, -1, ScriptGlobal_Format("#{PFZY_140613_127}", colors[5]..rongHe ), "" )
	--等级
	showFunc( TargetFightScore_FutiGetSafeItem( 5 ), "set:TaskTools15 image:TaskTools15_16", 0, -1, ScriptGlobal_Format("#{PFZY_140613_198}", colors[6]..level ), "" )
	--技能
	for i=0, 4 do
		local skillLevel, ImageName = TargetFightScore_FutiSkill( objtype, i )
		if skillLevel < 0 then
			showFunc( TargetFightScore_FutiGetSafeItem( i + 6 ), "", 0, -1, "#{PFZY_140613_128}", "" )
		else
			if g_data.CompareState == 1 and TargetFightScore_FutiCheck( 1 - objtype) ~= 0 then
			local skillLevel2,_ = TargetFightScore_FutiSkill( 1 - objtype, i )
				if skillLevel2 > skillLevel then
					colors[i+7] = "#cFF0000"
				end
			end
			if skillLevel < 2 then
				skillLevel = 0
			else
				skillLevel = skillLevel-1
			end
			local FullImgName = TargetFightScore_MakeFullImageName(ImageName)
			showFunc( TargetFightScore_FutiGetSafeItem( i + 6 ), FullImgName, 0, -1, ScriptGlobal_Format("#{PFZY_140613_130}",colors[i+7]..skillLevel), "" )
		end
	end
end

function TargetFightScore_FutiCheck( objtype )
	local idx = -1
	if objtype == 0 then
		idx = CachedTarget:GetData("PetFutiIndex")
	else
		idx = Pet:GetFuTiPetIndex()
	end
	if idx >= 0 then
		return 1
	else
		return 0
	end
end

function TargetFightScore_GetLevel( objtype )
	local idx = -1
	if objtype == 0 then
		return CachedTarget:GetData("LEVEL")
	else
		return Player:GetLevel()
	end
end

function TargetFightScore_GetHasEm( objtype )
	if objtype == 0 then
		return CachedTarget:GetEquipMasterFlag()
	else
		return CachedTarget:GetMySelfEquipMasterFlag()
	end
end

function TargetFightScore_Info( objtype )
	local idx = -1
	if objtype == 0 then
		idx = CachedTarget:GetData("PetFutiIndex")
	else
		idx = Pet:GetFuTiPetIndex()
	end
	if idx < 0 then
		return
	end
	if objtype == 0 then
		local takeLevel, growRate, wuXing, lingXing, rongHe, level, icon = DataPool:GetOtherFuTiPetInfo( idx )
		return takeLevel, growRate, wuXing, lingXing, rongHe, level, icon
	else
		local takeLevel, growRate, wuXing, lingXing, rongHe, level, icon = Pet:GetTakeLevel(idx), Pet:GetPetGrowLevel(idx, Pet:GetGrowRate(idx) ), Pet:GetSavvy(idx), Pet:GetLixing(idx), Pet:GetFitValue(idx), Pet:GetLevel(idx), Pet:GetPetPortraitByIndex(idx)
		return takeLevel, growRate, wuXing, lingXing, rongHe, level, icon
	end
end

function TargetFightScore_FutiSkill( objtype, i )
	local idx = -1
	if objtype == 0 then
		idx = CachedTarget:GetData("PetFutiIndex")
	else
		idx = Pet:GetFuTiPetIndex()
	end
	if idx < 0 then
		return
	end
	local skillLevel, ImageName = nil, nil
	if objtype == 0 then
		skillLevel, ImageName = DataPool:GetOtherFuTiSkillLevel(idx,i)
	else
		skillLevel, ImageName = DataPool:GetFuTiSkillLevel(i)
	end
	return skillLevel, ImageName
end

function TargetFightScore_UpdateRightFuti()
	TargetFightScore_UpdateRightFutiPart(0)
	if g_data.CompareState == 1 then
		TargetFightScore_UpdateRightFutiPart(1)
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_NewTargetDiaoWenItem( actionItem, actionItemMy, nImageListIndex )
	local ItemBar = TargetFightScore_NewRightItem()
	local itemButton1, itemButton2 = ItemBar:GetLuaActionButton( 1, "TargetFightScore" ), nil
	local levelTar,levelMy = CachedTarget:GetData("LEVEL"), Player:GetLevel()
	local hasEm1,hasEm2 = CachedTarget:GetEquipMasterFlag(), CachedTarget:GetMySelfEquipMasterFlag()
	itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
	local actionId1, actionId2, StrContent1, StrContent2 = actionItem:GetID(), nil, "", ""
	if g_data.CompareState == 1 then
		itemButton2 = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
		itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
		actionId2 = actionItemMy:GetID()
	end
	
	local limitLevel, limitLevel2, testMaster, partName = 
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].level,
		g_setting.EquipBasicInfo[nImageListIndex].testMaster,
		g_setting.EquipBasicInfo[nImageListIndex].name
	local bk2 = g_setting.EquipBasicInfo[nImageListIndex].back2
	
	if hasEm1 == 1 and testMaster then
		limitLevel = limitLevel - 10
	end
	if hasEm2 == 1 and testMaster then
		limitLevel2 = limitLevel2 - 10
	end
	
	local dwId, dwId2, MyDwId, MyDwId2 = -1, -1, -1, -1
	local MaxLevelTar, MaxLevelMy = -1, -1
	local l1, l2, ml1, ml2 = -1, -1, -1, -1
	local ColorTar,ColorTar2, ColorMy, ColorMy2 = "#G", "#G", "#G", "#G"
	if actionId1 > 0 then
		dwId, dwId2 = actionItem:GetEquipDiaoWen()
		l1,l2 = LifeAbility:GetWearedDiaoWenGrade(dwId), LifeAbility:GetWearedDiaoWenGrade(dwId2)
		MaxLevelTar = l1
		if l2 > l1 then
			MaxLevelTar = l2
		end
	end
	if g_data.CompareState == 1 and actionId2 > 0 then
		MyDwId, MyDwId2 = actionItemMy:GetEquipDiaoWen()
		ml1, ml2 = LifeAbility:GetWearedDiaoWenGrade(MyDwId), LifeAbility:GetWearedDiaoWenGrade(MyDwId2)
		MaxLevelMy = ml1
		if ml2 > ml1 then
			MaxLevelMy = ml2
		end
	end
	if l2 > 0 and ml2 > 0 then
		if l2 > ml2 then
			ColorMy2 = "#cff0000"
		elseif l2 < ml2 then
			ColorTar2 = "#cff0000"
		end
		if l1 > ml1 then
			ColorMy = "#cff0000"
		elseif l1 < ml1 then
			ColorTar = "#cff0000"
		end
	elseif l2 <= 0 and ml2 <= 0 then
		if l1 > ml1 then
			ColorMy,ColorMy2 = "#cFF0000", "#cFF0000"
		elseif l1 < ml1 then
			ColorTar, ColorTar2 = "#cFF0000", "#cFF0000"
		end
	else
		if MaxLevelTar < MaxLevelMy then
			ColorTar, ColorTar2 = "#cFF0000", "#cFF0000"
		end
		if MaxLevelTar > MaxLevelMy then
			ColorMy,ColorMy2 = "#cFF0000", "#cFF0000"
		end 
	end

	
	itemButton1:Show()
	if actionId1 > 0 then
		itemButton1:SetActionItem(actionId1)
		local strTemp = ""
		if ( hasEm1 == 1 and levelTar < 40 ) or levelTar < 50 then
			if hasEm1 == 1 then
				strTemp = ScriptGlobal_Format( "#{PFBJ_160106_59}", 40 )
			else
				strTemp = ScriptGlobal_Format( "#{PFBJ_160106_59}", 50 )
			end
		elseif dwId > 0 then
			local strName = LifeAbility:GetWearedDiaoWenName(dwId)
			strTemp = "#{PFBJ_160106_22}"..ColorTar..strName
			if dwId2 > 0 then
				local strDesc = LifeAbility:GetWearedDiaoWenDesc(dwId)
				local strDescEx = LifeAbility:GetWearedDiaoWenDesc(dwId2)
				local nLevel = LifeAbility:GetWearedDiaoWenGrade(dwId)
				local nLevelEx = LifeAbility:GetWearedDiaoWenGrade(dwId2)
				strTemp = ScriptGlobal_Format("#{PFBJ_160106_86}", ColorTar..strDesc, ColorTar2..strDescEx, ColorTar..nLevel, ColorTar2..nLevelEx)
			end
		else
			strTemp = "#{PFZY_140613_65}"
		end
		ItemBar:Setm_newText(1, strTemp)
		ItemBar:Setm_newTextShow(1)
	elseif ( hasEm1 == 1 and levelTar < 40 ) or levelTar < 50 then
		local StrContent1 = ""
		if hasEm1 == 1 then
			StrContent1 = ScriptGlobal_Format( "#{PFBJ_160106_59}", 40 )
		else
			StrContent1 = ScriptGlobal_Format( "#{PFBJ_160106_59}", 50 )
		end
		itemButton1:SetToolTip( ScriptGlobal_Format("#{PFZY_140613_39}", partName) )
		ItemBar:Setm_newText(1, StrContent1 )
		ItemBar:Setm_newTextShow(1)
	elseif levelTar < limitLevel then
		local StrContent1 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel )
		itemButton1:SetToolTip( ScriptGlobal_Format("#{PFZY_140613_39}", partName) )
		if type(bk2) == "string" then
			itemButton1:SetProperty( "BackImage", bk2 )
		elseif type(bk2) == "table" then
			itemButton1:SetProperty( "BackImage", bk2[TargetFightScore_GetTargetAttackType()] )
		else
			itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back  )
		end
		ItemBar:Setm_newText(1, StrContent1 )
		ItemBar:Setm_newTextShow(1)
	else
		local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", partName )
		local strNoEquipText = "#cFF0000"..strNoEquipToolTips
		itemButton1:SetToolTip(strNoEquipToolTips)
		ItemBar:Setm_newText(1, strNoEquipText)
		ItemBar:Setm_newTextShow(1)
	end
	
	if g_data.CompareState == 1 then
		if actionId2 > 0 then
			itemButton2:SetActionItem(actionId2)
			local strTemp = ""
			if ( hasEm2 == 1 and levelMy < 40 ) or levelMy < 50 then
				if hasEm2 == 1 then
					strTemp = ScriptGlobal_Format( "#{PFBJ_160106_59}", 40 )
				else
					strTemp = ScriptGlobal_Format( "#{PFBJ_160106_59}", 50 )
				end
			elseif MyDwId > 0 then
				local strName = LifeAbility:GetWearedDiaoWenName(MyDwId)
				strTemp = "#{PFBJ_160106_22}"..ColorMy..strName
				if MyDwId2 > 0 then
					local strDesc = LifeAbility:GetWearedDiaoWenDesc(MyDwId)
					local strDescEx = LifeAbility:GetWearedDiaoWenDesc(MyDwId2)
					local nLevel = LifeAbility:GetWearedDiaoWenGrade(MyDwId)
					local nLevelEx = LifeAbility:GetWearedDiaoWenGrade(MyDwId2)
					strTemp = ScriptGlobal_Format("#{PFBJ_160106_86}", ColorMy..strDesc, ColorMy2..strDescEx, ColorMy..nLevel, ColorMy2..nLevelEx)
				end
			else
				strTemp = "#{PFZY_140613_65}"
			end
			ItemBar:Setm_newText( 22, strTemp)
			ItemBar:Setm_newTextShow(22)
		elseif ( hasEm2 == 1 and levelMy < 40 ) or levelMy < 50 then
			local StrContent2 = ""
			if hasEm2 == 1 then
				StrContent2 = ScriptGlobal_Format( "#{PFBJ_160106_59}", 40 )
			else
				StrContent2 = ScriptGlobal_Format( "#{PFBJ_160106_59}", 50 )
			end
			itemButton2:SetToolTip( ScriptGlobal_Format("#{PFZY_140613_39}", partName) )
			ItemBar:Setm_newText(22, StrContent2 )
			ItemBar:Setm_newTextShow(22)
		elseif levelMy < limitLevel2 then
			local StrContent2 = ScriptGlobal_Format( "#{PFBJ_160106_7}", limitLevel2 )
			itemButton2:SetToolTip( ScriptGlobal_Format("#{PFZY_140613_39}", partName) )
			if type(bk2) == "string" then
				itemButton2:SetProperty( "BackImage", bk2 )
			elseif type(bk2) == "table" then
				itemButton2:SetProperty( "BackImage", bk2[TargetFightScore_GetAttackType()] )
			else
				itemButton2:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back  )
			end
			ItemBar:Setm_newText(22, StrContent2 )
			ItemBar:Setm_newTextShow(22)
		else
			local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", partName )
			local strNoEquipText = "#cFF0000"..strNoEquipToolTips
			itemButton2:SetToolTip(strNoEquipToolTips)
			ItemBar:Setm_newText(22, strNoEquipText)
			ItemBar:Setm_newTextShow(22)
		end
		itemButton2:Show()
	end

	table.insert( g_data.RightItems, ItemBar )
end

function TargetFightScore_UpdateRightDiaowen()
	for i=1, g_EquipMax do
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_TargetFightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_TargetFightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end
		local tempEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "targetequip" )
		local tempEquipMy = EnumAction( g_setting.EquipBasicInfo[i].index, "equip" )
		TargetFightScore_NewTargetDiaoWenItem( tempEquip, tempEquipMy, i )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_UpdateRightInfant_Target()
	if TargetFightScore_GetLevel(0) < 50 then
		TargetFightScore_AddGenericItem1( g_data.RightItems[1], "set:IMShow image:IMShow_13", 0, -1, "#{PFBJ_160106_23}", "#{PFZY_140613_152}" )
		return
	end
	if Infant:Other_GetInfantCount() <= 0 then
		TargetFightScore_AddGenericItem1( g_data.RightItems[1], "set:IMShow image:IMShow_13", 0, -1, "#{PFZY_140613_152}", "" )
		return
	end
	local bCmp = false
	if g_data.CompareState == 1 and Infant:GetInfantCount() > 0 then
		bCmp = true
	end
	local strTemp,strTemp2 = "", ""
	--等级
	strTemp = ScriptGlobal_Format("#{PFZY_140613_156}", Infant:Other_GetInfantLevel(0) )
	if bCmp and Infant:GetInfantLevel(0) > Infant:Other_GetInfantLevel(0) then
		strTemp = ScriptGlobal_Format("#{PFZY_140613_156}", "#cFF0000"..Infant:Other_GetInfantLevel(0) )
	end
	TargetFightScore_AddGenericItem1( g_data.RightItems[1], "set:CircularTaskTool57 image:CircularTaskTool57_6", 0, -1, strTemp, "" )
	--综合素养
	local total_attr = 0
	for i=0,4 do
		total_attr = total_attr + Infant:Other_GetInfantAttr( 0, i )
	end
	strTemp = ScriptGlobal_Format( "#{PFZY_140613_158}", total_attr )
	if bCmp then
		local total_attr2 = 0
		for i=0,4 do
			total_attr2 = total_attr2 + Infant:GetInfantAttr( 0, i )
		end
		if total_attr2 > total_attr then
			strTemp = ScriptGlobal_Format( "#{PFZY_140613_158}", "#cFF0000"..total_attr )
		end
	end
	TargetFightScore_AddGenericItem1( g_data.RightItems[2], "set:CircularTaskTool57 image:CircularTaskTool57_5", 0, -1, strTemp, "" )
	--技能
	local nSkillCount = Infant:GetMaxSkillNum()
	for i=1,nSkillCount do
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:Other_GetSkillInfo(0, i - 1)
		strTemp = ScriptGlobal_Format( "#{PFZY_140613_162}", nSkillLevel )
		if nSkillID <= 0 then
			strTemp = "#{PFZY_140613_159}"
			szSkillName = "#{PFZY_140613_159}"
		elseif bCmp then
			local _, nSkillLevel2 = Infant:GetInfantSkillInfo( 0, i - 1 )
			if nSkillLevel2 > nSkillLevel then
				strTemp = ScriptGlobal_Format( "#{PFZY_140613_162}", "#cFF0000"..nSkillLevel )
			end
		end
		TargetFightScore_AddGenericItem1( g_data.RightItems[2+i], szIcon, 0, -1, strTemp, szSkillName )
	end
	--卡牌类型
	local nInfantCardType = { "神兵", "锦装", "轻功", "良驹", "武决", "名饰" }
	--卡牌品质
	local nInfantCardQual =	{ "绿色", "蓝色", "紫色", "橙色", "金色" }
	--卡牌
	for i = 0, 5 do
		local cardItem = EnumAction( i, "otherinfantcard" )
		local actionID = cardItem:GetID()
		local cardQuality, cardLevel = Infant:Other_GetInfantCardInfo( 0, i )
		if actionID > 0 and cardQuality then
			strTemp = ScriptGlobal_Format( "#{PFZY_140613_168}", nInfantCardQual[cardQuality+1] )
			strTemp2 = ScriptGlobal_Format( "#{PFZY_140613_169}", cardLevel )
			if bCmp then
				local cardQuality2, cardLevel2 = Infant:GetInfantCardQuality(0, i), Infant:GetInfantCardYanDuLevel(0, i)
				if cardQuality2 and cardQuality2 > cardQuality then
					strTemp = ScriptGlobal_Format( "#{PFZY_140613_168}", "#cFF0000"..nInfantCardQual[cardQuality+1] )
				end
				if cardLevel2 and cardLevel2 > cardLevel then
					strTemp2 = ScriptGlobal_Format( "#{PFZY_140613_169}", "#cFF0000"..cardLevel )
				end
			end
			TargetFightScore_AddGenericItem1( g_data.RightItems[7+i], "set:TaskTools17 image:TaskTools17_3", 0, actionID, strTemp.."#r"..strTemp2, "" )
		else
			strTemp = ScriptGlobal_Format( "#{PFZY_140613_164}", nInfantCardType[i+1] )
			strTemp2 = ScriptGlobal_Format( "#{PFZY_140613_163}", nInfantCardType[i+1] )
			TargetFightScore_AddGenericItem1( g_data.RightItems[7+i], "set:TaskTools17 image:TaskTools17_3", 0, -1, strTemp, strTemp2 )
		end
	end
end

function TargetFightScore_UpdateRightInfant_My()
	if TargetFightScore_GetLevel(1) < 50 then
		TargetFightScore_AddGenericItem2( g_data.RightItems[1], "set:IMShow image:IMShow_13", 0, -1, "#{PFBJ_160106_23}", "#{PFZY_140613_152}" )
		return
	end
	if Infant:GetInfantCount() <= 0 then
		TargetFightScore_AddGenericItem2( g_data.RightItems[1], "set:IMShow image:IMShow_13", 0, -1, "#{PFZY_140613_152}", "" )
		return
	end
	local bCmp = false
	if Infant:Other_GetInfantCount() > 0 then
		bCmp = true
	end
	local strTemp,strTemp2 = "", ""
	--等级
	strTemp = ScriptGlobal_Format("#{PFZY_140613_156}", Infant:GetInfantLevel(0) )
	if bCmp and Infant:Other_GetInfantLevel(0) > Infant:GetInfantLevel(0) then
		strTemp = ScriptGlobal_Format("#{PFZY_140613_156}", "#cFF0000"..Infant:GetInfantLevel(0) )
	end
	TargetFightScore_AddGenericItem2( g_data.RightItems[1], "set:CircularTaskTool57 image:CircularTaskTool57_6", 0, -1, strTemp, "" )
	--综合素养
	local total_attr = 0
	for i=0,4 do
		total_attr = total_attr + Infant:GetInfantAttr( 0, i )
	end
	strTemp = ScriptGlobal_Format( "#{PFZY_140613_158}", total_attr )
	if bCmp then
		local total_attr2 = 0
		for i=0,4 do
			total_attr2 = total_attr2 + Infant:Other_GetInfantAttr( 0, i )
		end
		if total_attr2 > total_attr then
			strTemp = ScriptGlobal_Format( "#{PFZY_140613_158}", "#cFF0000"..total_attr )
		end
	end
	TargetFightScore_AddGenericItem2( g_data.RightItems[2], "set:CircularTaskTool57 image:CircularTaskTool57_5", 0, -1, strTemp, "" )
	--技能
	local nSkillCount = Infant:GetMaxSkillNum()
	for i=1,nSkillCount do
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(0, i - 1)
		strTemp = ScriptGlobal_Format( "#{PFZY_140613_162}", nSkillLevel )
		if nSkillID <= 0 then
			strTemp = "#{PFZY_140613_160}"
			szSkillName = "#{PFZY_140613_159}"
		elseif bCmp then
			local _, nSkillLevel2 = Infant:Other_GetSkillInfo( 0, i - 1 )
			if nSkillLevel2 > nSkillLevel then
				strTemp = ScriptGlobal_Format( "#{PFZY_140613_162}", "#cFF0000"..nSkillLevel )
			end
		end
		TargetFightScore_AddGenericItem2( g_data.RightItems[2+i], szIcon, 0, -1, strTemp, szSkillName )
	end
	--卡牌类型
	local nInfantCardType = { "神兵", "锦装", "轻功", "良驹", "武决", "名饰" }
	--卡牌品质
	local nInfantCardQual =	{ "绿色", "蓝色", "紫色", "橙色", "金色" }
	--卡牌
	for i = 0, 5 do
		local cardItem = EnumAction( i, "infantcard" )
		local actionID = cardItem:GetID()
		local cardQuality, cardLevel = Infant:GetInfantCardQuality(0, i), Infant:GetInfantCardYanDuLevel(0, i)
		if actionID > 0 and cardQuality then
			strTemp = ScriptGlobal_Format( "#{PFZY_140613_168}", nInfantCardQual[cardQuality+1] )
			strTemp2 = ScriptGlobal_Format( "#{PFZY_140613_169}", cardLevel )
			if bCmp then
				local cardQuality2, cardLevel2 = Infant:Other_GetInfantCardInfo( 0, i )
				if cardQuality2 and cardQuality2 > cardQuality then
					strTemp = ScriptGlobal_Format( "#{PFZY_140613_168}", "#cFF0000"..nInfantCardQual[cardQuality+1] )
				end
				if cardLevel2 and cardLevel2 > cardLevel then
					strTemp2 = ScriptGlobal_Format( "#{PFZY_140613_169}", "#cFF0000"..cardLevel )
				end
			end
			TargetFightScore_AddGenericItem2( g_data.RightItems[7+i], "set:TaskTools17 image:TaskTools17_3", 0, actionID, strTemp.."#r"..strTemp2, "" )
		else
			strTemp = ScriptGlobal_Format( "#{PFZY_140613_164}", nInfantCardType[i+1] )
			strTemp2 = ScriptGlobal_Format( "#{PFZY_140613_163}", nInfantCardType[i+1] )
			TargetFightScore_AddGenericItem2( g_data.RightItems[7+i], "set:TaskTools17 image:TaskTools17_3", 0, -1, strTemp, strTemp2 )
		end
	end
end

function TargetFightScore_UpdateRightInfant()
	if Infant:Other_GetInfantCount() <= 0 and ( g_data.CompareState == 0 or Infant:GetInfantCount() <= 0 ) then
		local ItemBar = nil
		if TargetFightScore_GetLevel(0) < 50 then
			ItemBar = TargetFightScore_NewGenericItem( "set:IMShow image:IMShow_13", 0, -1, "#{PFBJ_160106_23}", "" )
		else
			ItemBar = TargetFightScore_NewGenericItem( "set:IMShow image:IMShow_13", 0, -1, "#{PFZY_140613_152}", "" )
		end
		if g_data.CompareState == 1 then
			TargetFightScore_AddGenericItem2( ItemBar, "set:IMShow image:IMShow_13", 0, -1, "#{PFZY_140613_152}", "" )
		end
		TargetFightScore_FlashRight()
		return
	end
	for i = 1, 12 do
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	end
	TargetFightScore_UpdateRightInfant_Target()
	if g_data.CompareState == 1 then
		TargetFightScore_UpdateRightInfant_My()
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_UpdateRightWuhunPart( actionItem, actionItem2Cmp, showFunc, p )
	local czDict = { "普通","优秀","杰出","卓越","完美" }
	local actionID = actionItem:GetID()
	local actionID2 = -1
	if actionItem2Cmp then
		actionID2 = actionItem2Cmp:GetID()
	end
	
	local nNeedLevel,hasEm = 65,TargetFightScore_GetHasEm( p-1 )
	if hasEm == 1 then
		nNeedLevel = nNeedLevel - 10
	end

	if actionID > 0 then
		local colors = { "","","","","","","","" }
		local grade = -1
		if p == 1 then
			grade = CachedTarget:GetKfsData("Grade") + 1
		elseif p == 2 then
			grade = DataPool:GetEquipScore(18,-1)
		end
		if actionID2 > 0 then
			if p == 1 and DataPool:GetEquipScore(18,-1) > grade then
				colors[1] = "#cFF0000"
			end
			if p == 2 and ( CachedTarget:GetKfsData("Grade") + 1 ) > grade then
				colors[1] = "#cFF0000"
			end
		end
		showFunc( g_data.RightItems[1], "", 0, actionID, ScriptGlobal_Format( "#{PFZY_140613_100}",colors[1]..czDict[ grade ] ), "" )
		for i=1, 7 do
			local AttrLevel,IconName,AttrName = actionItem:GetEquipKfsAttrInfo(i-1)
			local ImageName = ""
			if not AttrLevel or AttrLevel <= 0 then
				showFunc( g_data.RightItems[i+1], ImageName, 0, -1, "#{PFZY_140613_102}", "#{PFBJ_160106_29}" )
			else
				if not IconName or IconName == "" then
					IconName, AttrName = "", ""
				else
					ImageName = TargetFightScore_MakeFullImageName(IconName)
				end
				if actionID2 > 0 then
					local AttrLevel2,_,_ = actionItem2Cmp:GetEquipKfsAttrInfo(i-1)
					if AttrLevel2 and AttrLevel2 > AttrLevel then
						colors[i+1] = "#cFF0000"
					end
				end
				local strTemp = ScriptGlobal_Format( "#{PFZY_140613_104}", colors[i+1]..AttrLevel )
				showFunc( g_data.RightItems[i+1], ImageName, 0, -1, strTemp, AttrName )
			end
		end		
	elseif TargetFightScore_GetLevel( p - 1 ) < nNeedLevel then
		showFunc( g_data.RightItems[1], "set:CommonFrame7 image:WuhunEquip", 0, -1, ScriptGlobal_Format( "#{PFBJ_160106_57}", nNeedLevel ), "" )
	else
		showFunc( g_data.RightItems[1], "set:CommonFrame7 image:WuhunEquip", 0, -1, "#{PFZY_140613_96}", "" )
	end
end

function TargetFightScore_UpdateRightWuhun()
	local WuHunAction,WuHunActionMy = EnumAction( 18, "targetequip" ), EnumAction( 18, "equip" )
	local actionID, actionID2 = WuHunAction:GetID(), WuHunActionMy:GetID()
	if actionID <= 0 and ( g_data.CompareState == 0 or actionID2 <= 0 ) then
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	else
		for i = 1, 8 do
			local ItemBar = TargetFightScore_NewRightItem()
			table.insert( g_data.RightItems, ItemBar )
		end
	end
	if g_data.CompareState == 1 and actionID2 > 0 then
		TargetFightScore_UpdateRightWuhunPart( WuHunAction, WuHunActionMy, TargetFightScore_AddGenericItem1, 1 )
	else
		TargetFightScore_UpdateRightWuhunPart( WuHunAction, nil, TargetFightScore_AddGenericItem1, 1 )
	end
	if g_data.CompareState == 1 then
		if actionID > 0 then
			TargetFightScore_UpdateRightWuhunPart( WuHunActionMy, WuHunAction, TargetFightScore_AddGenericItem2, 2 )
		else
			TargetFightScore_UpdateRightWuhunPart( WuHunActionMy, nil, TargetFightScore_AddGenericItem2, 2 )
		end
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_LwAttrLevel( attr )
	if attr > 0 then
		attr = math.floor( math.mod(attr,10) )
		if attr == 0 then
			attr = 10
		end
	end
	return attr
end

function TargetFightScore_UpdateRightLongWen()
	local LongWenAction, LongWenActionMy = EnumAction( 19, "targetequip" ), EnumAction( 19, "equip" )
	local hasEm1,hasEm2 = CachedTarget:GetEquipMasterFlag(), CachedTarget:GetMySelfEquipMasterFlag()
	local actionID,actionID2 = LongWenAction:GetID(), -1
	if g_data.CompareState == 1 then
		actionID2 = LongWenActionMy:GetID()
	end 
	if actionID <= 0 and actionID2 <= 0 then
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	else
		for i=1, 5 do
			local ItemBar = TargetFightScore_NewRightItem()
			table.insert( g_data.RightItems, ItemBar )
		end
	end
	
	local needLevel1,needLevel2 = 80, 80
	if hasEm1 == 1 then
		needLevel1 = needLevel1 - 10
	end
	if hasEm2 == 1 then
		needLevel2 = needLevel2 - 10
	end
	
	if actionID > 0 then
		--等级
		local nQuality, nLevel, nAttr1, nAttr2, nAttr3 = LongWenAction:GetEquipLongWenInfo()
		nAttr1, nAttr2, nAttr3 = TargetFightScore_LwAttrLevel(nAttr1), TargetFightScore_LwAttrLevel(nAttr2), TargetFightScore_LwAttrLevel(nAttr3)

		local colors = { "", "", "", "", "" }
		if actionID2 > 0 then
			local nQuality2, nLevel2, nAttr21, nAttr22, nAttr23 = LongWenActionMy:GetEquipLongWenInfo()
			nAttr21, nAttr22, nAttr23 = TargetFightScore_LwAttrLevel(nAttr21), TargetFightScore_LwAttrLevel(nAttr22), TargetFightScore_LwAttrLevel(nAttr23)
			if nLevel2 > nLevel then
				colors[1] = "#cFF0000"
			end
			if nQuality2 > nQuality then
				colors[2] = "#cFF0000"
			end
			if nAttr21 > nAttr1 then
				colors[3] = "#cFF0000"
			end
			if nAttr22 > nAttr2 then
				colors[4] = "#cFF0000"
			end
			if nAttr23 > nAttr3 then
				colors[5] = "#cFF0000"
			end
		end
		TargetFightScore_AddGenericItem1( g_data.RightItems[1], "set:MiniMap image:LongWen", 0, actionID, ScriptGlobal_Format("#{PFZY_140613_83}", colors[1]..nLevel), "" )
		--星级
		TargetFightScore_AddGenericItem1( g_data.RightItems[2], "set:CircularTaskTool33 image:CircularTaskTool33_5", 0, -1, ScriptGlobal_Format("#{PFZY_140613_86}", colors[2]..nQuality), "#{PFZY_140613_84}" )
		local lwDict = {
			{ icon="set:CircularTaskTool32 image:CircularTaskTool32_12", tips="#{PFZY_140613_87}" },
			{ icon="set:CircularTaskTool32 image:CircularTaskTool32_10", tips="#{PFZY_140613_88}" },
			{ icon="set:CircularTaskTool32 image:CircularTaskTool32_11", tips="#{PFZY_140613_89}" },
		}
		--扩展属性
		if nAttr1 > 0 then
			TargetFightScore_AddGenericItem1( g_data.RightItems[3], lwDict[1].icon, 0, -1, ScriptGlobal_Format("#{PFZY_140613_92}", colors[3]..nAttr1),  lwDict[1].tips )
		else
			TargetFightScore_AddGenericItem1( g_data.RightItems[3], lwDict[1].icon, 0, -1, "#{PFBJ_160106_37}",  lwDict[1].tips )
		end
		if nAttr2 > 0 then
			TargetFightScore_AddGenericItem1( g_data.RightItems[4], lwDict[2].icon, 0, -1, ScriptGlobal_Format("#{PFZY_140613_92}", colors[4]..nAttr2),  lwDict[2].tips )
		else
			TargetFightScore_AddGenericItem1( g_data.RightItems[4], lwDict[2].icon, 0, -1, "#{PFBJ_160106_37}",  lwDict[2].tips )
		end
		if nAttr3 > 0 then
			TargetFightScore_AddGenericItem1( g_data.RightItems[5], lwDict[3].icon, 0, -1, ScriptGlobal_Format("#{PFZY_140613_92}", colors[5]..nAttr3),  lwDict[3].tips )
		else
			TargetFightScore_AddGenericItem1( g_data.RightItems[5], lwDict[3].icon, 0, -1, "#{PFBJ_160106_37}",  lwDict[3].tips )
		end
	elseif TargetFightScore_GetLevel( 0 ) < needLevel1 then
		TargetFightScore_AddGenericItem1( g_data.RightItems[1], "set:MiniMap image:LongWen", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_56}", needLevel1), "" )
	else
		TargetFightScore_AddGenericItem1( g_data.RightItems[1], "set:MiniMap image:LongWen", 0, -1, "#{PFZY_140613_78}", "" )
	end
	
	if actionID2 > 0 then
		local nQuality2, nLevel2, nAttr21, nAttr22, nAttr23 = LongWenActionMy:GetEquipLongWenInfo()
		nAttr21, nAttr22, nAttr23 = TargetFightScore_LwAttrLevel(nAttr21), TargetFightScore_LwAttrLevel(nAttr22), TargetFightScore_LwAttrLevel(nAttr23)
		
		local colors = { "", "", "", "", "" }
		if actionID > 0 then
			local nQuality, nLevel, nAttr1, nAttr2, nAttr3 = LongWenAction:GetEquipLongWenInfo()
			Attr1, nAttr2, nAttr3 = TargetFightScore_LwAttrLevel(nAttr1), TargetFightScore_LwAttrLevel(nAttr2), TargetFightScore_LwAttrLevel(nAttr3)
			if nLevel2 < nLevel then
				colors[1] = "#cFF0000"
			end
			if nQuality2 < nQuality then
				colors[2] = "#cFF0000"
			end
			if nAttr21 < nAttr1 then
				colors[3] = "#cFF0000"
			end
			if nAttr22 < nAttr2 then
				colors[4] = "#cFF0000"
			end
			if nAttr23 < nAttr3 then
				colors[5] = "#cFF0000"
			end
		end
		TargetFightScore_AddGenericItem2( g_data.RightItems[1], "set:MiniMap image:LongWen", 0, actionID2, ScriptGlobal_Format("#{PFZY_140613_83}", colors[1]..nLevel2), "" )
		--星级
		TargetFightScore_AddGenericItem2( g_data.RightItems[2], "set:CircularTaskTool33 image:CircularTaskTool33_5", 0, -1, ScriptGlobal_Format("#{PFZY_140613_86}", colors[2]..nQuality2), "#{PFZY_140613_84}" )
		local lwDict = {
			{ icon="set:CircularTaskTool32 image:CircularTaskTool32_12", tips="#{PFZY_140613_87}" },
			{ icon="set:CircularTaskTool32 image:CircularTaskTool32_10", tips="#{PFZY_140613_88}" },
			{ icon="set:CircularTaskTool32 image:CircularTaskTool32_11", tips="#{PFZY_140613_89}" },
		}
		--扩展属性
		if nAttr21 > 0 then
			TargetFightScore_AddGenericItem2( g_data.RightItems[3], lwDict[1].icon, 0, -1, ScriptGlobal_Format("#{PFZY_140613_92}", colors[3]..nAttr21),  lwDict[1].tips )
		else
			TargetFightScore_AddGenericItem2( g_data.RightItems[3], lwDict[1].icon, 0, -1, "#{PFBJ_160106_37}",  lwDict[1].tips )
		end
		if nAttr22 > 0 then
			TargetFightScore_AddGenericItem2( g_data.RightItems[4], lwDict[2].icon, 0, -1, ScriptGlobal_Format("#{PFZY_140613_92}", colors[4]..nAttr22),  lwDict[2].tips )
		else
			TargetFightScore_AddGenericItem2( g_data.RightItems[4], lwDict[2].icon, 0, -1, "#{PFBJ_160106_37}",  lwDict[2].tips )
		end
		if nAttr23 > 0 then
			TargetFightScore_AddGenericItem2( g_data.RightItems[5], lwDict[3].icon, 0, -1, ScriptGlobal_Format("#{PFZY_140613_92}", colors[5]..nAttr23),  lwDict[3].tips )
		else
			TargetFightScore_AddGenericItem2( g_data.RightItems[5], lwDict[3].icon, 0, -1, "#{PFBJ_160106_37}",  lwDict[3].tips )
		end
	elseif g_data.CompareState == 1 then
		if TargetFightScore_GetLevel( 1 ) < needLevel2 then
			TargetFightScore_AddGenericItem2( g_data.RightItems[1], "set:MiniMap image:LongWen", 0, -1, ScriptGlobal_Format("#{PFBJ_160106_56}", needLevel2), "" )
		else
			TargetFightScore_AddGenericItem2( g_data.RightItems[1], "set:MiniMap image:LongWen", 0, -1, "#{PFZY_140613_78}", "" )
		end	
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_NewTargetJingTongItemNew( ItemBar, actionItem, actionItemMy, nImageListIndex  )
	local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", g_setting.EquipBasicInfo[nImageListIndex].name)
	local itemButton1 = ItemBar:GetLuaActionButton( 1, "TargetFightScore" )
	local levelTar,levelMy = CachedTarget:GetData("LEVEL"), Player:GetLevel()
	local hasEm1,hasEm2 = CachedTarget:GetEquipMasterFlag(), CachedTarget:GetMySelfEquipMasterFlag()
	itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
	itemButton1:Show()
	
	local actionID = actionItem:GetID()
	if actionID > 0 then
		itemButton1:SetActionItem(actionID)
		local l1,s1,l2,s2,l3,s3 = actionItem:GetEquipJingTongInfo()
		if levelTar < 80 or ( hasEm1 == 1 and levelTar < 70 ) then
			local tmpText = ""
			if hasEm1 == 1 then
				tmpText = ScriptGlobal_Format("#{PFBJ_160106_58}", 70 )
			else
				tmpText = ScriptGlobal_Format("#{PFBJ_160106_58}", 80 )
			end
			ItemBar:Setm_newText(1, tmpText )
			ItemBar:Setm_newTextShow(1)
		elseif not l1 then
			--未开启精通
			ItemBar:Setm_newText(1, "#{PFZY_140613_145}" )
			ItemBar:Setm_newTextShow(1)
		else
			local colors = {"","",""}
			if g_data.CompareState == 1 and actionItemMy:GetID() > 0 then
				local l1m,s1m,l2m,s2m,l3m,s3m = actionItemMy:GetEquipJingTongInfo()
				if l1m then
					if l1m > l1 then
						colors[1] = "#cFF0000"
					end
					if l2m > l2 then
						colors[2] = "#cFF0000"
					end
					if l3m > l3 then
						colors[3] = "#cFF0000"
					end
				end
			end
			ItemBar:Setm_newText( 13, "#{PFZY_140613_146}" )
			ItemBar:Setm_newTextShow(13)
			ItemBar:Setm_newText( 14, ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..s1.."}",colors[1]..l1 ) )
			ItemBar:Setm_newTextShow(14)
			ItemBar:Setm_newText( 15, ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..s2.."}",colors[2]..l2 ) )
			ItemBar:Setm_newTextShow(15)
			ItemBar:Setm_newText( 16, ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..s3.."}",colors[3]..l3 ) )
			ItemBar:Setm_newTextShow(16)
		end
	else
		local strTitle1 = "#cFF0000"..strNoEquipToolTips
		if levelTar < 80 or ( hasEm1 == 1 and levelTar < 70 ) then
			if hasEm1 == 1 then
				strTitle1 = ScriptGlobal_Format("#{PFBJ_160106_58}", 70 )
			else
				strTitle1 = ScriptGlobal_Format("#{PFBJ_160106_58}", 80 )
			end
		end
		TargetFightScore_AddGenericItem1( ItemBar, g_setting.EquipBasicInfo[nImageListIndex].back, 0, -1, strTitle1, strNoEquipToolTips )
	end
	
	if g_data.CompareState == 1 then
		local itemButton2 = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
		itemButton2:Show()
		local actionID2 = actionItemMy:GetID()
		if actionID2 > 0 then
			itemButton2:SetActionItem(actionID2)
			local l1m,s1m,l2m,s2m,l3m,s3m = actionItemMy:GetEquipJingTongInfo()
			if levelMy < 80 or ( hasEm2 == 1 and levelMy < 70 ) then
				local tmpText = ""
				if hasEm2 == 1 then
					tmpText = ScriptGlobal_Format("#{PFBJ_160106_58}", 70 )
				else
					tmpText = ScriptGlobal_Format("#{PFBJ_160106_58}", 80 )
				end
				ItemBar:Setm_newText( 22, tmpText )
				ItemBar:Setm_newTextShow( 22 )
			elseif not l1m then
				--未开启精通
				ItemBar:Setm_newText( 22, "#{PFZY_140613_145}" )
				ItemBar:Setm_newTextShow( 22 )
			else
				local colors = {"","",""}
				if actionID > 0 then
					local l1,s1,l2,s2,l3,s3 = actionItem:GetEquipJingTongInfo()
					if l1 then
						if l1m < l1 then
							colors[1] = "#cFF0000"
						end
						if l2m < l2 then
							colors[2] = "#cFF0000"
						end
						if l3m < l3 then
							colors[3] = "#cFF0000"
						end
					end
				end
				ItemBar:Setm_newText( 26, "#{PFZY_140613_146}" )
				ItemBar:Setm_newTextShow(26)
				ItemBar:Setm_newText( 27, ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..s1m.."}",colors[1]..l1m ) )
				ItemBar:Setm_newTextShow(27)
				ItemBar:Setm_newText( 28, ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..s2m.."}",colors[2]..l2m ) )
				ItemBar:Setm_newTextShow(28)
				ItemBar:Setm_newText( 29, ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..s3m.."}",colors[3]..l3m ) )
				ItemBar:Setm_newTextShow(29)
			end
		else
			local strTitle2 = "#cFF0000"..strNoEquipToolTips
			local strTitle2 = "#cFF0000"..strNoEquipToolTips
			if levelTar < 80 or ( hasEm2 == 1 and levelTar < 70 ) then
				if hasEm2 == 1 then
					strTitle2 = ScriptGlobal_Format("#{PFBJ_160106_58}", 70 )
				else
					strTitle2 = ScriptGlobal_Format("#{PFBJ_160106_58}", 80 )
				end
			end
			TargetFightScore_AddGenericItem2( ItemBar, g_setting.EquipBasicInfo[nImageListIndex].back, 0, -1, strTitle2, strNoEquipToolTips )
		end
	end
end

function TargetFightScore_UpdateRightJingTong()
	for i = 2, 13 do
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
		local tempEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "targetequip" )
		local tempEquipMy = EnumAction( g_setting.EquipBasicInfo[i].index, "equip" )
		TargetFightScore_NewTargetJingTongItemNew( ItemBar, tempEquip, tempEquipMy, i )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_NewTargetZhenYuanItemNew( ItemBar, actionItem, actionItemMy, nImageListIndex, ZhenYuanIndex  )
	local zyColorDict = { "白色","绿色","蓝色","紫色","橙色","金色" }
	local itemButton1 = ItemBar:GetLuaActionButton( 1, "TargetFightScore" )
	local levelTar,levelMy = CachedTarget:GetData("LEVEL"), Player:GetLevel()
	itemButton1:SetProperty( "BackImage", g_setting.EquipBasicInfo[nImageListIndex].back )
	itemButton1:Show()
	
	if not ZhenYuanIndex then
		return
	end
	
	local actionID = actionItem:GetID()
	if actionID > 0 then
		itemButton1:SetActionItem(actionID)
		local PneumaAction,bLocked = Pneuma:EnumPneumaItem( "targetpneuma", ZhenYuanIndex )
		local strTemp = ""
		if levelTar < 80 then
			strTemp = "#{PFBJ_160106_41}"
		elseif bLocked == 1 or PneumaAction:GetID() <= 0 then
			strTemp = "#{PFZY_140613_72}"
		else
			local curLevel = Pneuma:GetTargetPneumaItemProperty( ZhenYuanIndex, 4 )
			local curQua = Pneuma:GetTargetPneumaItemProperty( ZhenYuanIndex, 2 )
			local colors = {"#G","#G"}
			if g_data.CompareState == 1 then
				local PneumaAction2,bLocked2 = Pneuma:EnumPneumaItem( "pneuma", ZhenYuanIndex )
				if bLocked2 ~= 1 and PneumaAction:GetID() > 0 then
					local curLevel2 = Pneuma:GetPneumaProperty( ZhenYuanIndex, 4 )
					local curQua2 = Pneuma:GetPneumaProperty( ZhenYuanIndex, 2 )
					if curQua2 > curQua then
						colors[1] = "#cFF0000"
					end
					if curLevel2 > curLevel then
						colors[2] = "#cFF0000"
					end
				end
			end
			strTemp = ScriptGlobal_Format( "#{PFZY_140613_74}", colors[1]..zyColorDict[curQua], colors[2]..curLevel )
		end
		ItemBar:Setm_newText(1, strTemp )
		ItemBar:Setm_newTextShow(1)
	else
		local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", g_setting.EquipBasicInfo[nImageListIndex].name)
		local strContent = "#cFF0000"..strNoEquipToolTips
		if levelTar < 80 then
			strContent = "#{PFBJ_160106_41}"
		end
		TargetFightScore_AddGenericItem1( ItemBar, g_setting.EquipBasicInfo[nImageListIndex].back, 0, -1, strContent, strNoEquipToolTips )
	end
	
	if g_data.CompareState == 1 then
		local itemButton2 = ItemBar:GetLuaActionButton( 6, "TargetFightScore" )
		itemButton2:Show()
		local actionID2 = actionItemMy:GetID()
		local strTemp = ""
		if actionID2 > 0 then
			itemButton2:SetActionItem(actionID2)
			local PneumaAction2,bLocked2 = Pneuma:EnumPneumaItem( "pneuma", ZhenYuanIndex )
			if levelMy < 80 then
				strTemp = "#{PFBJ_160106_41}"
			elseif bLocked2 == 1 or PneumaAction2:GetID() <= 0 then
				strTemp = "#{PFZY_140613_72}"
			else
				local curLevel2 = Pneuma:GetPneumaProperty( ZhenYuanIndex, 4 )
				local curQua2 = Pneuma:GetPneumaProperty( ZhenYuanIndex, 2 )
				local colors = {"#G","#G"}
				if g_data.CompareState == 1 then
					local PneumaAction,bLocked = Pneuma:EnumPneumaItem( "targetpneuma", ZhenYuanIndex )
					if bLocked ~= 1 and PneumaAction:GetID() > 0 then
						local curLevel = Pneuma:GetTargetPneumaItemProperty( ZhenYuanIndex, 4 )
						local curQua = Pneuma:GetTargetPneumaItemProperty( ZhenYuanIndex, 2 )
						if curQua2 < curQua then
							colors[1] = "#cFF0000"
						end
						if curLevel2 < curLevel then
							colors[2] = "#cFF0000"
						end
					end
				end
				strTemp = ScriptGlobal_Format( "#{PFZY_140613_74}", colors[1]..zyColorDict[curQua2], colors[2]..curLevel2 )
			end
			ItemBar:Setm_newText(22, strTemp )
			ItemBar:Setm_newTextShow(22)
		else
			local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", g_setting.EquipBasicInfo[nImageListIndex].name)
			local strContent = "#cFF0000"..strNoEquipToolTips
			if levelMy < 80 then
				strContent = "#{PFBJ_160106_41}"
			end
			TargetFightScore_AddGenericItem2( ItemBar, g_setting.EquipBasicInfo[nImageListIndex].back, 0, -1, strContent, strNoEquipToolTips )
		end
	end
end

function TargetFightScore_UpdateRightZhenYuan()
	for i=2,13 do
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
		local tempEquip = EnumAction( g_setting.EquipBasicInfo[i].index, "targetequip" )
		local tempEquipMy = EnumAction( g_setting.EquipBasicInfo[i].index, "equip" )
		TargetFightScore_NewTargetZhenYuanItemNew( ItemBar, tempEquip, tempEquipMy, i, g_setting.EquipBasicInfo[i].ZhenYuanIndex )
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_MakeFullImageName(ImageName)
	local Temp =""
	if ImageName ~= nil and ImageName ~= "" then
		local sPos, ePos = string.find(ImageName, "_")
		if sPos ~= nil then
			local filename = string.sub(ImageName, 0, sPos-1)
			Temp = string.format("set:%s image:%s", filename, ImageName)
		end
	end
	return Temp
end

function TargetFightScore_UpdateRightLingPaiPart( actionItem, actionItem2Cmp, objtype )
	local showFunc = TargetFightScore_AddGenericItem1
	if objtype == 1 then
		showFunc = TargetFightScore_AddGenericItem2
	end
	local ObjLevel = TargetFightScore_GetLevel(objtype)
	local actionID = actionItem:GetID()
	if actionID > 0 then
		local LingPaiName = actionItem:GetName()
		local NameColor = "#G"
		if actionItem2Cmp and actionItem2Cmp:GetID() > 0 and actionItem2Cmp:GetDefineID() > actionItem:GetDefineID() then
			NameColor = "#cFF0000"
		end
		showFunc( g_data.RightItems[1], "", 0, actionID, ScriptGlobal_Format("#{PFZY_140613_187}",NameColor..LingPaiName), "" )
		local quality, infos = actionItem:GetEquipLingPaiInfo()
		if quality and infos then
			local colors = {"","","","",""}
			if actionItem2Cmp then
				local quality2, infos2 = actionItem2Cmp:GetEquipLingPaiInfo()
				if quality2 and infos2 then
					if quality2 > quality then
						colors[5] = "#cFF0000"
					end
					for i=1,4 do
						if infos2[i] and infos[i] then
							if infos2[i][1] > infos[i][1] then
								colors[i] = "#cFF0000"
							end
						end
					end
				end
			end
			for i=1,4 do
				if infos[i] then
					local level, szicon, sztips = infos[i][1], TargetFightScore_MakeFullImageName(infos[i][2]), infos[i][3]
					local showTemp = ScriptGlobal_Format( "#{PFZY_140613_190}", colors[i]..level )
					showFunc( g_data.RightItems[i+1], szicon, 0, -1, showTemp, sztips )
				else
					showFunc( g_data.RightItems[i+1], "", 0, -1,"#{PFZY_140613_188}", "" )
				end
			end
			showFunc( g_data.RightItems[6], "set:CircularTaskTool60 image:CircularTaskTool60_15", 0, -1, ScriptGlobal_Format("#{PFZY_140613_192}", colors[5]..quality ), "" )
		end
		
	else
		if ObjLevel < 80 then
			showFunc( g_data.RightItems[1], g_setting.EquipBasicInfo[17].back, 0, -1, "#{PFBJ_160106_45}", "" )
		else
			showFunc( g_data.RightItems[1], g_setting.EquipBasicInfo[17].back, 0, -1, "#{PFBJ_160106_44}", "" )
		end
	end
end

function TargetFightScore_UpdateRightLingPai()
	local LingPaiAction,LingPaiActionMy = EnumAction( 20, "targetequip" ), EnumAction( 20, "equip" )
	local actionID, actionID2 = LingPaiAction:GetID(), LingPaiActionMy:GetID()
	if actionID <= 0 and ( g_data.CompareState == 0 or actionID2 <= 0 ) then
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	else
		for i = 1, 6 do
			local ItemBar = TargetFightScore_NewRightItem()
			table.insert( g_data.RightItems, ItemBar )
		end
	end
	if g_data.CompareState == 1 and actionID2 > 0 then
		TargetFightScore_UpdateRightLingPaiPart( LingPaiAction, LingPaiActionMy, 0 )
	else
		TargetFightScore_UpdateRightLingPaiPart( LingPaiAction, nil, 0 )
	end
	if g_data.CompareState == 1 then
		if actionID > 0 then
			TargetFightScore_UpdateRightLingPaiPart( LingPaiActionMy, LingPaiAction, 1 )
		else
			TargetFightScore_UpdateRightLingPaiPart( LingPaiActionMy, nil, 1 )
		end
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_GetHXYAttrLevel( objtype, i )
	if objtype == 0 then
		local nIndex , iEffectLevel, iCost , iNeedHXYLevel , iValue = CachedTarget:Lua_GetHXYEffect( i - 1 )
		if nIndex ~= nil then
			return iEffectLevel
		end
	elseif objtype == 1 then
		local nIndex , iEffectLevel, iCost , iNeedHXYLevel , iValue = DataPool:Lua_GetHXYEffect( i - 1 )
		if nIndex ~= nil then
			return iEffectLevel
		end
	end
	return 0
end


function TargetFightScore_UpdateRightXiaYinPart( actionItem, actionItem2Cmp, objtype )
	local showFunc = TargetFightScore_AddGenericItem1
	if objtype == 1 then
		showFunc = TargetFightScore_AddGenericItem2
	end
	local ObjLevel = TargetFightScore_GetLevel(objtype)
	local actionID = actionItem:GetID()
	local icondic = {
		"set:JunXian1 image:JunXian1_1",
		"set:JunXian1 image:JunXian1_6",
		"set:JunXian1 image:JunXian1_5",
		"set:JunXian1 image:JunXian1_2",
		"set:JunXian1 image:JunXian1_4",
		"set:JunXian1 image:JunXian1_3",
		"set:JunXian1 image:JunXian1_7",
	}
	local tipsdic = {
		"#{JXJW_140922_12}",
		"#{JXJW_140922_14}",
		"#{JXJW_140922_13}",
		"#{JXJW_140922_11}",
		"#{JXJW_140922_16}",
		"#{JXJW_140922_17}",
		"#{JXJW_140922_15}",
	}
	if actionID > 0 then
		local LevelColor,propsColor = "#G","#G"
		if actionItem2Cmp and actionItem2Cmp:GetID() > 0 and actionItem2Cmp:GetEquipHXYLevel() > actionItem:GetEquipHXYLevel() then
			LevelColor = "#cFF0000"
		end
		local nProps,nProps2 = 0,0
		for i=1,7 do
			local lv = TargetFightScore_GetHXYAttrLevel( objtype, i )
			local lv2 = TargetFightScore_GetHXYAttrLevel( 1 - objtype, i )
			local c2 = "#G"
			if lv2 > lv then
				c2 = "#cFF0000"
			end
			if lv2 > 0 then
				nProps2 = nProps2 + 1
			end
			if lv == 0 then
				showFunc( g_data.RightItems[i+2], icondic[i], 0, -1, "#{PFBJ_160106_53}", "#{PFBJ_160106_53}" )
			else
				showFunc( g_data.RightItems[i+2], icondic[i], 0, -1, "#{PFBJ_160106_52}"..c2..lv, tipsdic[i] )
				nProps = nProps + 1
			end
		end
		if nProps2 > nProps then
			propsColor = "#cFF0000"
		end
		showFunc( g_data.RightItems[2], "", 0, actionID, ScriptGlobal_Format( "#{PFBJ_160106_69}",propsColor..nProps), "" )
		showFunc( g_data.RightItems[1], "", 0, actionID, "#{PFBJ_160106_52}"..LevelColor..actionItem:GetEquipHXYLevel(), "" )
	else
		if ObjLevel < 85 then
			showFunc( g_data.RightItems[1], g_setting.EquipBasicInfo[17].back, 0, -1, "#{PFBJ_160106_50}", "" )
		else
			showFunc( g_data.RightItems[1], g_setting.EquipBasicInfo[17].back, 0, -1, "#{PFBJ_160106_49}", "" )
		end
	end
end

function TargetFightScore_UpdateRightXiaYin()
	local XiaYinAction,XiaYinActionMy = EnumAction( 21, "targetequip" ), EnumAction( 21, "equip" )
	local actionID, actionID2 = XiaYinAction:GetID(), XiaYinActionMy:GetID()
	if actionID <= 0 and ( g_data.CompareState == 0 or actionID2 <= 0 ) then
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	else
		for i = 1, 9 do
			local ItemBar = TargetFightScore_NewRightItem()
			table.insert( g_data.RightItems, ItemBar )
		end
	end
	if g_data.CompareState == 1 and actionID2 > 0 then
		TargetFightScore_UpdateRightXiaYinPart( XiaYinAction, XiaYinActionMy, 0 )
	else
		TargetFightScore_UpdateRightXiaYinPart( XiaYinAction, nil, 0 )
	end
	if g_data.CompareState == 1 then
		if actionID > 0 then
			TargetFightScore_UpdateRightXiaYinPart( XiaYinActionMy, XiaYinAction, 1 )
		else
			TargetFightScore_UpdateRightXiaYinPart( XiaYinActionMy, nil, 1 )
		end
	end
	TargetFightScore_FlashRight()
end

function TargetFightScore_UpdateRightMartial()

	for i=1,3 do
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	end
	local bMyOpenMartial = MaritialSys:HasFinishWuYiMisson() 
	local bTargetOpenMartial = MaritialSys:HasFinishWuYiMisson("other") 
	


	--武意等级
	local myLevel = MaritialSys:GetMaritiaLevel()
	local TargetLevel = MaritialSys:GetMaritiaLevel("other")
	local myLevelStr = ScriptGlobal_Format("#{PFBJ_170911_03}",myLevel)
	local TargetLevelStr = ScriptGlobal_Format("#{PFBJ_170911_13}",TargetLevel)
	if(myLevel >= TargetLevel) then
		myLevelStr = ScriptGlobal_Format("#{PFBJ_170911_13}",myLevel)
		TargetLevelStr = ScriptGlobal_Format("#{PFBJ_170911_03}",TargetLevel)
	end
	if(bMyOpenMartial == 1) then
		TargetFightScore_AddGenericItem2(g_data.RightItems[1], "set:Ach_Icon image:Ach_Icon_14", 0, -1, myLevelStr, "" )
	else
		TargetFightScore_AddGenericItem2(g_data.RightItems[1], "set:Ach_Icon image:Ach_Icon_14", 0, -1, "#{PFBJ_170911_01}", "#{PFBJ_170911_01}" )
	end
	if(bTargetOpenMartial == 1) then
		TargetFightScore_AddGenericItem1(g_data.RightItems[1], "set:Ach_Icon image:Ach_Icon_14", 0, -1, TargetLevelStr, "" )
	else
		TargetFightScore_AddGenericItem1(g_data.RightItems[1], "set:Ach_Icon image:Ach_Icon_14", 0, -1, "#{PFBJ_170911_01}", "#{PFBJ_170911_01}" )
	end
	--武意潜灵
	local myAlreadyPoint = MaritialSys:GetMaritiaAlreadyPoint()
	local TargetAlreadyPoint = MaritialSys:GetMaritiaAlreadyPoint("other")
	local myattrStr = ScriptGlobal_Format("#{PFBJ_170911_15}",myAlreadyPoint)
	local TargetattrStr = ScriptGlobal_Format("#{PFBJ_170911_16}",TargetAlreadyPoint)
	if(myAlreadyPoint >= TargetAlreadyPoint) then
		myattrStr = ScriptGlobal_Format("#{PFBJ_170911_16}",myAlreadyPoint)
		TargetattrStr = ScriptGlobal_Format("#{PFBJ_170911_15}",TargetAlreadyPoint)
	end
	if(bMyOpenMartial == 1) then
		TargetFightScore_AddGenericItem2(g_data.RightItems[2], "set:CircularTaskTool88 image:CircularTaskTool88_14", 0, -1, myattrStr, "" )
	end
	if(bTargetOpenMartial == 1) then
		TargetFightScore_AddGenericItem1(g_data.RightItems[2], "set:CircularTaskTool88 image:CircularTaskTool88_14", 0, -1, TargetattrStr, "" )
	end
	--武意培元
	local myAleardyTalentPoint = 0
	local TargetAleardyTalentPoint = 0
	for i=1,5 do
		local nId,nLevel = MaritialSys:GetTalentLevelBylayerID(i - 1)
		local nId1,nLevel1 = MaritialSys:GetTalentLevelBylayerID(i - 1,"other")
		myAleardyTalentPoint = myAleardyTalentPoint + nLevel
		TargetAleardyTalentPoint = TargetAleardyTalentPoint + nLevel1
	end
	local myTalentStr = ScriptGlobal_Format("#{PFBJ_170911_18}",myAleardyTalentPoint)
	local TargetTalentStr = ScriptGlobal_Format("#{PFBJ_170911_19}",TargetAleardyTalentPoint)
	if(myAleardyTalentPoint >= TargetAleardyTalentPoint) then
		myTalentStr = ScriptGlobal_Format("#{PFBJ_170911_19}",myAleardyTalentPoint)
		TargetTalentStr = ScriptGlobal_Format("#{PFBJ_170911_18}",TargetAleardyTalentPoint)
	end
	if(bMyOpenMartial == 1) then
		TargetFightScore_AddGenericItem2(g_data.RightItems[3], "set:CircularTaskTool88 image:CircularTaskTool88_15", 0, -1, myTalentStr, "" )
	end
	if(bTargetOpenMartial == 1) then
		TargetFightScore_AddGenericItem1(g_data.RightItems[3], "set:CircularTaskTool88 image:CircularTaskTool88_15", 0, -1, TargetTalentStr, "" )
	end

	TargetFightScore_FlashRight()
end

local g_XingZhenQualText = {
	"#{PFBJ_200424_05}",
	"#{PFBJ_200424_04}",
	"#{PFBJ_200424_06}",
	"#{PFBJ_200424_07}",
}

local g_XingZhenNumText = {
	"#{PFBJ_200424_08}",
	"#{PFBJ_200424_09}",
	"#{PFBJ_200424_10}",
	"#{PFBJ_200424_11}",
	"#{PFBJ_200424_12}",
	"#{PFBJ_200424_13}",
}

local g_XingJuanImg = {
	"set:TaskTools18 image:TaskTools18_14",
	"set:TaskTools18 image:TaskTools18_13",
	"set:TaskTools18 image:TaskTools18_15",
	"set:TaskTools18 image:TaskTools18_16",
}

local g_SkillCardImg = {
	"set:Rune02 image:Rune02_16",
	"set:Rune03 image:Rune03_7",
	"set:Rune02 image:Rune02_5",
	"set:Rune01 image:Rune01_8",
}

function TargetFightScore_UpdateRightXingZhen()
	
	local nTargetLevel = CachedTarget:GetData("LEVEL")
	local nMyLevel = Player:GetLevel()
	
	local strRed = "#cff0000"
	local strGreen = "#G"
	
	if nMyLevel < 75 and nTargetLevel < 75 then
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )		
		TargetFightScore_AddGenericItem1(ItemBar, "", 0, -1, "#{PFBJ_200424_01}", "" )
		TargetFightScore_AddGenericItem2(ItemBar, "", 0, -1, "#{PFBJ_200424_01}", "" )
		TargetFightScore_FlashRight()
		return
	end
	
	for i = 1, 16 do
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert( g_data.RightItems, ItemBar )
	end
	
	local cur_index = 0
	
	for i = 1, 4 do	
		
		local myXingJuanID = 0
		local myQuality = 0
		local myOrder = 0
		
		local tarXingJuanID = 0
		local tarQuality = 0
		local tarOrder = 0
		
		if nMyLevel >= 75 then
			myXingJuanID = DataPool:LuaFnGetActivedXingJuanID(i)		
			if myXingJuanID > 0 then
				myOrder = DataPool:LuaFnGetXingJuanInfo(myXingJuanID, "Order")
				myQuality = DataPool:LuaFnGetXingJuanInfo(myXingJuanID, "Quality")
			end
		end
		
		if nTargetLevel >= 75 then
			tarXingJuanID = CachedTarget:LuaFnGetActivedXingJuanID(i)		
			if tarXingJuanID > 0 then
				tarOrder = CachedTarget:LuaFnGetXingJuanInfo(tarXingJuanID, "Order")
				tarQuality = CachedTarget:LuaFnGetXingJuanInfo(tarXingJuanID, "Quality")
			end
		end
		
		if nMyLevel >= 75 then	
			if myXingJuanID > 0 then				
				local theAction = EnumAction(myXingJuanID,"xingjuan")
				local strTemp = ""
				local strColor = strGreen
				if myQuality > tarQuality then
					strColor = strGreen
				elseif myQuality < tarQuality then
					strColor = strRed
				elseif myOrder > tarOrder then
					strColor = strGreen
				elseif myOrder < tarOrder then
					strColor = strRed
				end
				
				if myQuality >= 1 and myQuality <= 4 and myOrder >= 0 and myOrder <= 5 then
					strTemp = ScriptGlobal_Format("#{PFBJ_200424_02}", strColor..g_XingZhenQualText[myQuality], g_XingZhenNumText[myOrder + 1])
				end			
				TargetFightScore_AddXingZhenItem2(g_data.RightItems[i + cur_index], theAction:GetID(), strTemp)
			else
				TargetFightScore_AddGenericItem2(g_data.RightItems[i + cur_index], "", 0, -1, "#{PFBJ_200424_14}", "")
			end
		else
			TargetFightScore_AddGenericItem2(g_data.RightItems[i + cur_index], "", 0, -1, "#{PFBJ_200424_01}", "" )
		end
		
		if nTargetLevel >= 75 then
			if tarXingJuanID > 0 then
				local theAction = EnumAction(tarXingJuanID,"otherxingjuan")
				local strTemp = ""
				local strColor = strGreen
				if myQuality > tarQuality then
					strColor = strRed
				elseif myQuality < tarQuality then
					strColor = strGreen
				elseif myOrder > tarOrder then
					strColor = strRed
				elseif myOrder < tarOrder then
					strColor = strGreen
				end
				
				if tarQuality >= 1 and tarQuality <= 4 and tarOrder >= 0 and tarOrder <= 5 then
					strTemp = ScriptGlobal_Format("#{PFBJ_200424_02}", strColor..g_XingZhenQualText[tarQuality], g_XingZhenNumText[tarOrder + 1])
				end			
				TargetFightScore_AddXingZhenItem1(g_data.RightItems[i + cur_index], theAction:GetID(), strTemp)
			else
				TargetFightScore_AddGenericItem1(g_data.RightItems[i + cur_index], "", 0, -1, "#{PFBJ_200424_14}", "")
			end
		else
			TargetFightScore_AddGenericItem1(g_data.RightItems[i + cur_index], "", 0, -1, "#{PFBJ_200424_01}", "" )
		end
	end
	
	cur_index = 4
	
	for i = 1, 4 do	
		
		local mySkillCardID = 0
		local myQuality = 0
		local myLevel = 0
		
		local tarSkillCardID = 0
		local tarQuality = 0
		local tarLevel = 0
		
		if nMyLevel >= 75 then
			mySkillCardID = DataPool:LuaFnGetActivedSkillCardID(i)
			if mySkillCardID > 0 then
				myLevel = DataPool:LuaFnGetSkillCardInfo(mySkillCardID, "Level")
				myQuality = DataPool:LuaFnGetSkillCardInfo(mySkillCardID, "Quality")	
			end
		end
		
		if nTargetLevel >= 75 then
			tarSkillCardID = CachedTarget:LuaFnGetActivedSkillCardID(i)
			if tarSkillCardID > 0 then
				tarLevel = CachedTarget:LuaFnGetSkillCardInfo(tarSkillCardID, "Level")
				tarQuality = CachedTarget:LuaFnGetSkillCardInfo(tarSkillCardID, "Quality")	
			end
		end
		
		if nMyLevel >= 75 then
			if mySkillCardID > 0 then
				local theAction = EnumAction(mySkillCardID,"skillcard")
				local strTemp = ""
				local strColor = strGreen
				if myQuality > tarQuality then
					strColor = strGreen
				elseif myQuality < tarQuality then
					strColor = strRed
				elseif myLevel > tarLevel then
					strColor = strGreen
				elseif myLevel < tarLevel then
					strColor = strRed
				end
				
				if myQuality >= 1 and myQuality <= 4 and myLevel >= 1 and myLevel <= 5 then
					strTemp = ScriptGlobal_Format("#{PFBJ_200424_03}", strColor..g_XingZhenQualText[myQuality], g_XingZhenNumText[myLevel + 1])
				end			
				TargetFightScore_AddXingZhenItem2(g_data.RightItems[i + cur_index], theAction:GetID(), strTemp)
			else
				TargetFightScore_AddGenericItem2(g_data.RightItems[i + cur_index], "", 0, -1, "#{PFBJ_200424_15}", "")
			end
		else
			TargetFightScore_AddGenericItem2(g_data.RightItems[i + cur_index], "", 0, -1, "#{PFBJ_200424_01}", "")
		end
		
		if nTargetLevel >= 75 then
			if tarSkillCardID > 0 then
				local theAction = EnumAction(tarSkillCardID,"otherskillcard")
				local strTemp = ""
				local strColor = strGreen
				if myQuality > tarQuality then
					strColor = strRed
				elseif myQuality < tarQuality then
					strColor = strGreen
				elseif myLevel > tarLevel then
					strColor = strRed
				elseif myLevel < tarLevel then
					strColor = strGreen
				end
				
				if tarQuality >= 1 and tarQuality <= 4 and tarLevel >= 1 and tarLevel <= 5 then
					strTemp = ScriptGlobal_Format("#{PFBJ_200424_03}", strColor..g_XingZhenQualText[tarQuality], g_XingZhenNumText[tarLevel + 1])
				end			
				TargetFightScore_AddXingZhenItem1(g_data.RightItems[i + cur_index], theAction:GetID(), strTemp)
			else
				TargetFightScore_AddGenericItem1(g_data.RightItems[i + cur_index], "", 0, -1, "#{PFBJ_200424_15}", "")
			end
		else
			TargetFightScore_AddGenericItem1(g_data.RightItems[i + cur_index], "", 0, -1, "#{PFBJ_200424_01}", "" )
		end
	end
	
	cur_index = 8
	
	local strText = {"#{PFBJ_200424_16}", "#{PFBJ_200424_17}", "#{PFBJ_200424_18}", "#{PFBJ_200424_19}"}

	for i = 1, 4 do
		
		local valid_count = 0
		
		local my_collect_count = 0
		local my_uporder_count = 0
		
		local tar_collect_count = 0
		local tar_uporder_count = 0
		
		local index = 4 - i + 1	
		
		if nMyLevel >= 75 then
			valid_count, my_collect_count, my_uporder_count = DataPool:LuaFnXingJuanCollection(index)
		end
		
		if nTargetLevel >= 75 then
			valid_count, tar_collect_count, tar_uporder_count = CachedTarget:LuaFnXingJuanCollection(index)
		end
		
		if nMyLevel >= 75 then			
			
			local strColor1 = strGreen
			local strColor2 = strGreen			

			if my_collect_count < tar_collect_count then
				strColor1 = strRed
			end
			
			if my_uporder_count < tar_uporder_count then
				strColor2 = strRed
			end
			
			local strTemp = ScriptGlobal_Format(strText[i], strColor1..tostring(my_collect_count), tostring(valid_count), strColor2..tostring(my_uporder_count))
			TargetFightScore_AddGenericItem2(g_data.RightItems[i + cur_index], g_XingJuanImg[index], 0, -1, strTemp, "")
		else
			TargetFightScore_AddGenericItem2(g_data.RightItems[i + cur_index], g_XingJuanImg[index], 0, -1, "#{PFBJ_200424_01}", "")
		end
		
		if nTargetLevel >= 75 then
		
			local strColor1 = strGreen
			local strColor2 = strGreen
			
			if my_collect_count > tar_collect_count then
				strColor1 = strRed
			end
			
			if my_uporder_count > tar_uporder_count then
				strColor2 = strRed
			end
			
			local strTemp = ScriptGlobal_Format(strText[i], strColor1..tostring(tar_collect_count), tostring(valid_count), strColor2..tostring(tar_uporder_count))
			TargetFightScore_AddGenericItem1(g_data.RightItems[i + cur_index], g_XingJuanImg[index], 0, -1, strTemp, "")
		else
			TargetFightScore_AddGenericItem1(g_data.RightItems[i + cur_index], g_XingJuanImg[index], 0, -1, "#{PFBJ_200424_01}", "")
		end
	end
	
	cur_index = 12
	
	strText = {"#{PFBJ_200424_20}", "#{PFBJ_200424_21}", "#{PFBJ_200424_22}", "#{PFBJ_200424_23}"}
	for i = 1, 4 do
		
		local valid_count = 0
		
		local my_collect_count = 0
		local my_uplevel_count = 0
		
		local tar_collect_count = 0
		local tar_uplevel_count = 0
		
		local index = 4 - i + 1	
		
		if nMyLevel >= 75 then			
			valid_count, my_collect_count, my_uplevel_count = DataPool:LuaFnSkillCardCollection(index)
		end
		
		if nTargetLevel >= 75 then
			valid_count, tar_collect_count, tar_uplevel_count = CachedTarget:LuaFnSkillCardCollection(index)
		end		
		
		if nMyLevel >= 75 then
		
			local strColor1 = strGreen
			local strColor2 = strGreen
			
			if my_collect_count < tar_collect_count then
				strColor1 = strRed
			end
			
			if my_uplevel_count < tar_uplevel_count then
				strColor2 = strRed
			end
			
			local strTemp = ScriptGlobal_Format(strText[i], strColor1..tostring(my_collect_count), tostring(valid_count), strColor2..tostring(my_uplevel_count))
			TargetFightScore_AddGenericItem2(g_data.RightItems[i + cur_index], g_SkillCardImg[index], 0, -1, strTemp, "")
		else
			TargetFightScore_AddGenericItem2(g_data.RightItems[i + cur_index], g_SkillCardImg[index], 0, -1, "#{PFBJ_200424_01}", "")
		end
		
		if nTargetLevel >= 75 then
			
			local strColor1 = strGreen
			local strColor2 = strGreen
			
			if my_collect_count > tar_collect_count then
				strColor1 = strRed
			end
			
			if my_uplevel_count > tar_uplevel_count then
				strColor2 = strRed
			end
			
			local strTemp = ScriptGlobal_Format(strText[i], strColor1..tostring(tar_collect_count), tostring(valid_count), strColor2..tostring(tar_uplevel_count))
			TargetFightScore_AddGenericItem1(g_data.RightItems[i + cur_index], g_SkillCardImg[index], 0, -1, strTemp, "")
		else
			TargetFightScore_AddGenericItem1(g_data.RightItems[i + cur_index], g_SkillCardImg[index], 0, -1, "#{PFBJ_200424_01}", "")
		end
	end

	TargetFightScore_FlashRight()
end

function TargetFightScore_AddXingZhenItem1(ItemBar, nActionID, strText)
	if not ItemBar then
		return
	end
	local ItemButton  = ItemBar:GetLuaActionButton(1,"TargetFightScore")
	if ItemButton == nil then
		return
	end
	ItemButton:SetActionItem(nActionID)
	ItemButton:Show()
	ItemBar:Setm_newText(1, strText)
	ItemBar:Setm_newTextShow(1)

end

function TargetFightScore_AddXingZhenItem2(ItemBar, nActionID, strText)
	if not ItemBar then
		return
	end
	local ItemButton  = ItemBar:GetLuaActionButton(6, "TargetFightScore")
	if ItemButton == nil then
		return
	end

	ItemButton:SetActionItem(nActionID)

	ItemButton:Show()
	ItemBar:Setm_newText(22, strText)
	ItemBar:Setm_newTextShow(22)
end

local g_UA_Rank_Name = {
	"#{PFZY_220915_07}",
	"#{PFZY_220915_08}",
	"#{PFZY_220915_09}",
	"#{PFZY_220915_10}",
	"#{PFZY_220915_11}",
	"#{PFZY_220915_12}",
}

function TargetFightScore_AddUnderArmourItem1(ItemBar, strBackImage, action_item_id, strText)
	if not ItemBar then
		return
	end

	local ItemButton  = ItemBar:GetLuaActionButton(1, "TargetFightScore")
	if ItemButton == nil then
		return
	end
	
	ItemButton:SetProperty("BackImage", strBackImage)
	ItemButton:SetActionItem(action_item_id)
	ItemButton:Show()
	
	ItemBar:Setm_newText(1, strText)
	ItemBar:Setm_newTextShow(1)
end

function TargetFightScore_AddUnderArmourItem2(ItemBar, strBackImage, action_item_id, strText)
	if not ItemBar then
		return
	end

	local ItemButton  = ItemBar:GetLuaActionButton(6, "TargetFightScore")
	if ItemButton == nil then
		return
	end
	
	ItemButton:SetProperty("BackImage", strBackImage)
	ItemButton:SetActionItem(action_item_id)
	ItemButton:Show()
	
	ItemBar:Setm_newText(22, strText)
	ItemBar:Setm_newTextShow(22)
end

function TargetFightScore_UpdateRightUnderArmour()
	
	local nTargetLevel = CachedTarget:GetData("LEVEL")
	local nMyLevel = Player:GetLevel()
	
	local strRed = "#cff0000"
	local strGreen = "#G"
	
	if nMyLevel < 85 and nTargetLevel < 85 then
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert(g_data.RightItems, ItemBar)
		TargetFightScore_AddGenericItem1(ItemBar, "", 0, -1, "#{PFBJ_220915_01}", "")
		TargetFightScore_AddGenericItem2(ItemBar, "", 0, -1, "#{PFBJ_220915_01}", "")
		TargetFightScore_FlashRight()
		return
	end
	
	for i = 1, 6 do
		local ItemBar = TargetFightScore_NewRightItem()
		table.insert(g_data.RightItems, ItemBar)
	end
	
	
	local strTemp = ""

	local cur_index = 0
	
	for i = 1, 3 do	
		
		local iActive = 0
		local iRank = 0
		local iLevel = 0
		local iStar = 0
		local iScore = 0
		
		local iTargetActive = 0
		local iTargetRank = 0
		local iTargetLevel = 0
		local iTargetStar = 0
		local iTargetScore = 0
		
		if nMyLevel >= 75 then
			iActive = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
			if iActive == 1 then
				iRank = DataPool:LuaFnGetUnderArmourData(i - 1, "RANK")
				iLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "LEVEL")
				iStar = DataPool:LuaFnGetUnderArmourData(i - 1, "STAR")
				iScore = DataPool:LuaFnGetUnderArmourFightScore(i - 1, iRank, iLevel, iStar)
			end
		end
		
		if nTargetLevel >= 75 then
			iTargetActive = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "ACTIVED")
			if iTargetActive == 1 then
				iTargetRank = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "RANK")
				iTargetLevel = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "LEVEL")
				iTargetStar = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "STAR")
				iTargetScore = DataPool:LuaFnGetUnderArmourFightScore(i - 1, iTargetRank, iTargetLevel, iTargetStar)
			end
		end
		
		if nMyLevel >= 75 then	
			if iActive == 1 then
				local strIcon = DataPool:LuaFnGetUnderArmourInfo(i - 1, "ICON", iRank)
				local strIconImage = GetIconFullName(tostring(strIcon))

				if iScore >= iTargetScore then
					if iRank == 5 then
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_14}", tostring(iStar))
					else
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_02}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel), tostring(iStar))
					end
				else
					if iRank == 5 then
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_18}", tostring(iStar))
					else
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_15}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel), tostring(iStar))
					end
				end

				TargetFightScore_AddUnderArmourItem2(g_data.RightItems[i + cur_index], tostring(strIconImage), -1, strTemp)
				
				local itemButton = g_data.RightItems[i + cur_index]:GetLuaActionButton(6, "TargetFightScore")
				itemButton:SetEvent("MouseEnter", string.format("TargetFightScore_UnderArmourMouseEnter(0, %d)", i))
				itemButton:SetEvent("MouseLeave", string.format("TargetFightScore_UnderArmourMouseLeave(0, %d)", i))
			else
				local strIcon = DataPool:LuaFnGetUnderArmourInfo(i - 1, "LOCKICON")
				local strIconImage = GetIconFullName(tostring(strIcon))
				TargetFightScore_AddUnderArmourItem2(g_data.RightItems[i + cur_index], tostring(strIconImage), -1, "#{PFBJ_220915_10}", "")
			end
		else
			TargetFightScore_AddUnderArmourItem2(g_data.RightItems[i + cur_index], "", -1, "#{PFBJ_220915_01}", "")
		end
		
		if nTargetLevel >= 75 then
			if iTargetActive == 1 then
				local strIcon = DataPool:LuaFnGetUnderArmourInfo(i - 1, "ICON", iTargetRank)
				local strIconImage = GetIconFullName(tostring(strIcon))
				
				if iScore > iTargetScore then
					if iTargetRank == 5 then
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_18}", tostring(iTargetStar))
					else
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_15}", tostring(g_UA_Rank_Name[iTargetRank + 1]), tostring(iTargetLevel), tostring(iTargetStar))
					end
				else
					if iTargetRank == 5 then
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_14}", tostring(iTargetStar))
					else
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_02}", tostring(g_UA_Rank_Name[iTargetRank + 1]), tostring(iTargetLevel), tostring(iTargetStar))
					end
				end
				
				TargetFightScore_AddUnderArmourItem1(g_data.RightItems[i + cur_index], tostring(strIconImage), -1, strTemp)
				
				local itemButton = g_data.RightItems[i + cur_index]:GetLuaActionButton(1, "TargetFightScore")
				itemButton:SetEvent("MouseEnter", string.format("TargetFightScore_UnderArmourMouseEnter(1, %d)", i))
				itemButton:SetEvent("MouseLeave", string.format("TargetFightScore_UnderArmourMouseLeave(1, %d)", i))
			else
				local strIcon = DataPool:LuaFnGetUnderArmourInfo(i - 1, "LOCKICON")
				local strIconImage = GetIconFullName(tostring(strIcon))
				TargetFightScore_AddUnderArmourItem1(g_data.RightItems[i + cur_index], tostring(strIconImage), -1, "#{PFBJ_220915_10}")
			end
		else
			TargetFightScore_AddUnderArmourItem1(g_data.RightItems[i + cur_index], "", -1, "#{PFBJ_220915_01}")
		end
	end

	cur_index = 3

	for i = 1, 3 do
		
		local iActive = 0
		local iJewel = 0
		local iJewelLevel = 0
		local iPlate = 0
		local iPlateLevel = 0
		local iScore = 0
		
		local iTargetActive = 0
		local iTargetJewel = 0
		local iTargetJewelLevel = 0
		local iTargetPlate = 0
		local iTargetPlateLevel = 0
		local iTargetScore = 0
		
		if nMyLevel >= 75 then
			iActive = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
			if iActive == 1 then
				iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
				if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
					iJewelLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL_LEVEL")
					iScore = DataPool:LuaFnGetUnderArmourJewelFightScore(tonumber(iJewel), iJewelLevel)

					iPlate = DataPool:LuaFnGetUnderArmourData(i - 1, "PLATE")
					if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then
						iPlateLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "PLATE_LEVEL")
						iScore = iScore + DataPool:LuaFnGetUnderArmourPlateFightScore(tonumber(iPlate), iPlateLevel)
					end
				end
			end
		end
		
		if nTargetLevel >= 75 then
			iTargetActive = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "ACTIVED")
			if iTargetActive == 1 then
				iTargetJewel = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "JEWEL")
				if tonumber(iTargetJewel) ~= nil and tonumber(iTargetJewel) > 0 then
					iTargetJewelLevel = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "JEWEL_LEVEL")
					iTargetScore = DataPool:LuaFnGetUnderArmourJewelFightScore(tonumber(iTargetJewel), iTargetJewelLevel)
					
					iTargetPlate = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "PLATE")
					if tonumber(iTargetPlate) ~= nil and tonumber(iTargetPlate) > 0 then
						iTargetPlateLevel = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "PLATE_LEVEL")
						iTargetScore = iTargetScore + DataPool:LuaFnGetUnderArmourPlateFightScore(tonumber(iTargetPlate), iTargetPlateLevel)
					end
				end
			end
		end
		
		if nMyLevel >= 75 then
			if iActive == 1 and tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
				local strColor = strGreen
				local itemAction = EnumAction(i - 1, "UnderArmourJewel")
				
				if iScore >= iTargetScore then
					if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_11}", tostring(iJewelLevel + 1), tostring(iPlateLevel + 1))
					else
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_12}", tostring(iJewelLevel + 1))
					end
				else
					if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_16}", tostring(iJewelLevel + 1), tostring(iPlateLevel + 1))
					else
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_17}", tostring(iJewelLevel + 1))
					end
				end
				
				TargetFightScore_AddUnderArmourItem2(g_data.RightItems[i + cur_index], "", itemAction:GetID(), strTemp)
			else
				TargetFightScore_AddUnderArmourItem2(g_data.RightItems[i + cur_index], "", -1, "#{PFBJ_220915_13}")
			end
		else
			TargetFightScore_AddUnderArmourItem2(g_data.RightItems[i + cur_index], "", -1, "#{PFBJ_220915_01}")
		end
		
		if nTargetLevel >= 75 then
			if iTargetActive == 1 and tonumber(iTargetJewel) ~= nil and tonumber(iTargetJewel) > 0 then
				local strColor = strGreen
				local itemAction = EnumAction(i - 1, "TargetUnderArmourJewel")
				
				if iScore > iTargetScore then
					if tonumber(iTargetPlate) ~= nil and tonumber(iTargetPlate) > 0 then
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_16}", tostring(iTargetJewelLevel + 1), tostring(iTargetPlateLevel + 1))
					else
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_17}", tostring(iTargetJewelLevel + 1))
					end
				else
					if tonumber(iTargetPlate) ~= nil and tonumber(iTargetPlate) > 0 then
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_11}", tostring(iTargetJewelLevel + 1), tostring(iTargetPlateLevel + 1))
					else
						strTemp = ScriptGlobal_Format("#{PFBJ_220915_12}", tostring(iTargetJewelLevel + 1))
					end
				end

				TargetFightScore_AddUnderArmourItem1(g_data.RightItems[i + cur_index], "", itemAction:GetID(), strTemp)
			else
				TargetFightScore_AddUnderArmourItem1(g_data.RightItems[i + cur_index], "", -1, "#{PFBJ_220915_13}")
			end
		else
			TargetFightScore_AddUnderArmourItem1(g_data.RightItems[i + cur_index], "", -1, "#{PFBJ_220915_01}")
		end
	end

	TargetFightScore_FlashRight()
end

function TargetFightScore_UnderArmourMouseEnter(iType, index)

	if g_data.RightItems[index] == nil then
		return
	end
		
	if iType == 1 then
		local itemButton = g_data.RightItems[index]:GetLuaActionButton(1, "TargetFightScore")
		
		if itemButton == nil then
			return
		end
		
		local iActive = DataPool:LuaFnGetOtherUnderArmourData(index - 1, "ACTIVED")
		if iActive ~= 1 then
			return
		end
		
		local fX, fY = itemButton:GetAbsolutePositionToScreen()
		local SetWidth = itemButton:GetProperty("AbsoluteWidth")
		local SetHeight = itemButton:GetProperty("AbsoluteHeight")
		LuaFnOpenUnderArmourTip(1, index, tonumber(fX), tonumber(fY), tonumber(SetWidth), tonumber(SetHeight))
	else
		local itemButton = g_data.RightItems[index]:GetLuaActionButton(6, "TargetFightScore")
		
		if itemButton == nil then
			return
				end

		local iActive = DataPool:LuaFnGetUnderArmourData(index - 1, "ACTIVED")
		if iActive ~= 1 then
			return
		end

		local fX, fY = itemButton:GetAbsolutePositionToScreen()
		local SetWidth = itemButton:GetProperty("AbsoluteWidth")
		local SetHeight = itemButton:GetProperty("AbsoluteHeight")
		LuaFnOpenUnderArmourTip(0, index, tonumber(fX), tonumber(fY), tonumber(SetWidth), tonumber(SetHeight))
	end
end

function TargetFightScore_UnderArmourMouseLeave(iType, index)
	LuaFnCloseUnderArmourTip(iType, index)
end

local g_ZongMenEquipLevelStr = {
	"#{PFZY_230830_08}",
	"#{PFZY_230830_09}",
	"#{PFZY_230830_10}",
	"#{PFZY_230830_11}",
	"#{PFZY_230830_12}",
}

function TargetFightScore_UpdateRightZongMenEquip()
	local nTargetLevel = CachedTarget:GetData("LEVEL")
	local nMyLevel = Player:GetLevel()
	
	local strRed = "#cff0000"
	local strGreen = "#G"
	
	local strTemp = ""
	
	local ItemBar = TargetFightScore_NewRightItem()
	table.insert(g_data.RightItems, ItemBar)
	
	if nMyLevel < 60 and nTargetLevel < 60 then
		TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_01}", "")
		TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_01}", "")
		TargetFightScore_FlashRight()
		return
	end
	
	if nMyLevel >= 60 and nTargetLevel < 60 then
		if DataPool:LuaFnIsEquipZMXW() == 1 then
			local ActionEquip = EnumAction(23, "equip")	
			local item_table_index = DataPool:LuaFnGetEquipItemTableIndex(23)
			local equip_level = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "LEVEL")	
			strTemp = ScriptGlobal_Format("#{PFBJ_230830_02}", strGreen..tostring(g_ZongMenEquipLevelStr[equip_level]))
			TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_01}", "")		--对方
			TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, ActionEquip:GetID(), strTemp, "")	--自己
			TargetFightScore_FlashRight()
		else
			TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_01}", "")
			TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_08}", "")
			TargetFightScore_FlashRight()
		end
		return
	end
	
	if nMyLevel < 60 and nTargetLevel >= 60 then
		if DataPool:LuaFnOtherIsEquipZMXW() == 1 then
			local ActionEquip_Other = EnumAction(23, "targetequip")	
			local item_table_index_other = DataPool:LuaFnOtherGetEquipItemTableIndex(23)
			local equip_level_other = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index_other), "LEVEL")
			
			strTemp = ScriptGlobal_Format("#{PFBJ_230830_02}", strGreen..tostring(g_ZongMenEquipLevelStr[equip_level_other]))
			TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, ActionEquip_Other:GetID(), strTemp, "")	--对方
			TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_01}", "")		--自己
			TargetFightScore_FlashRight()
		else
			TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_08}", "")		--对方
			TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_01}", "")		--自己
			TargetFightScore_FlashRight()
		end
		return
	end
	
	if nMyLevel >= 60 and nTargetLevel >= 60 then
		if DataPool:LuaFnIsEquipZMXW() == 1 and DataPool:LuaFnOtherIsEquipZMXW() == 1 then
			local ActionEquip = EnumAction(23, "equip")	
			local item_table_index = DataPool:LuaFnGetEquipItemTableIndex(23)
			local equip_level = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "LEVEL")

			local ActionEquip_Other = EnumAction(23, "targetequip")	
			local item_table_index_other = DataPool:LuaFnOtherGetEquipItemTableIndex(23)
			local equip_level_other = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index_other), "LEVEL")
			
			if equip_level > equip_level_other then
				strTemp = ScriptGlobal_Format("#{PFBJ_230830_02}", strRed..tostring(g_ZongMenEquipLevelStr[equip_level_other]))
			else
				strTemp = ScriptGlobal_Format("#{PFBJ_230830_02}", strGreen..tostring(g_ZongMenEquipLevelStr[equip_level_other]))				
			end
			TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, ActionEquip_Other:GetID(), strTemp, "")	--对方
			
			if equip_level < equip_level_other then
				strTemp = ScriptGlobal_Format("#{PFBJ_230830_02}", strRed..tostring(g_ZongMenEquipLevelStr[equip_level]))
			else
				strTemp = ScriptGlobal_Format("#{PFBJ_230830_02}", strGreen..tostring(g_ZongMenEquipLevelStr[equip_level]))
			end
			TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, ActionEquip:GetID(), strTemp, "")		--自己
			TargetFightScore_FlashRight()
		elseif DataPool:LuaFnIsEquipZMXW() == 1 and DataPool:LuaFnOtherIsEquipZMXW() ~= 1 then
			local ActionEquip = EnumAction(23, "equip")	
			local item_table_index = DataPool:LuaFnGetEquipItemTableIndex(23)
			local equip_level = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "LEVEL")
			
			TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_08}", "")		--对方
			
			strTemp = ScriptGlobal_Format("#{PFBJ_230830_02}", strGreen..tostring(g_ZongMenEquipLevelStr[equip_level]))
			TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, ActionEquip:GetID(), strTemp, "")		--自己
			TargetFightScore_FlashRight()
		elseif DataPool:LuaFnIsEquipZMXW() ~= 1 and DataPool:LuaFnOtherIsEquipZMXW() == 1 then
			local ActionEquip_Other = EnumAction(23, "targetequip")	
			local item_table_index_other = DataPool:LuaFnOtherGetEquipItemTableIndex(23)
			local equip_level_other = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index_other), "LEVEL")
			
			strTemp = ScriptGlobal_Format("#{PFBJ_230830_02}", strGreen..tostring(g_ZongMenEquipLevelStr[equip_level_other]))
			TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, ActionEquip_Other:GetID(), strTemp, "")		--对方

			TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_08}", "")		--自己
			TargetFightScore_FlashRight()
		else
			TargetFightScore_AddGenericItem1(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_08}", "")		--对方
			TargetFightScore_AddGenericItem2(ItemBar, "set:ZongMenSkill image:ZongMenSkill_ItemBK", 0, -1, "#{PFBJ_230830_08}", "")		--自己
			TargetFightScore_FlashRight()
		end
		return
	end
end