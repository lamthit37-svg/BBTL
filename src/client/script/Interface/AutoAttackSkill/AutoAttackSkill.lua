local g_unifiedposistion = nil

local g_configdata = {
	useskill = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, },
	usepotiont = { 0, 0, 0, },
	usepotion =  { 1,  1,  1,},
	usepotionc = { 50, 50, 50, },

	useRecoverSkill = { 50, 50, 50, },
	usePetSkill = { 1, 1 },
	usePetSkillc = { 50, 50 },
	usePetSkillt = { 0, 0 },

	useSwitch = {1,1,0,0,0,0,0,0,0,0},

	valid = 0,
	ticktime = 1000,

	usepotionofft = { 0, 0, 0, },
	usepotionoff =  { 1,  1,  1,},
	usepotionoffc = { 50, 50, 50, },
}

local g_data = {
	xfselect = 1,	-- 当前选中技能
	curxfid = 1,	-- 心法组
	option = 1,		-- 当前选中项
	optiontype = 1,	-- 当前药品设置类型
}
-- 心法
local g_uixfskillactions = {}
-- 子技能组合
local g_uiskillactions = {}
-- 选项组合
local g_uiskilloptions = {}
-- 回复技能特殊页签组合
local g_uirrskilloptions = {}
-- 切换页签按钮
local g_uipageactions = {}
-- 子选项组合
local g_uioptionsactions = {}
-- 其他ui
local g_uicommoninfo = {}
-- 选项组合
local g_uiskillpetoptions = {}
-- 回调内容集合
local g_recoverInfo = {}
local g_recoverSkills = {}
local g_petSkills = {}

-- 结束条件Input框
local g_StopCondition_NumberInput_Box = { nil, nil, nil }
local g_StopCondition_Config_Data = { 0, 0, 0 }
local g_StopCondition_CallBack_Type = 0
local g_StopCondition_AskSave_Flag = 0

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_AutoAttackSkill_Page = {
	[1] = {Text = "#e010101".."#{INTERFACE_XML_494}",	NeedCheck = 0, Tip = ""},
	[2] = {Text = "#e010101".."#{INTERFACE_XML_448}",	NeedCheck = 0, Tip = ""},
	[3] = {Text = "#e010101".."#{JBGXW_150526_215}",	NeedCheck = 0, Tip = ""},
	[4] = {Text = "#e010101".."#{INTERFACE_XML_635}",	NeedCheck = 0, Tip = ""},
	[5] = {Text = "#e010101#Y".."#{ZDZD_200724_08}",	NeedCheck = 0, Tip = ""},
	[6] = {Text = "#e010101".."#{ZMTF_230628_20}",		NeedCheck = 0, Tip = ""},
}
local g_AutoAttackSkill_PageButton = {}
local g_AutoAttackSkill_PageOrder = {}
local g_PageTipsPos = {}

--==================================下面为固定常量===============================================
-- 当前页签号
local g_curpage = 5
-- 无门派
local g_invalidmenpai = 9
-- 加血门派
local g_menpai_recover = {
	[4] = 1 ,
	[12] = 1,
	[14] = 1,
}

local g_menpaiattr = {
	[0] = {image = "set:Menpaishuxing image:Shuxing_Dark", Tooltip = "#{MPZSX_20071221_13}", },			--少林
	[1] = {image = "set:Menpaishuxing image:Shuxing_Fire", Tooltip = "#{MPZSX_20071221_12}",},				--明教
	[2] = {image = "set:Menpaishuxing image:Shuxing_PoisonFire", Tooltip = "#{MPZSX_20071221_15}",},		--丐帮
	[3] = {image = "set:Menpaishuxing image:Shuxing_DarkIce", Tooltip = "#{MPZSX_20071221_16}",},			--武当
	[4] = {image = "set:Menpaishuxing image:Shuxing_IceDark", Tooltip = "#{MPZSX_20071221_17}",},			--峨嵋
	[5] = {image = "set:Menpaishuxing image:Shuxing_Poison", Tooltip = "#{MPZSX_20071221_14}",},			--星宿
	[6] = {image = "set:Menpaishuxing image:Shuxing_FIPD", Tooltip = "#{MPZSX_20071221_18}",},				--天龙
	[7] = {image = "set:Menpaishuxing image:Shuxing_Ice", Tooltip = "#{MPZSX_20071221_11}",},				--天山
	[8] = {image = "set:Menpaishuxing image:Shuxing_FirePoison", Tooltip = "#{MPZSX_20071221_19}",},		--逍遥
	[9] = {image = "", Tooltip = "#{ZDZD_200724_46}",},															--无门派
	[10]= {image = "set:Menpaishuxing image:Shuxing_Dark", Tooltip = "#{MPZSX_20071221_13}", },			--慕容
	[11]= {image = "set:Menpaishuxing image:Shuxing_DarkPoison", Tooltip = "#{XMPTM_130123_36}",},			--唐门
	[12]= {image = "set:Menpaishuxing image:Shuxing_DarkFire", Tooltip = "#{XMPGG_160524_01}",},			--鬼谷
	[13]= {image = "set:Menpaishuxing image:Shuxing_KunLun", Tooltip = "#{THDXG_190705_02}",},				--桃花岛
	[14]= {image = "set:Menpaishuxing image:Shuxing_CongRen", Tooltip = "#{XMPHM_210604_25}",},			--从刃
	[15]= {image = "set:Menpaishuxing image:Shuxing_PoisonIce", Tooltip = "#{XMPHM_210604_38}",},			--menpai15
}
-- 被禁止取消的普通攻击技能,每个门派一个，特写吧，表里虽然按顺序写的，但是一旦改变顺序就GG了。
local g_nobanskill = {--menpai15 mptodo
	281,311,341,371,401,431,461,491,521,760,2900,3430,3800,4515,4622
}
local g_optionbtnattr = {
	special = { num=4, text={"#{ZDZD_200724_10}","#{ZDZD_200724_11}","#{ZDZD_200724_12}","#{ZDZD_20220815_08}"} },
	normal = { num=3, text={"#{ZDZD_200724_10}","#{ZDZD_200724_12}","#{ZDZD_20220815_08}"} },
}

local g_configdef = {
	useskill = 17,
	usepotion = 3,
	userecover = 4,
	usepet = 2,
	useswitch = 10,
	usepotionoff = 3,
}

local g_optionpagedef = {
	recoverinfo = 1,	-- 药品
	recoverskill = 2,	-- 回复技能
	petskill = 3,		-- 宠物技能
	stopconfig = 4,		-- 结束条件
}

local g_rateautoselect = 2
local g_ratevalue = {
	30,50,70,
}

-- 宠物技能配置。 绿色挪过来的貌似不能通用，写死吧
local g_recoverpetskill = {
	{ 686, 687, },	-- 共生， 高级共生
	{ 696, 697, },	-- 血祭， 高级血祭
}

local g_specialrecoverskill = 3 -- 特殊的回复技能

-- 近战门派 少林 明教 丐帮 天山
local g_autoattackskill_melee_mp = {
	0,1,2,7,10,
}

-- 按钮位置调整 
local g_autoattackskill_nofightpos = {
	new = "{{0.000000,40.000000},{0.000000,455.000000}}",
	old = "{{0.000000,8.000000},{0.000000,455.000000}}",
	btnnew = "{{1.000000,-150.000000},{1.000000,-45.000000}}",
	btnold = "{{1.000000,-110.000000},{1.000000,-45.000000}}",
}

local g_optiontype_def = {
	auto = 1,
	off =2,
}
local g_speical_ban_skill = 407
--===================================固定常量END==========================================================

function AutoAttackSkill_PreLoad()
	this:RegisterEvent("TRIGGER_ZIDONGZHANDOU")
	this:RegisterEvent("ZDZD_AUTOSEARCHNPC")
	this:RegisterEvent("NEIGUA_FUBEN_EVENT", true)
	this:RegisterEvent("BATTLE_ASSIST_EVENT",false)
	this:RegisterEvent("TOGLE_LIFE_PAGE",false)
	this:RegisterEvent("TOGLE_SKILL_BOOK",false)
	this:RegisterEvent("TOGLE_COMMONSKILL_PAGE",false)
	this:RegisterEvent("SKILL_UPDATE",false)
	this:RegisterEvent("CHANGE_PETSKILL_BAR",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED",false)
	this:RegisterEvent("OPEN_ZHENFAFREAM",false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("CLOSE_SKILL_BOOK",false)
	this:RegisterEvent("ZDZD_AUTOTEAMAPPLY", true)
end

function AutoAttackSkill_OnLoad()
	-- 进行UI内容组合
	local _prefix = "AutoAttackSkill_"
	local makeGroup = function(action)
		return _G[_prefix..action]
	end
	local makeSkillGroup = function(check,lockp,lock,ban,unlock,action)
		return {
			["check"] = _G[_prefix..check],
			["lockp"] = _G[_prefix..lockp],
			["lock"] = _G[_prefix..lock],
			["ban"] = _G[_prefix..ban],
			["unlock"] = _G[_prefix..unlock],
			["action"] = _G[_prefix..action],
		}
	end
	local makeXinfaGroup = function(check, action)
		return {
			["check"] = _G[_prefix..check],
			["action"] = _G[_prefix..action],
		}
	end
	local makeoptionsGroup = function(_prefix2,name,combo,btn,btntext,btn1,btntext1,btn2,btntext2)
		return {
			["parent"] = _G[_prefix.._prefix2],
			["name"] = _G[_prefix.._prefix2..name],
			["combo"] = _G[_prefix.._prefix2..combo],
			["btnlist"] = {
				_G[_prefix.._prefix2..btn],
				_G[_prefix.._prefix2..btntext],
				_G[_prefix.._prefix2..btn1],
				_G[_prefix.._prefix2..btntext1],
				_G[_prefix.._prefix2..btn2],
				_G[_prefix.._prefix2..btntext2],
			}
		}
	end
	g_uiskillactions = {
		makeSkillGroup("Zhaoshi1", "Background1", "lock1", "Jin1", "OK1", "Zhaoshi1"),
		makeSkillGroup("Zhaoshi2", "Background2", "lock2", "Jin2", "OK2", "Zhaoshi2"),
		makeSkillGroup("Zhaoshi3", "Background3", "lock3", "Jin3", "OK3", "Zhaoshi3"),
		makeSkillGroup("Zhaoshi4", "Background4", "lock4", "Jin4", "OK4", "Zhaoshi4"),
		makeSkillGroup("Zhaoshi5", "Background5", "lock5", "Jin5", "OK5", "Zhaoshi5"),
	}
	g_uixfskillactions = {
		makeXinfaGroup("Xinfa1", "Xinfa1"),
		makeXinfaGroup("Xinfa2", "Xinfa2"),
		makeXinfaGroup("Xinfa3", "Xinfa3"),
		makeXinfaGroup("Xinfa4", "Xinfa4"),
		makeXinfaGroup("Xinfa5", "Xinfa5"),
		makeXinfaGroup("Xinfa6", "Xinfa6"),
		makeXinfaGroup("Xinfa7", "Xinfa7"),
		makeXinfaGroup("Xinfa8", "Xinfa8"),
	}
	g_uiskilloptions = {
		makeoptionsGroup("Explain1","_Blood","_BloodHuiFu",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
		makeoptionsGroup("Explain2","_Blood","_BloodHuiFu",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
		makeoptionsGroup("Explain3","_Blood","_BloodHuiFu",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
	}
	g_uiskillpetoptions = {
		makeoptionsGroup("PetExplain1","_Blood","_BloodHuiFu",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
		makeoptionsGroup("PetExplain2","_Blood","_BloodHuiFu",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
		makeoptionsGroup("PetExplain3","_Blood","_BloodHuiFu",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
	}
	g_uirrskilloptions = {
		makeoptionsGroup("Skill1","_Blood","_Blood",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
		makeoptionsGroup("Skill2","_Blood","_Blood",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
		makeoptionsGroup("Skill3","_Blood","_Blood",
		"_Blood30","_Blood30Text","_Blood50","_Blood50Text","_Blood70","_Blood70Text") ,
	}
	g_uipageactions = {
		makeGroup("CommonlySkill"),
		makeGroup("ActionSkill"),
		makeGroup("ZhenfaSkill"),
		makeGroup("LifeSkill"),
		makeGroup("AutoAttack"),
		makeGroup("ZongMenSkill"),

	}
	g_uioptionsactions = {
		makeGroup("Setting1"),
		makeGroup("Setting2"),
		makeGroup("Setting3"),
		makeGroup("Setting4"),
	}
	g_uicommoninfo = {
		mpicon = makeGroup("MenPai_ICON"),
		atbdesc = makeGroup("MenPai_Attr_Intro"),
		fight = makeGroup("Fight"),
		title = makeGroup("Frame_Title"),
		skill = makeGroup("Skill_Bk"),
		explain = makeGroup("Explain_Bk"),
		noattackhm = makeGroup("NoFightBtn"),
		longfight = makeGroup("LongFightBtn"),
		fightbg = makeGroup("LongFight_Button"),
		nofightbg = makeGroup("NoFight_Button"),
		baseconfig = makeGroup("Index1"),
		qiankunpot = makeGroup("Index2"),
		tldbtn = makeGroup("Others_TianlingDan"),
		xldbtn = makeGroup("Others_XuanlingDan"),
		lvlimit = makeGroup("Others_Time"),
		auto = makeGroup("AutoFight"),
		off = makeGroup("NotAutoFight"),
		petskill = makeGroup("PetExplain_Bk"),
		autoapply = makeGroup("Others_Apply"),
		autoghost = makeGroup("Others_AutoGhost"),
		pausegodali = makeGroup("Others_MaintainBattle"),
	}

	g_StopCondition_NumberInput_Box[1] = AutoAttackSkill_Others_NumberInput1
	g_StopCondition_NumberInput_Box[2] = AutoAttackSkill_Others_NumberInput2
	g_StopCondition_NumberInput_Box[3] = AutoAttackSkill_Others_Levelup_NumberInput

	--AutoAttackSkill_SetTabColor()
	g_unifiedposistion = AutoAttackSkill_Frame:GetProperty("UnifiedPosition")
		
	g_AutoAttackSkill_PageButton[1] = AutoAttackSkill_CommonlySkill
	g_AutoAttackSkill_PageButton[2] = AutoAttackSkill_ActionSkill
	g_AutoAttackSkill_PageButton[3] = AutoAttackSkill_ZhenfaSkill
	g_AutoAttackSkill_PageButton[4] = AutoAttackSkill_LifeSkill
	g_AutoAttackSkill_PageButton[5] = AutoAttackSkill_AutoAttack
	g_AutoAttackSkill_PageButton[6] = AutoAttackSkill_ZongMenSkill
	
	g_PageTipsPos[1] = "{0.000000,28.000000}" 
	g_PageTipsPos[2] = "{0.000000,64.000000}" 
	g_PageTipsPos[3] = "{0.000000,100.000000}"
	g_PageTipsPos[4] = "{0.000000,136.000000}"
	g_PageTipsPos[5] = "{0.000000,172.000000}"
	g_PageTipsPos[6] = "{0.000000,208.000000}"
	
end

function AutoAttackSkill_OnEvent(event)
	if event == "TRIGGER_ZIDONGZHANDOU" then
		AutoAttackSkill_AttackEvent(arg0)
	elseif event == "BATTLE_ASSIST_EVENT"  then
		AutoAttackSkill_UpdateBaseUI()
	elseif event == "SKILL_UPDATE" and this:IsVisible() then
		AutoAttackSkill_UpdateSkillUI()
	elseif event == "PACKAGE_ITEM_CHANGED" and this:IsVisible() then
		if g_data.option == g_optionpagedef.recoverinfo then
			AutoAttackSkill_UpdateOptionUI()
		end
	elseif event == "ADJEST_UI_POS"  then
		AutoAttackSkill_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		AutoAttackSkill_OnResetPos()
	elseif ( event == "CLOSE_SKILL_BOOK" ) then
		AutoAttackSkill_OnClose()
	elseif event == "ZDZD_AUTOSEARCHNPC" then
		AutoAttackSkill_OnAutoSearchNpc()
	elseif  event == "TOGLE_SKILL_BOOK" or
		event == "TOGLE_LIFE_PAGE" or
		event == "TOGLE_COMMONSKILL_PAGE" or 
		event == "PLAYER_LEAVE_WORLD" or
		event == "OPEN_ZHENFAFREAM" then
		AutoAttackSkill_OnClose()

	elseif event == "NEIGUA_FUBEN_EVENT" and arg0 == "update" then
		local isworking = BattleAssist:IsWorking()
		if isworking ~= "false" then
			g_uicommoninfo.fight:SetText("#{ZDZD_200724_28}")
		else
			g_uicommoninfo.fight:SetText("#{ZDZD_200724_27}")
		end
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			AutoAttackSkill_ZongMenSkill_Tips:Show()	
		else
			AutoAttackSkill_ZongMenSkill_Tips:Hide()		
		end
		
	elseif  event == "ZDZD_AUTOTEAMAPPLY" then
		AutoAttackSkill_OnTeamAutoApply()
	end
end

--================= local函数 =====================
----------------------------------------------------------------------------------------------------

local function datareset()
	g_data.xfselect = 1
	g_data.curxfid = 1
	g_data.option = 1
	g_data.optiontype = 1
end

local function getpetskill()
	return g_recoverpetskill
end

local function getlongrangeskillvalue()
	if g_configdata.useSwitch[2] > 0 then
		return 0
	else
		return 1
	end
end

-- 注意，以下3个方法会被ngmain.lua的UpdateZDZDConfig()调用，修改后会影响string.find读取参数
function AutoAttackSkill_GetPostionCfgStr()
	local ret = ""
	ret = ret..string.format("usepotiont=%d,%d,%d;", g_configdata.usepotiont[1], g_configdata.usepotiont[2], g_configdata.usepotiont[3] )
	ret = ret..string.format("usepotion=%d%d%d;", g_configdata.usepotion[1], g_configdata.usepotion[2], g_configdata.usepotion[3] )
	ret = ret..string.format("usepotionc=%.3f,%.3f,%.3f;",g_configdata.usepotionc[1]/100.0,g_configdata.usepotionc[2]/100.0,g_configdata.usepotionc[3]/100.0)
	return ret
end

function AutoAttackSkill_GetRecoverSkillCfgStr()
	local ret = string.format("users=%.3f,%.3f,%.3f;",g_configdata.useRecoverSkill[1]/100.0,g_configdata.useRecoverSkill[2]/100.0,g_configdata.useRecoverSkill[3]/100.0)
	return ret
end

function AutoAttackSkill_GetPetSkillCfgStr()
	local ret = ""
	ret = ret..string.format("useps=%d,%d;",g_configdata.usePetSkill[1],g_configdata.usePetSkill[2])
	ret = ret..string.format("usepsc=%.3f,%.3f;",g_configdata.usePetSkillc[1],g_configdata.usePetSkillc[2])
	ret = ret..string.format("usepst=%d,%d;",g_configdata.usePetSkillt[1],g_configdata.usePetSkillt[2])
	return ret
end

function AutoAttackSkill_GetReliveCfg()
	return g_configdata.useSwitch[8] --死亡自动出窍
end

function AutoAttackSkill_IsFocusRecover()
	return g_configdata.useSwitch[10] --是否专注回复
end

local function makecfgstr()
	local skillbuffer = ""
	for i=1,17 do
		skillbuffer = skillbuffer..g_configdata.useskill[i]
	end
	local ret = ""
	ret = ret..string.format("useskill=%s;", skillbuffer )
	ret = ret..AutoAttackSkill_GetPostionCfgStr()..AutoAttackSkill_GetRecoverSkillCfgStr()..AutoAttackSkill_GetPetSkillCfgStr()
	ret = ret..string.format("usepotionofft=%d,%d,%d;", g_configdata.usepotionofft[1], g_configdata.usepotionofft[2], g_configdata.usepotionofft[3] )
	ret = ret..string.format("usepotionoff=%d%d%d;", g_configdata.usepotionoff[1], g_configdata.usepotionoff[2], g_configdata.usepotionoff[3] )
	ret = ret..string.format("usepotionoffc=%.3f,%.3f,%.3f;",g_configdata.usepotionoffc[1]/100.0,g_configdata.usepotionoffc[2]/100.0,g_configdata.usepotionoffc[3]/100.0)
	ret = ret..string.format("EnableAttachHuman=%d;",g_configdata.useSwitch[1])
	ret = ret..string.format("EnableLongRangeSkill=%d;",getlongrangeskillvalue())
	ret = ret..string.format("EnableUseExpItem=%d;",g_configdata.useSwitch[3])
	ret = ret..string.format("EnableUseExpPetItem=%d;",g_configdata.useSwitch[4])
	ret = ret..string.format("EnableDTLock=%d;",g_configdata.useSwitch[5])
	ret = ret..string.format("EnableUsePetPotion=%d;",g_configdata.useSwitch[6])
	ret = ret..string.format("EnableAutoApply=%d;",g_configdata.useSwitch[7])
	ret = ret..string.format("EnablePauseGoDaLi=%d;",g_configdata.useSwitch[8])
	ret = ret..string.format("EnableAutoRevive=%d;",g_configdata.useSwitch[9])
	ret = ret..string.format("EnableFocusRecover=%d;",g_configdata.useSwitch[10])
	ret = ret..string.format("TickTime=%d;",g_configdata.ticktime)

	return ret
end

local function initconfigdata()
	local us, upt, up, upc, urs, ps, ush, upot, upo, upoc  = BattleAssist:Farm_GetConfigData()
	if not us then
		g_configdata.valid = 0
		return
	end

	for i=1, g_configdef.useskill do
		g_configdata.useskill[i] = tonumber(us[i])
	end
	for i=1, g_configdef.usepotion do
		g_configdata.usepotiont[i] = tonumber(upt[i])
		g_configdata.usepotion[i] = tonumber(up[i])
		g_configdata.usepotionc[i] = tonumber(upc[i])
	end
	for i=1, g_configdef.userecover do
		g_configdata.useRecoverSkill[i] = tonumber(urs[i])
	end
	for i=1,g_configdef.usepet do
		g_configdata.usePetSkill[i] = tonumber( ps[i] )
		g_configdata.usePetSkillc[i] = tonumber( ps[2+i] )
		g_configdata.usePetSkillt[i] = tonumber( ps[4+i] )
	end
	for i=1,g_configdef.useswitch do
		g_configdata.useSwitch[i] = tonumber( ush[i] )
	end

	for i=1, g_configdef.usepotionoff do
		g_configdata.usepotionofft[i] = tonumber(upot[i])
		g_configdata.usepotionoff[i] = tonumber(upo[i])
		g_configdata.usepotionoffc[i] = tonumber(upoc[i])
	end

	g_configdata.valid = 1
end

--================= 对数值进行修正 =====================
local function getmodifyvalue(data)
	if data >= 0 then
		local cnt = table.getn(g_ratevalue)
		for i=1, cnt do
			if g_ratevalue[i] >= data then
				return i, g_ratevalue[i]
			end
		end
	end

	return g_rateautoselect, g_ratevalue[g_rateautoselect]
end

local function getoptionbasevalue()
	local ret = g_ratevalue[g_rateautoselect]
	return ret, g_rateautoselect
end

local function getoptiondatabyid(id)
	if g_ratevalue[id] ~= nil then
		return g_ratevalue[id]
	else
		return getoptionbasevalue()
	end
end
--================= 对小btn进行处理 =====================
-- h： 横向id  l：纵向id
local function uibtnoptionupdate(l,h)
	local uill = g_uiskilloptions[h]
	if uill ~= nil then
		local cnt = table.getn(uill.btnlist or {})
		for i=1, cnt do
			-- 先进行ui内容显示
			if math.mod(i,2) == 0 then
				local id = math.floor( i/2 )
				uill.btnlist[i]:SetText(getoptiondatabyid(id))
			else
				uill.btnlist[i]:SetCheck(0)
			end
		end
		if l > 0 and l <= cnt then
			uill.btnlist[l*2 - 1]:SetCheck(1)
		end
	end
end

local function uibtnpetoptionupdate(l,h)
	local uill = g_uiskillpetoptions[h]
	if uill ~= nil then
		local cnt = table.getn(uill.btnlist or {})
		for i=1, cnt do
			-- 先进行ui内容显示
			if math.mod(i,2) == 0 then
				local id = math.floor( i/2 )
				uill.btnlist[i]:SetText(getoptiondatabyid(id))
			else
				uill.btnlist[i]:SetCheck(0)
			end
		end
		if l > 0 and l <= cnt then
			uill.btnlist[l*2 - 1]:SetCheck(1)
		end
	end
end

-- h： 横向id  l：纵向id 回复页签用
local function uibtnrroptionupdate(l,h)
	local uill = g_uirrskilloptions[h]
	if uill ~= nil then
		local cnt = table.getn(uill.btnlist or {})
		for i=1, cnt do
			-- 先进行ui内容显示
			if math.mod(i,2) == 0 then
				local id = math.floor( i/2 )
				uill.btnlist[i]:SetText(getoptiondatabyid(id))
			else
				uill.btnlist[i]:SetCheck(0)
			end
		end
		if l > 0 and l <= cnt then
			uill.btnlist[l*2 - 1]:SetCheck(1)
		end
	end
end


-- 根据索引，找到对应心法技能对用skill配置的位置
local function getskillbyxf(xfid,idx)
	local skillaction = g_uiskillactions[idx]
	if skillaction ~= nil then
		local sumskill,index,skillid = GetActionNum("skill"), 1, -1
		for i=1, sumskill do
			local skillaction = EnumAction(i-1, "skill")
			if skillaction:GetID() ~= -1 and skillaction:GetOwnerXinfa() == xfid then
				if idx == index then
					skillid = LifeAbility : GetLifeAbility_Number(skillaction:GetID())
					-- 可使用的技能ID提取出来
					local skilldata,unlocklist = BattleAssist:Farm_GetSkillIds(),{}
					for i, v in ipairs(skilldata) do
						local id = v[1]
						if skillid == id then
							return i, skillid
						end
					end
				end
				index = index+1
			end
		end
	end
	return -1,-1
end

--================= 是否可以使用的技能 =====================
local function isusefulskill(skillid)
	local islearn,isrequire = Player:GetSkillInfo(skillid,"learn"),Player:GetSkillInfo(skillid,"isequirement")
	if islearn and isrequire then
		return 1
	end

	return 0
end


--================ 是否达到道具使用限制 =====================
local function iscanuseitem(itemid, binditemid)
	local cnt = PlayerPackage:CountAvailableItemByIDTable( itemid )
	if binditemid > 0 then
		cnt = cnt + PlayerPackage:CountAvailableItemByIDTable( binditemid )
	end
	if cnt > 0 then
		-- 是否可以使用
		local needlv = PlayerPackage : GetItemNeedLvByIndex(itemid)
		local myLevel = Player:GetData("LEVEL")
		if needlv ~= nil and needlv <= myLevel then
			return 1
		else
			PushDebugMessage("#{ZDZD_200724_16}")
			return 0
		end
	else
		PushDebugMessage("#{ZDZD_200724_15}")
		return 0
	end
end

--================= 是否是必须使用的技能 =====================
local function isnobanskill(skillid)
	for i, v in ipairs(g_nobanskill) do
		if v == skillid then
			return 1
		end
	end
	return 0
end

--================= 是否可以攻击玩家 =====================
local function isbanattackplayer()
	if g_configdata.useSwitch[1] > 0 then
		return 0
	end

	return 1
end

--================= 是否近战门派 =====================
local function autoattackskill_ismeleemp()
	local mpid = Player : GetData("MEMPAI")
	for i, v in ipairs(g_autoattackskill_melee_mp) do
		if v == mpid then
			return 1
		end
	end

	return 0
end

--================= local函数 End=====================
--------------------------------------------------------------------------------------

--================= 初始化页面数据 =====================
function AutoAttackSkill_InitData()
	datareset()
	initconfigdata()

end
--================= 显示UI内容 =====================
function AutoAttackSkill__OnShowUI()
	AutoAttackSkill_UpdateBaseUI()
	AutoAttackSkill_UpdateSkillUI()
	AutoAttackSkill_UpdateOptionUI()
	
	-- 默认选中第一个心法
	AutoAttackSkill_XinFa_Clicked(1)
	AutoAttackSkill_ShowPage()
	this:Show()
end

--================= 显示一些基础内容 =====================
function AutoAttackSkill_UpdateBaseUI()
	-- 隐藏结束条件页的UI
	if AutoAttackSkill_Others_Bk ~= nil and g_data.option ~= g_optionpagedef.stopconfig then
		AutoAttackSkill_Others_Bk:Hide()
	end

	-- 处理自动战斗按钮
	local isworking = BattleAssist:IsWorking()
	if isworking ~= "false" then
		g_uicommoninfo.fight:SetText("#{ZDZD_200724_28}")
	else
		g_uicommoninfo.fight:SetText("#{ZDZD_200724_27}")
	end
	-- 设置页签按钮选中状态
	--local pagecnt = table.getn(g_uipageactions)
	--for i=1, pagecnt do
	--	g_uipageactions[i]:SetCheck(0)
	--end
	--if g_curpage <= pagecnt then
	--	g_uipageactions[g_curpage]:SetCheck(1)
	--end

	-- 设置页签名字
	g_uicommoninfo.title:SetText("#{ZDZD_200724_09}")

	-- 设置是否攻击玩家
	local isbanattack = isbanattackplayer()
	g_uicommoninfo.noattackhm:SetCheck(isbanattack)

	-- 设置是否使用远程攻击
	local check = 1
	if g_configdata.useSwitch[2] > 0 then
		check = 0
	end
	g_uicommoninfo.longfight:SetCheck(check)
	
	local meleeshow = autoattackskill_ismeleemp()
	if meleeshow > 0 then
		g_uicommoninfo.fightbg:Show()
		g_uicommoninfo.nofightbg:SetProperty("UnifiedPosition", g_autoattackskill_nofightpos.old)
		g_uicommoninfo.fight:SetProperty("UnifiedPosition", g_autoattackskill_nofightpos.btnold)
	else
		g_uicommoninfo.fightbg:Hide()
		g_uicommoninfo.nofightbg:SetProperty("UnifiedPosition", g_autoattackskill_nofightpos.new)
		g_uicommoninfo.fight:SetProperty("UnifiedPosition", g_autoattackskill_nofightpos.btnnew)
	end
	
	g_uicommoninfo.baseconfig:SetCheck(1)
	g_uicommoninfo.qiankunpot:SetCheck(0)

	-- 设置位置
	if not this:IsVisible() then
		local pos = Variable:GetVariable("SkillUnionPos")
		if pos ~= nil then
			AutoAttackSkill_Frame:SetProperty("UnifiedPosition", pos)
		end
	end
end

--================= 对技能UI进行内容更新 =====================
function AutoAttackSkill_UpdateSkillUI()
	local mpid = Player:GetData("MEMPAI")

	local xfcnt,skillcnt = table.getn(g_uixfskillactions), table.getn(g_uiskillactions)
	-- 无门派
	if mpid == g_invalidmenpai then
		for i=1, xfcnt do
			g_uixfskillactions[i].action:SetActionItem(-1)
		end
		for i=1, skillcnt do
			g_uiskillactions[i].action:SetActionItem(-1)
			g_uiskillactions[i].lockp:Hide()
		end

		g_uicommoninfo.atbdesc:Hide()
		g_uicommoninfo.mpicon:Hide()
	else
		-- 处理属性提示
		g_uicommoninfo.mpicon:SetToolTip(g_menpaiattr[mpid].Tooltip)
		g_uicommoninfo.mpicon:SetProperty("Image",g_menpaiattr[mpid].image)
		local str = GetDictionaryString( "MPZSX_20071221_0" .. (mpid +1) )
		g_uicommoninfo.atbdesc:SetText("#Y" .. str)
		g_uicommoninfo.atbdesc:Show()
		g_uicommoninfo.mpicon:Show()
		for i=1, xfcnt do
			local action = EnumAction(i-1, "xinfa")
			if action:GetID() ~= 0 then
				g_uixfskillactions[i].action:SetActionItem(action:GetID())
			end
		end
		
		AutoAttackSkill_UpdateSkillUIByXF()
	end

end
--================= 根据心法对应得具体技能UI进行内容更新 =====================
-- notice : g_data.curxfid 需要进行提前进行计算赋值
function AutoAttackSkill_UpdateSkillUIByXF()

	-- 可使用的技能ID提取出来
	local skilldata,unlocklist = BattleAssist:Farm_GetSkillIds(),{}
	for i, v in ipairs(skilldata) do
		local id = v[1]
		unlocklist[id] = i
	end

	-- 处理当前技能action
	local skillcnt = table.getn(g_uiskillactions)
	for i=1, skillcnt do
		g_uiskillactions[i].action:SetActionItem(-1)
		g_uiskillactions[i].lockp:Hide()
	end

	-- 10TL逻辑，照搬
	local sumskill,idx,ownlist = GetActionNum("skill"), 1, {}
	for i=1, sumskill do
		local skillaction = EnumAction(i-1, "skill")
		if skillaction:GetOwnerXinfa() == g_data.curxfid and skillaction:GetDefineID() ~= 3294  and skillaction:GetDefineID() ~= 3295 then
			--跳过部分丛刃技能, actionskill.lua 抄过来的
			if ((skillaction:GetDefineID() < 4533 or skillaction:GetDefineID() > 4536) and (skillaction:GetDefineID() < 4528 or skillaction:GetDefineID() > 4529) 
			and (skillaction:GetDefineID() < 5189 or skillaction:GetDefineID() > 5193) and IsLMSJSecond(skillaction:GetDefineID()) == 0 and IsJYJYSecond(skillaction:GetDefineID()) == 0 
				 and IsWJQFSecond(skillaction:GetDefineID()) == 0)then
				local actionid = skillaction:GetID()
				g_uiskillactions[idx].action:SetActionItem(actionid)
				ownlist[idx] = LifeAbility : GetLifeAbility_Number(actionid)
				idx = idx+1
			end
		end
	end

	-- 处理图标状态
	for i=1, skillcnt do
		-- 该技能是存在的
		local id = ownlist[i]
		if id ~= nil then
			-- 判断技能是否禁用该技能, 普功技能也会被禁用
			if unlocklist[id] == nil or id == g_speical_ban_skill then
				g_uiskillactions[i].lock:Hide()
				g_uiskillactions[i].ban:Show()
				g_uiskillactions[i].unlock:Hide()
			else
				-- 开始读取配置
				local isuseful = isusefulskill(id)
				if isuseful > 0 then
					g_uiskillactions[i].lock:Hide()
					g_uiskillactions[i].ban:Hide()
					g_uiskillactions[i].unlock:Show()
					local isusing = g_configdata.useskill[unlocklist[id]]
					g_uiskillactions[i].unlock:SetCheck(isusing)
				else
					g_uiskillactions[i].lock:Show()
					g_uiskillactions[i].ban:Hide()
					g_uiskillactions[i].unlock:Hide()
				end
			end
			-- 显示状态
			g_uiskillactions[i].lockp:Show()
		else
			-- 隐藏所有状态UI
			g_uiskillactions[i].lockp:Hide()
		end
	end

end

--================= 刷新选项UI内容 =====================
function AutoAttackSkill_UpdateOptionBaseUI()
	-- 先进行选项按钮更新
	local mpid,cnt,btnnum,list = Player:GetData("MEMPAI"),table.getn(g_uioptionsactions),2,{}
	if g_menpai_recover[mpid] ~= nil then
		btnnum = g_optionbtnattr.special.num
		list = g_optionbtnattr.special.text
	else
		btnnum = g_optionbtnattr.normal.num
		list = g_optionbtnattr.normal.text
	end

	for i=1, cnt do
		if i <= btnnum then
			g_uioptionsactions[i]:SetText(list[i])
			g_uioptionsactions[i]:Show()
		else
			g_uioptionsactions[i]:Hide()
		end
	end

	if g_data.option == g_optionpagedef.recoverskill then
		g_uicommoninfo.skill:Show()
		g_uicommoninfo.explain:Hide()
		g_uicommoninfo.petskill:Hide()
		local rrskillcnt = table.getn(g_uirrskilloptions or {})
		for i=1, rrskillcnt do
			g_uirrskilloptions[i].parent:Hide()
		end
	else
		g_uicommoninfo.skill:Hide()
		if g_data.option == g_optionpagedef.stopconfig then
			g_uicommoninfo.explain:Hide()
			g_uicommoninfo.petskill:Hide()
		elseif g_data.option == g_optionpagedef.recoverinfo then
			g_uicommoninfo.explain:Show()
			g_uicommoninfo.petskill:Hide()
		elseif g_data.option == g_optionpagedef.petskill then
			g_uicommoninfo.explain:Hide()
			g_uicommoninfo.petskill:Show()
		end

		local optionscnt = table.getn(g_uiskilloptions or {})
		for i=1, optionscnt do
			g_uiskilloptions[i].parent:Hide()
		end
		local optionscnt = table.getn(g_uiskillpetoptions or {})
		for i=1, optionscnt do
			g_uiskillpetoptions[i].parent:Hide()
		end
		if g_data.option == g_optionpagedef.recoverinfo then
			if g_data.optiontype == g_optiontype_def.off then
				g_uicommoninfo.auto:SetCheck(0)
				g_uicommoninfo.off:SetCheck(1)
			else	
				g_uicommoninfo.auto:SetCheck(1)
				g_uicommoninfo.off:SetCheck(0)
			end
		end
	end
end

function AutoAttackSkill_UpdateOptionUI()

	AutoAttackSkill_UpdateOptionBaseUI()
	AutoAttackSkill_Update_InputNumber()
	-- 处理药品界面信息
	if g_data.option == g_optionpagedef.recoverinfo then
		local cnt = table.getn(g_recoverInfo)
		if cnt > 0 then
			for i=1,cnt do
				g_recoverInfo[i]:update()
			end
		else
			g_recoverInfo = {}
			for i=1,3 do
				AutoAttackSkill_MakeRecoverInfo(i)
			end
		end
	elseif g_data.option == g_optionpagedef.recoverskill then
		local cnt = table.getn(g_recoverSkills)
		if cnt > 0 then
			for i=1,cnt do
				if g_recoverSkills[i] ~= nil then
					g_recoverSkills[i]:update()
				end
			end
		else
			local recoverSkills = {}
			for i, v in ipairs(BattleAssist:Farm_GetSkillIds()) do
				if v[2] == 5 then
					table.insert( recoverSkills, { v, i } )
				end
			end
			g_recoverSkills = {}
			-- 这里最多就3个，超出来会有显示问题
			for i,v in ipairs(recoverSkills) do
				AutoAttackSkill_MakeRecoverSkillInfo( i, v[1], v[2] )
			end
		end
	elseif g_data.option == g_optionpagedef.petskill then
		local cnt,petskills = table.getn(g_petSkills),getpetskill()
		if cnt > 0 then
			for i=1,cnt do
				g_petSkills[i]:update(petskills[i])
			end
		else
			g_petSkills = {}
			for i,v in ipairs(petskills) do
				AutoAttackSkill_MakePetSkill(i,v)
			end
		end
	end

	-- 专注回复选项显隐
	if g_data.option == g_optionpagedef.recoverskill then
		AutoAttackSkill_Skill4:Show()
		AutoAttackSkill_Skill4_Button:SetCheck(g_configdata.useSwitch[10])
	else
		AutoAttackSkill_Skill4:Hide()
	end
end

-- 专注回复按钮
function AutoAttackSkill_Skill4_ButtonCheck_Clicked()

	if g_configdata.useSwitch[10] > 0 then
		g_configdata.useSwitch[10] = 0
		AutoAttackSkill_Skill4_Button:SetCheck(0)
	else
		g_configdata.useSwitch[10] = 1
		AutoAttackSkill_Skill4_Button:SetCheck(1)
	end

	BattleAssist:Farm_UpdateConfig(makecfgstr())
	BattleAssist:Farm_SetConfigData(g_configdata)
end

function AutoAttackSkill_DispatchCall( fn, ... )
	if not fn then
		return
	end
	fn( unpack(arg) )
end

function AutoAttackSkill_CallCb( i, key, ... )
	local inst = g_recoverInfo[i]
	if inst then
		AutoAttackSkill_DispatchCall( inst[key], inst, unpack(arg) )
	end
end

function AutoAttackSkill_CallCb2( i, key, ... )
	local inst = g_recoverSkills[i]
	if inst then
		AutoAttackSkill_DispatchCall( inst[key], inst, unpack(arg) )
	end
end

function AutoAttackSkill_CallCb3( i, key, ... )
	local inst = g_petSkills[i]
	if inst then
		AutoAttackSkill_DispatchCall( inst[key], inst, unpack(arg) )
	end
end

--================= 处理自动战斗的各个时间 =====================
function AutoAttackSkill_AttackEvent(event)
	--PushDebugMessage("AutoAttackSkill_AttackEvent 我要打开了"..event)
	if event == "config_update" then
		--AutoAttackSkill_InitData()
		initconfigdata()
		BattleAssist:Farm_UpdateConfig(makecfgstr())
		AutoAttackSkill_Update_InputNumber()
	elseif event == "config" then
		AutoAttackSkill_InitData()
		BattleAssist:Farm_UpdateConfig(makecfgstr())
		if g_configdata.valid == 0 then
			return
		end
		AutoAttackSkill__OnShowUI()
	elseif event == "config_reset" then
		g_recoverSkills = {}
		--换门派时候，强行关闭界面
		if this:IsVisible() then
			AutoAttackSkill_OnClose()
		end
	elseif event == "start" then
		--AutoAttackSkill_InitData()
		-- 保持原有状态
		initconfigdata()
		if g_configdata.valid == 0 then
			return
		else
			BattleAssist:Start("Farm",makecfgstr())
		end
	elseif event == "stop" then
		BattleAssist:Stop()
	end
end

--================= 药品设置 =====================
function AutoAttackSkill_MakeRecoverInfo( i )
	local texts = { "#{ZDZD_200724_13}", "#{ZDZD_200724_21}", "#{ZDZD_200724_22}" }
	local potions = BattleAssist:Farm_GetPotionIds(i)
	local delegate = {
		["updatecombo"] = function( self, select )
			g_uiskilloptions[i].combo:ResetList()
			-- 会默认添加一个不使用的选项
			g_uiskilloptions[i].combo:AddTextItem("#{ZDZD_200724_52}",0)
			
			local potionscnt = table.getn(potions or {})
			for j=1, potionscnt do
				local data = potions[j]
				local desc,cnt = PlayerPackage:GetItemName(data[1])
				local cnt = PlayerPackage:CountAvailableItemByIDTable( data[1] ) + PlayerPackage:CountAvailableItemByIDTable( data[5] )
				if cnt > 0 then
					-- 拥有数量大于0，需要变换文字显示
					desc = ScriptGlobal_Format("#{ZDZD_200724_14}",desc,tostring(cnt))
				end
				g_uiskilloptions[i].combo:AddTextItem(desc,j)
			end
			-- 当前有默认选中

			g_uiskilloptions[i].combo:SetCurrentSelect(select)
			g_uiskilloptions[i].parent:Show()
		end,
		["updatetext"] = function( self )
			if g_data.optiontype == g_optiontype_def.off then
				local btnidx,rate = getmodifyvalue(g_configdata.usepotionoffc[i])
				g_uiskilloptions[i].name:SetText(ScriptGlobal_Format(texts[i], rate))
			else
				local btnidx,rate = getmodifyvalue(g_configdata.usepotionc[i])
				g_uiskilloptions[i].name:SetText(ScriptGlobal_Format(texts[i], rate))
			end
		end,
		["update"] = function( self )
			-- 获取当前我使用的道具
			local cur,potionscnt = 0, table.getn(potions or {})
			-- 处理UI
			g_uiskilloptions[i].combo:ResetList()
			if g_data.optiontype == g_optiontype_def.off then
				if g_configdata.usepotionoff[i] == 0 then
					cur = 0 
				else
					cur = g_configdata.usepotionofft[i]
				end
				self:updatecombo(cur)
				-- 开始处理按钮选中
				local btnidx,rate = getmodifyvalue(g_configdata.usepotionoffc[i])
				g_uiskilloptions[i].name:SetText(ScriptGlobal_Format(texts[i], rate))
				-- 进行按钮内容选中
				uibtnoptionupdate(btnidx,i)
			else
				if g_configdata.usepotion[i] == 0 then
					cur = 0 
				else
					cur = g_configdata.usepotiont[i]
				end
				self:updatecombo(cur)
				-- 开始处理按钮选中
				local btnidx,rate = getmodifyvalue(g_configdata.usepotionc[i])
				g_uiskilloptions[i].name:SetText(ScriptGlobal_Format(texts[i], rate))
				-- 进行按钮内容选中
				uibtnoptionupdate(btnidx,i)
			end
		end,
		["onPosChange"] = function( self, select )
			-- 获得当前选中的大小
			if g_data.optiontype == g_optiontype_def.off then
				g_configdata.usepotionoffc[i] = getoptiondatabyid(select)
			else
				g_configdata.usepotionc[i] = getoptiondatabyid(select)
			end
			-- 刷新选中按钮
			uibtnoptionupdate(select,i)
			-- 存储配置
			BattleAssist:Farm_UpdateConfig(makecfgstr())
			BattleAssist:Farm_SetConfigData( g_configdata )
			AutoAttackSkill_CallCb( i, "updatetext" )
		end,
		["onSetPotionOk"] = function( self, typei )
			if g_data.optiontype == g_optiontype_def.off then
				if g_configdata.usepotionoff[i] == 0 then
					if typei == 0 then
						return
					end
				elseif g_configdata.usepotionofft[i] == typei then
					return
				end

				if typei == 0 then
					g_configdata.usepotionoff[i] = 0 
				else
					local data,select = potions[typei],0
					if iscanuseitem(data[1], data[5]) <= 0 then
						if g_configdata.usepotionoff[i] ~= 0 then
							select = g_configdata.usepotionofft[i]
						end
						g_uiskilloptions[i].combo:SetCurrentSelect(select)
						return
					end
					g_configdata.usepotionoff[i] = 1
					g_configdata.usepotionofft[i] = typei
				end
			else
				if g_configdata.usepotion[i] == 0 then
					if typei == 0 then
						return
					end
				elseif g_configdata.usepotiont[i] == typei then
					return
				end

				if typei == 0 then
					g_configdata.usepotion[i] = 0 
				else
					local data,select = potions[typei],0
					if iscanuseitem(data[1], data[5]) <= 0 then
						if g_configdata.usepotion[i] ~= 0 then
							select = g_configdata.usepotiont[i]
						end
						g_uiskilloptions[i].combo:SetCurrentSelect(select)
						return
					end
					g_configdata.usepotion[i] = 1
					g_configdata.usepotiont[i] = typei
				end
			end
			--g_configdata.usepotionc[i] = getoptionbasevalue()

			BattleAssist:Farm_UpdateConfig(makecfgstr())
			BattleAssist:Farm_SetConfigData( g_configdata )
			-- 刷新选中按钮
			--uibtnoptionupdate(g_rateautoselect,i)
			AutoAttackSkill_CallCb( i, "updatetext" )
		end,
	}
	g_recoverInfo[i] = delegate
	delegate:update()
end


function AutoAttackSkill_MakeRecoverSkillInfo( i, skillinfo, skillIdx )
	local texts = { [4] = {"#{ZDZD_200724_47}","#{ZDZD_200724_48}","#{ZDZD_200724_50}",},
					[12] = {"#{ZDZD_200724_65}","#{ZDZD_200724_66}","",},
					[14] = {"#{ZDZD_200724_67}","","",},
				}
	local delegate = {
		["update"] = function( self )
			-- 处理UI
			local max = table.getn(g_uirrskilloptions)
			if i > max then
				PushDebugMessage("g_uirrskilloptions: Table is error")
				return
			end
			local mpid = Player:GetData("MEMPAI")
			local textsdata = texts[mpid]
			if textsdata == nil then
				PushDebugMessage("AutoAttackSkill_MakeRecoverSkillInfo: texts is error")
				return
			end
			-- 获得我当前的技能ID
			local id = skillinfo[1]
			local btnidx,rate = getmodifyvalue(g_configdata.useRecoverSkill[i])
			local text = ScriptGlobal_Format(textsdata[i], rate)
			-- if i == g_specialrecoverskill then
			-- 	local islearn = Player:GetSkillInfo(id,"learn")
			-- 	if not islearn then
			-- 		text = ScriptGlobal_Format("#{ZDZD_200724_49}", rate)
			-- 	end
			-- end
			g_uirrskilloptions[i].name:SetText(text)
			g_uirrskilloptions[i].parent:Show()
			if mpid == 4 and i == 2 then
				g_uirrskilloptions[i].parent:Hide()
			end
			-- 进行按钮内容选中
			uibtnrroptionupdate(btnidx,i)

			--local isusing = g_configdata.useskill[skillIdx]
		end,
		["onPosChange"] = function( self, select )
			-- 默认选中50
			g_configdata.useRecoverSkill[i] = getoptiondatabyid(select)
			-- 刷新选中按钮
			--uibtnoptionupdate(g_rateautoselect,i)
			AutoAttackSkill_CallCb2( i, "update" )
			BattleAssist:Farm_UpdateConfig(makecfgstr())
			BattleAssist:Farm_SetConfigData( g_configdata )
		end,
	}	
	g_recoverSkills[i] = delegate
	delegate:update()
end

function AutoAttackSkill_MakePetSkill( i, info )
	local delegate = {
		["info"] = { -1, -1, -1, -1 },
		["updateText"] = function(self)
			local text = ""
			if i == 1 then
				text = ScriptGlobal_Format( "#{ZDZD_200724_13}", ""..g_configdata.usePetSkillc[i]  )
			elseif i == 2 then
				text = ScriptGlobal_Format( "#{ZDZD_200724_21}", ""..g_configdata.usePetSkillc[i]  )
			end
			g_uiskillpetoptions[i].name:SetText(text)

			local btnidx,rate = getmodifyvalue(g_configdata.usePetSkillc[i])
			uibtnpetoptionupdate(btnidx,i)
		end,
		["update"] = function( self, newinfo )
			self.info = newinfo
			
			g_uiskillpetoptions[i].combo:ResetList()
			-- 会默认添加一个不使用的选项
			g_uiskillpetoptions[i].combo:AddTextItem("#{ZDZD_200724_52}",0)
			local cnt,cur = table.getn(self.info),0
			for j=1, cnt do
				local name = Player:GetSkillInfo(self.info[j],"name")
				g_uiskillpetoptions[i].combo:AddTextItem(name,j)
				--if g_configdata.usePetSkillt[i] == self.info[j] then
				--end
			end
			cur = g_configdata.usePetSkillt[i] + 1
			if g_configdata.usePetSkill[i] == 0 then
				cur = 0 
			end

			g_uiskillpetoptions[i].combo:SetCurrentSelect(cur)
			g_uiskillpetoptions[i].parent:Show()
			self:updateText()
		end,
		["onPosChange"] = function( self ,select )
			--uibtnoptionupdate(select,i)
			g_configdata.usePetSkillc[i] = getoptiondatabyid(select)
			BattleAssist:Farm_UpdateConfig(makecfgstr())
			BattleAssist:Farm_SetConfigData( g_configdata )
			self:updateText()
		end,
		["onSetPotionOk"] = function( self, typei )
			if g_configdata.usePetSkill[i] == 0 then
				if typei == 0 then
					return
				end
			elseif g_configdata.usePetSkillt[i] + 1 == typei then
				return
			end

			local realtypei = typei - 1
			if typei == 0 then
				g_configdata.usePetSkill[i] = 0
			else
				g_configdata.usePetSkill[i] = 1
				g_configdata.usePetSkillt[i] = realtypei
			end
			--g_configdata.usePetSkillc[i] = getoptionbasevalue()
			BattleAssist:Farm_UpdateConfig(makecfgstr())
			BattleAssist:Farm_SetConfigData( g_configdata )

			-- 刷新选中按钮
			--uibtnoptionupdate(g_rateautoselect,i)
			AutoAttackSkill_CallCb3( i, "updateText" )
		end,
	}
	g_petSkills[i] = delegate
	delegate:update(info)
end

---------------------------------------点击事件-----------------------------------------------------
function AutoAttackSkill_XinFa_Clicked(idx)
	local mpid = Player:GetData("MEMPAI")
	local xfcnt = table.getn(g_uixfskillactions)
	-- 点没点都会进行状态还原
	for i=1, xfcnt do
		g_uixfskillactions[i].check:SetPushed(0)
	end

	-- 无门派
	if mpid == g_invalidmenpai then
		return
	else
		if idx > 0 and idx <= xfcnt then
			local action = EnumAction(idx-1, "xinfa")
			g_data.curxfid = action:GetID()
			AutoAttackSkill_UpdateSkillUIByXF()
			
			g_uixfskillactions[idx].check:SetPushed(1)
			
			-- 等于默认点击了第一个技能栏，看了下，原版门派技能栏没有进行默认选中
			--AutoAttackSkill_Skill_Clicked(1)
		end
	end
end

function AutoAttackSkill_Skill_Clicked(idx)
	local xfcnt = table.getn(g_uiskillactions)
	-- 点没点都会进行状态还原
	for i=1, xfcnt do
		g_uiskillactions[i].action:SetPushed(0)
	end
	if idx > 0 and idx <= xfcnt then
		g_uiskillactions[idx].action:SetPushed(1)
	end
end

function AutoAttackSkill_SkillLock_Clicked(idx)
	local mpid = Player:GetData("MEMPAI")
	-- 无门派
	if mpid == g_invalidmenpai then
		return
	else
		local n,skillid = getskillbyxf(g_data.curxfid,idx)
		if n < 0 then
			return
		end
		-- 普攻技能,禁止点击取消
		if isnobanskill(skillid) > 0 then
			PushDebugMessage("#{ZDZD_200724_53}")
			g_uiskillactions[idx].unlock:SetCheck(1)
			return
		end
		-- 判断技能是否学会 ，现阶段默认使用的技能也可以设置，只不过显示解锁而已
		-- 切换状态
		if g_configdata.useskill[n] == 1 then
			g_configdata.useskill[n] = 0
		else
			g_configdata.useskill[n] = 1
		end

		BattleAssist:Farm_UpdateConfig(makecfgstr())
		BattleAssist:Farm_SetConfigData( g_configdata )

		AutoAttackSkill_UpdateSkillUIByXF()
	end
end

function AutoAttackSkill_Option_Click(idx)
	-- 需要根据门派进行内容特殊处理, 峨眉没有第二选项
	local mpid = Player:GetData("MEMPAI")
	if g_menpai_recover[mpid] == nil then
		-- 非回血门派，没有第二个选项页
		if idx >= 2 then
			idx = idx + 1
		end
	end

	if g_data.option == idx then
		return
	end

	if g_StopCondition_AskSave_Flag == 0 and g_data.option == g_optionpagedef.stopconfig then
		g_StopCondition_CallBack_Type = idx
		if AutoAttackSkill_AskSave() == 1 then
			return
		end
	end

	g_data.option = idx
	g_data.optiontype = g_optiontype_def.auto

	AutoAttackSkill_UpdateOptionUI()
end

--================= 百分比情况 =====================
-- i: 纵向索引 idx：横向索引
function AutoAttackSkill_OptionPercent_Click(i, idx)
	if g_data.option == g_optionpagedef.recoverinfo then
		AutoAttackSkill_CallCb( i, "onPosChange", idx )
	elseif g_data.option == g_optionpagedef.petskill then
		AutoAttackSkill_CallCb3( i, "onPosChange", idx  )
	end
end

--================= 回复技能点击情况 =====================
function AutoAttackSkill_RecoverOptionPercent_Click(i, idx)
	if g_data.option == g_optionpagedef.recoverskill then
		AutoAttackSkill_CallCb2( i, "onPosChange", idx  )
	end
end

--================= 下拉条变化 =====================
function AutoAttackSkill_ComboListSelectChanged(i)
	-- 进行初始条件判断
	if g_data.option == g_optionpagedef.recoverinfo then
		if g_uiskilloptions[i] == nil then
			return
		end
		local szname, idx = g_uiskilloptions[i].combo:GetCurrentSelect()
		if idx == nil or idx == -1  then
			return
		end
		AutoAttackSkill_CallCb( i, "onSetPotionOk", idx )
	elseif g_data.option == g_optionpagedef.petskill then
		if g_uiskillpetoptions[i] == nil then
			return
		end
		local szname, idx = g_uiskillpetoptions[i].combo:GetCurrentSelect()
		if idx == nil or idx == -1  then
			return
		end
		AutoAttackSkill_CallCb3( i, "onSetPotionOk", idx  )
	end
end
--================= 开始工作 =====================
function AutoAttackSkill_OnStartClick()
	local isworking = BattleAssist:IsWorking()
	local fbKey, branch = AutoAttack_Button_GetFBKeyAndBranchName()
	if fbKey and BattleAssist:AskIsNeiGuaOpen("FB") then
		if branch ~= isworking then
			-- 开启自动副本
			if AutoAttackSkill_CheckOpenAutoFB() == 1 then
				BattleAssist:Start("FB", fbKey)
			end
		else
			-- 关闭自动副本
			BattleAssist:Stop()
		end
	else
		if isworking == "true" then
			PushEvent("TRIGGER_ZIDONGZHANDOU","stop")
		else
			PushEvent("TRIGGER_ZIDONGZHANDOU","start")
		end	
	end

	-- 始终一个状态
	g_uicommoninfo.fight:SetCheck(0)
end

--================= 开始副本战斗的条件检查 =====================
function AutoAttackSkill_CheckOpenAutoFB()
	if not BattleAssist:CheckConditions("FB") then
		return 0
	end

	return AutoAttack_Button_CheckOpenAutoFB()
end

--================= 是否可以攻击玩家 =====================
function AutoAttackSkill_OnAttackHumanClick()
	-- 设置是否攻击玩家
	if g_configdata.useSwitch[1] > 0 then
		g_configdata.useSwitch[1] = 0
	else
		g_configdata.useSwitch[1] = 1
	end
	
	-- 配置存储
	BattleAssist:Farm_UpdateConfig(makecfgstr())
	BattleAssist:Farm_SetConfigData( g_configdata )

	local isattackplayer = isbanattackplayer()
	g_uicommoninfo.noattackhm:SetCheck(isattackplayer)
end

--================= 是否可以攻击玩家 =====================
function AutoAttackSkill_OnUseLongRangeSkillClick()
	-- 设置是否攻击玩家
	if g_configdata.useSwitch[2] > 0 then
		g_configdata.useSwitch[2] = 0
	else
		g_configdata.useSwitch[2] = 1
	end
	
	-- 配置存储
	BattleAssist:Farm_UpdateConfig(makecfgstr())
	BattleAssist:Farm_SetConfigData( g_configdata )

	local check = 1 
	if g_configdata.useSwitch[2] > 0 then
		check = 0
	end

	g_uicommoninfo.longfight:SetCheck(check)
end

--================= 切换页签 =====================
function AutoAttackSkill_Page_Switch(page)
	
	if page > g_curpage or page < 0 then
		AutoAttackSkill_ClearPage()
		return
	end

	-- 询问是否保存数据
	if g_StopCondition_AskSave_Flag == 0 then
		g_StopCondition_CallBack_Type = 100 + page
		if AutoAttackSkill_AskSave() == 1 then
			AutoAttackSkill_ClearPage()
			return
		end
	end

	if page == 5 then
		if DataPool:Lua_CheckOpenTalent() == 1 then
			ToggleTalentPage()
		else
			AutoAttackSkill_ClearPage()
			return
		end
	end
	-- 关闭
	AutoAttackSkill_OnClose()
	-- 打开各个界面
	if page == 1 then
		OpenCommonSkillPage()
	elseif page == 2 then
		local menpai = Player:GetData("MEMPAI")
		if menpai == g_invalidmenpai then 
			PushDebugMessage("#{ZDZD_200724_45}")
			AutoAttackSkill_ClearPage()
			return
		end
		OpenSkillBook()
	elseif page == 3 then
		OpenZhenfaFream()
	elseif page == 4 then
		OpenLifePage()
	end
end

function AutoAttackSkill_OnClose()
	if g_StopCondition_AskSave_Flag == 0 then
		-- 询问是否保存数据
		g_StopCondition_CallBack_Type = 0
		if AutoAttackSkill_AskSave() == 1 then
			return
		end
	end

	-- 关闭界面的时候需要保存相对位置
	local unifiedpos = AutoAttackSkill_Frame:GetProperty("UnifiedPosition")
	Variable:SetVariable("SkillUnionPos", unifiedpos, 1)

	this:Hide()
end

--====================恢复界面的默认相对位置=========================
function AutoAttackSkill_OnResetPos()
	AutoAttackSkill_Frame:SetProperty("UnifiedPosition",g_unifiedposistion)
end

function AutoAttackSkill_SetTabColor()
	

	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								[0] = AutoAttackSkill_CommonlySkill,
								AutoAttackSkill_ActionSkill,
								AutoAttackSkill_ZhenfaSkill,
								AutoAttackSkill_LifeSkill,
								AutoAttackSkill_AutoAttack,
								AutoAttackSkill_ZongMenSkill,
							};

	local TAB_TEXT = {
		[0] = "#{INTERFACE_XML_494}",
		"#{INTERFACE_XML_448}",
		"#{JBGXW_150526_215}",
		"#{INTERFACE_XML_635}",
		"#{ZDZD_200724_08}",
		"#{ZMTF_230628_20}",
	};
	
	tab[0]:SetText(noselColor..TAB_TEXT[0]);
	tab[1]:SetText(noselColor..TAB_TEXT[1]);
	tab[2]:SetText(noselColor..TAB_TEXT[2]);
	tab[3]:SetText(noselColor..TAB_TEXT[3]);
	tab[4]:SetText(selColor..TAB_TEXT[4]);
	tab[5]:SetText(noselColor..TAB_TEXT[5])
end

function AutoAttackSkill_ChildPage_Switch(idx)
	if idx == 1 then
		return
	end

	-- 询问是否保存数据
	if g_StopCondition_AskSave_Flag == 0 then
		g_StopCondition_CallBack_Type = idx + 50
		if AutoAttackSkill_AskSave() == 1 then
			return
		end
	end

	AutoAttackSkill_OnClose()

	if idx == 2 then
		PushEvent("QIANKUNPOT_SHOW")
	end
end

-- 刷新数据和UI：结束条件
function AutoAttackSkill_Update_InputNumber()
	local n1, n2, n3 = BattleAssist:Farm_GetCfgData_MaxNum()
	if n1 ~= nil and g_StopCondition_NumberInput_Box[1] ~= nil then
		if n1 <= 0 then
			g_StopCondition_NumberInput_Box[1]:SetText("") --空值表示不做数量判断
		else
			g_StopCondition_NumberInput_Box[1]:SetText(tostring(n1))
		end
	end
	if n2 ~= nil and g_StopCondition_NumberInput_Box[2] ~= nil then
		if n2 <= 0 then
			g_StopCondition_NumberInput_Box[2]:SetText("") --空值表示不做数量判断
		else
			g_StopCondition_NumberInput_Box[2]:SetText(tostring(n2))
		end
	end

	if n3 ~= nil and g_StopCondition_NumberInput_Box[3] ~= nil then
		if n3 <= 0 then
			g_StopCondition_NumberInput_Box[3]:SetText("") --空值表示不做数量判断
		else
			g_StopCondition_NumberInput_Box[3]:SetText(tostring(n3))
		end
	end

	g_StopCondition_Config_Data[1] = n1
	g_StopCondition_Config_Data[2] = n2
	g_StopCondition_Config_Data[3] = n3
	
	if AutoAttackSkill_Others_Save ~= nil then
		AutoAttackSkill_Others_Save:Disable()
	end

	if AutoAttackSkill_Others_Bk ~= nil and g_data.option == g_optionpagedef.stopconfig then
		if AutoAttackSkill_Frame:IsVisible() and ( not AutoAttackSkill_Others_Bk:IsVisible() ) then
			-- 显示UI
			AutoAttackSkill_Others_Bk:Show()
			-- 输入框设置焦点
			if g_StopCondition_NumberInput_Box[1] ~= nil then
				g_StopCondition_NumberInput_Box[1]:SetProperty("DefaultEditBox", "True")
			end
		end
	else
		if AutoAttackSkill_Others_Bk:IsVisible() then
			AutoAttackSkill_Others_Bk:Hide()
		end
	end

	AutoAttackSkill_ExpBtn_Update()
end

-- 输入数字：结束条件
function AutoAttackSkill_NumberInput_OnTextChanged(n_type)
	if g_StopCondition_NumberInput_Box[n_type] == nil then
		return
	end

	local text = g_StopCondition_NumberInput_Box[n_type]:GetText()
	if text == nil then
		return
	end
	local num = 0
	if text ~= "" then
		num = tonumber(text)
		if num == nil then return end
	end

	if n_type == 3 then
		local maxlevel = Player:GetDefineHumanMaxLevel()
		if Player:GetData("IsExpandLevelPlayer") > 0 then
			maxlevel = Player:GetDefineHumanMaxLevel()
		else
			maxlevel = Player:GetDefineHumanMaxLevelSub()
		end
		local specKaJi89 = Player : GetData("SPECKAJI89") 
		if KaJi:LuaFnIsKaJiServer() == 1 then
			maxlevel = KaJi:LuaFnGetKaJiLeveL()	
		elseif specKaJi89 == 1 or specKaJi89 == 2 then
			maxlevel = 89
		end
		if num >= maxlevel then
			num = maxlevel
			g_StopCondition_NumberInput_Box[n_type]:SetTextOriginal(tostring(maxlevel))
		end
	end

	if num > 9999999 then
		num = 9999999
		g_StopCondition_NumberInput_Box[n_type]:SetText("9999999")
	elseif num <= 0 then
		num = 0
		if text ~= "" then
			g_StopCondition_NumberInput_Box[n_type]:SetText("")
		end
	end

	-- 激活/置灰保存按钮
	if AutoAttackSkill_Others_Save ~= nil then
		if g_StopCondition_Config_Data[n_type] ~= num then
			AutoAttackSkill_Others_Save:Enable()
		else
			AutoAttackSkill_Others_Save:Disable()
		end
	end
end

-- 点击保存：结束条件
function AutoAttackSkill_OnSave(secconfirm)
	local n1, n2, n3 = AutoAttackSkill_GetNumber_StopConditon()
	if n1 == nil then
		return
	end

	-- 将UI上的数据持久化
	local is_changed = 0
	if g_StopCondition_Config_Data[1] ~= n1 then
		g_StopCondition_Config_Data[1] = n1
		is_changed = 1
	end
	if g_StopCondition_Config_Data[2] ~= n2 then
		g_StopCondition_Config_Data[2] = n2
		is_changed = 1
	end
	if g_StopCondition_Config_Data[3] ~= n3 then
		-- 如果等级变化，需要进行二次确诊
		if secconfirm < 1 then
			local msgdesc = ScriptGlobal_Format("#{ZDZD_20220815_21}",tostring(n3))
			MessageBoxSelf3("AutoAttackSkill_OnSaveConfirm", {["Content"] = msgdesc, ["Type"] = "YesNo"})
			return
		end
		g_StopCondition_Config_Data[3] = n3
		is_changed = 1
	end

	if is_changed == 1 then
		BattleAssist:Farm_SetCfgData_MaxNum(n1, n2, n3)
	end
	-- 置灰保存按钮
	if AutoAttackSkill_Others_Save ~= nil then
		AutoAttackSkill_Others_Save:Disable()
	end
	-- 输入框失去焦点
	if g_StopCondition_NumberInput_Box[1] ~= nil then
		g_StopCondition_NumberInput_Box[1]:SetProperty("DefaultEditBox", "False")
	end
	if g_StopCondition_NumberInput_Box[2] ~= nil then
		g_StopCondition_NumberInput_Box[2]:SetProperty("DefaultEditBox", "False")
	end
	if g_StopCondition_NumberInput_Box[3] ~= nil then
		g_StopCondition_NumberInput_Box[3]:SetProperty("DefaultEditBox", "False")
	end


end

-- 获取UI上的数据：结束条件
function AutoAttackSkill_GetNumber_StopConditon()
	if g_StopCondition_NumberInput_Box[1] == nil or g_StopCondition_NumberInput_Box[2] == nil 
		or g_StopCondition_NumberInput_Box[3] == nil then
		return nil, nil, nil
	end

	local text1 = g_StopCondition_NumberInput_Box[1]:GetText()
	local text2 = g_StopCondition_NumberInput_Box[2]:GetText()
	local text3 = g_StopCondition_NumberInput_Box[3]:GetText()
	local n1, n2, n3 = 0, 0, 0
	if text1 ~= nil and text1 ~= "" then
		n1 = tonumber(text1)
	end
	if text2 ~= nil and text2 ~= "" then
		n2 = tonumber(text2)
	end
	if text3 ~= nil and text3 ~= "" then
		n3 = tonumber(text3)
	end
	return n1, n2, n3
end

-- 询问是否关闭：结束条件
function AutoAttackSkill_AskSave()
	local n1, n2, n3 = AutoAttackSkill_GetNumber_StopConditon()
	if n1 == nil then
		return 0
	end

	if g_StopCondition_Config_Data[1] ~= n1 or g_StopCondition_Config_Data[2] ~= n2 
		or g_StopCondition_Config_Data[3] ~= n3 then
		g_StopCondition_AskSave_Flag = 1
		MessageBoxSelf3("AutoAttackSkill_CallBack_AskSave_OnClose", {["Content"] = "#{ZDZD_20220815_11}", ["Type"] = "YesNo"})
		return 1
	end

	return 0
end

-- 询问是否关闭的回调：结束条件
function AutoAttackSkill_CallBack_AskSave_OnClose(strRet)
	if nil == strRet then
		return
	end

	-- Input控件的Text设置成DataPool中的数据，然后根据g_StopCondition_CallBack_Type的值继续原操作
	if "Yes" == strRet or "Ok" == strRet then

		AutoAttackSkill_Update_InputNumber()

		if g_StopCondition_CallBack_Type <= 0 then
			-- 按关闭按钮
			AutoAttackSkill_OnClose()

		elseif g_StopCondition_CallBack_Type <= 50 then
			-- 切换选项页（药品设置等）
			AutoAttackSkill_Option_Click(g_StopCondition_CallBack_Type)

		elseif g_StopCondition_CallBack_Type <= 100 then
			-- 切换顶端页签（乾坤壶等）
			AutoAttackSkill_ChildPage_Switch(g_StopCondition_CallBack_Type - 50)

		elseif g_StopCondition_CallBack_Type <= 200 then
			-- 切换底端页签（门派技能等）
			AutoAttackSkill_Page_Switch(g_StopCondition_CallBack_Type - 100)
		end
	end

	-- 不隐藏结束条件这个页面，有些按钮要调整回去
	if "No" == strRet then
		if g_StopCondition_CallBack_Type <= 0 then
			-- 按关闭按钮
			return
		elseif g_StopCondition_CallBack_Type <= table.getn(g_optionpagedef) then
			-- 切换选项页（药品设置等）

		elseif g_StopCondition_CallBack_Type <= 100 then
			-- 切换顶端页签（乾坤壶等）

		elseif g_StopCondition_CallBack_Type <= 200 then
			-- 切换底端页签（门派技能等）
			-- AutoAttackSkill_SetTabColor()
		end
	end

	g_StopCondition_AskSave_Flag = 0
end

-- 刷新经验相关的按钮
function AutoAttackSkill_ExpBtn_Update()
	local switch =  g_configdata.useSwitch
	if switch[3] ~= nil and switch[3] > 0 then
		g_uicommoninfo.tldbtn:SetCheck(1)
	else
		g_uicommoninfo.tldbtn:SetCheck(0)
	end

	if switch[4] ~= nil and switch[4] > 0 then
		g_uicommoninfo.xldbtn:SetCheck(1)
	else
		g_uicommoninfo.xldbtn:SetCheck(0)
	end

	if switch[5] ~= nil and switch[5] > 0 then
		g_uicommoninfo.lvlimit:SetCheck(1)
	else
		g_uicommoninfo.lvlimit:SetCheck(0)
	end

	if switch[7] ~= nil and switch[7] > 0 then
		g_uicommoninfo.autoapply:SetCheck(1)
	else
		g_uicommoninfo.autoapply:SetCheck(0)
	end

	-- 22-24继续战斗
	if switch[8] ~= nil and switch[8] > 0 then
		g_uicommoninfo.pausegodali:SetCheck(1)
	else
		g_uicommoninfo.pausegodali:SetCheck(0)
	end

	-- 自动出窍
	if switch[9] ~= nil and switch[9] > 0 then
		g_uicommoninfo.autoghost:SetCheck(1)
	else
		g_uicommoninfo.autoghost:SetCheck(0)
	end
end

-- 新增关于经验等级的开关
function AutoAttackSkill_ExpBtn_OnClick(expType)
	if expType == nil then
		return
	end
	if g_configdata.useSwitch[expType] == nil then
		return
	end
	if g_configdata.useSwitch[expType] > 0 then
		g_configdata.useSwitch[expType] = 0
	else
		g_configdata.useSwitch[expType] = 1
	end

	-- 配置存储
	BattleAssist:Farm_UpdateConfig(makecfgstr())
	BattleAssist:Farm_SetConfigData( g_configdata )

	AutoAttackSkill_ExpBtn_Update()
end


function AutoAttackSkill_OnAutoSearchNpc()
	local bRet = AutoRuntoTargetExWithName(181, 139, 2, "洪大贵") 
	if bRet == 1 then
		BattleAssist:Farm_SetAutoSearchNpc(1)
	else
		BattleAssist:Farm_SetAutoSearchNpc(0)
	end
end

function AutoAttackSkill_OnSaveConfirm(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		AutoAttackSkill_OnSave(1)
	end

	if "No" == strRet then
		local n1, n2, n3 = BattleAssist:Farm_GetCfgData_MaxNum()
		if n3 ~= nil and g_StopCondition_NumberInput_Box[3] ~= nil then
			if n3 <= 0 then
				g_StopCondition_NumberInput_Box[3]:SetText("") --空值表示不做数量判断
			else
				g_StopCondition_NumberInput_Box[3]:SetText(tostring(n3))
			end
		end
		AutoAttackSkill_OnSave(1)
	end
end

function AutoAttackSkill_OnSelectOptionType(optionType)
	if g_data.option ~= g_optionpagedef.recoverinfo then
		return
	end

	if optionType == g_data.optiontype then
		return
	end

	g_data.optiontype = optionType
	AutoAttackSkill_UpdateOptionUI()
end

function AutoAttackSkill_OnTeamAutoApply()
	Player:SendAgreeJoinTeam_Apply(0)
	DataPool:EraseApply(0)
end


function AutoAttackSkill_ShowPage()

	for i = 1, table.getn(g_AutoAttackSkill_PageButton) do
		g_AutoAttackSkill_PageButton[i]:Hide()
	end
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	AutoAttackSkill_ClearPage()
	
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_AutoAttackSkill_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_AutoAttackSkill_PageButton) do
			if i ~= nPageNumber then
				g_AutoAttackSkill_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_AutoAttackSkill_PageOrder = {}
	local g_AutoAttackSkill_PageCount = 0
	
	for i = 1, table.getn(g_AutoAttackSkill_PageButton) do
		if AutoAttackSkill_CheckPage(i) == 1 then
			g_AutoAttackSkill_PageCount = g_AutoAttackSkill_PageCount + 1
			g_AutoAttackSkill_PageButton[g_AutoAttackSkill_PageCount]:Show()
			g_AutoAttackSkill_PageButton[g_AutoAttackSkill_PageCount]:SetText(g_AutoAttackSkill_Page[i].Text)	
			g_AutoAttackSkill_PageOrder[g_AutoAttackSkill_PageCount] = i
		end
	end
	
	for idx = 1, table.getn(g_AutoAttackSkill_PageOrder) do
		if g_AutoAttackSkill_PageOrder[idx] == 6 and g_PageTipsPos[idx] then -- 其他
			local newpos = g_PageTipsPos[idx]
			AutoAttackSkill_ZongMenSkill_Tips:SetProperty("UnifiedXPosition", newpos);
		end
	end
end

function AutoAttackSkill_OnPageClicked(idx)

	Variable:SetVariable("SkillPageNumber", tostring(idx), 1);
	idx = g_AutoAttackSkill_PageOrder[idx]
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	
	if idx == 1 then--普通
		AutoAttackSkill_Page_Switch(1)
	elseif idx == 2 then--门派
		AutoAttackSkill_Page_Switch(2)
	elseif idx == 3 then--阵法
		AutoAttackSkill_Page_Switch(3)
	elseif idx == 4 then--生活
		AutoAttackSkill_Page_Switch(4)
	elseif idx == 5 then--战斗
		AutoAttackSkill_ClearPage()
	elseif idx == 6 then --绝学
		AutoAttackSkill_Page_Switch(5)
	end
end

function AutoAttackSkill_CheckPage(idx)
	if idx == 1 then--普通
		return 1
	elseif idx == 2 then--门派
		return 1
	elseif idx == 3 then--阵法
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 4 then--生活
		return 1
	elseif idx == 5 then--战斗
		return 1
	elseif idx == 6 then--绝学
		return 1
	end
	return 0
end

function AutoAttackSkill_ClearPage()
	Variable:SetVariable("SkillPageNumber", tostring(0), 1)
end

