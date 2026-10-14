-- 武林之巅 boss挑战倒计时

-- 保存UI默认位置
local WuLin_BossInfo_New_UnifiedPosition = nil

local WuLin_BossInfo_New_BtnFenYe = nil

-- NPC
local WuLin_BossInfo_New_BossInfo =
{
	-- 明教
	[1] =
	{
		name = "#{PTFB_191228_86}", 
		image = "set:GuanShanHai18 image:MJ",
		skilltitle1 = "#{JZGSH_210222_224}",
		skillcontent1 = "#{JZGSH_210222_225}",
		skilltitle2 = "#{JZGSH_210222_226}",
		skillcontent2 = "#{JZGSH_210222_227}",
		skilltitle3 = "#{JZGSH_210222_228}",
		skillcontent3 = "#{JZGSH_210222_229}",
		advice = "#{JZGSH_210222_252}",
	},
	-- 丐帮
	[2] =
	{
		name = "#{PTFB_191228_87}",
		image = "set:GuanShanHai17 image:GB",
		skilltitle1 = "#{JZGSH_210222_212}",
		skillcontent1 = "#{JZGSH_210222_213}",
		skilltitle2 = "#{JZGSH_210222_214}",
		skillcontent2 = "#{JZGSH_210222_215}",
		skilltitle3 = "#{JZGSH_210222_216}",
		skillcontent3 = "#{JZGSH_210222_217}",
		advice = "#{JZGSH_210222_250}",
	},
	-- 唐门
	[3] =
	{
		name = "#{PTFB_191228_79}",
		image = "set:GuanShanHai21 image:TM",
		skilltitle1 = "#{JZGSH_210222_169}",
		skillcontent1 = "#{JZGSH_210222_170}",
		skilltitle2 = "#{JZGSH_210222_171}",
		skillcontent2 = "#{JZGSH_210222_172}",
		skilltitle3 = "#{JZGSH_210222_173}",
		skillcontent3 = "#{JZGSH_210222_174}",
		advice = "#{JZGSH_210222_242}",
	},
	-- 峨嵋
	[4] =
	{
		name = "#{PTFB_191228_80}",
		image = "set:GuanShanHai17 image:EM",
		skilltitle1 = "#{JZGSH_210222_175}",
		skillcontent1 = "#{JZGSH_210222_176}",
		skilltitle2 = "#{JZGSH_210222_177}",
		skillcontent2 = "#{JZGSH_210222_178}",
		skilltitle3 = "#{JZGSH_210222_179}",
		skillcontent3 = "#{JZGSH_210222_180}",
		advice = "#{JZGSH_210222_243}",
	},
	-- 星宿
	[5] =
	{
		name = "#{PTFB_191228_90}",
		image = "set:GuanShanHai20 image:XX",
		skilltitle1 = "#{JZGSH_210222_218}",
		skillcontent1 = "#{JZGSH_210222_219}",
		skilltitle2 = "#{JZGSH_210222_220}",
		skillcontent2 = "#{JZGSH_210222_221}",
		skilltitle3 = "#{JZGSH_210222_222}",
		skillcontent3 = "#{JZGSH_210222_223}",
		advice = "#{JZGSH_210222_251}",
	},
	-- 武当
	[6] =
	{
		name = "#{PTFB_191228_88}",
		image = "set:GuanShanHai20 image:WD",
		skilltitle1 = "#{JZGSH_210222_186}",
		skillcontent1 = "#{JZGSH_210222_187}",
		skilltitle2 = "#{JZGSH_210222_188}",
		skillcontent2 = "#{JZGSH_210222_189}",
		skilltitle3 = "#{JZGSH_210222_190}",
		skillcontent3 = "#{JZGSH_210222_191}",
		advice = "#{JZGSH_210222_245}",
	},
	-- 桃花岛
	[7] =
	{
		name = "#{PTFB_191228_81}",
		image = "set:GuanShanHai22 image:THD",
		skilltitle1 = "#{JZGSH_210222_181}",
		skillcontent1 = "#{JZGSH_210222_182}",
		skilltitle2 = "#{JZGSH_210222_255}",
		skillcontent2 = "#{JZGSH_210222_183}",
		skilltitle3 = "#{JZGSH_210222_184}",
		skillcontent3 = "#{JZGSH_210222_185}",
		advice = "#{JZGSH_210222_244}",
	},
	-- 天龙
	[8] =
	{
		name = "#{PTFB_191228_89}",
		image = "set:GuanShanHai22 image:TL",
		skilltitle1 = "#{JZGSH_210222_202}",
		skillcontent1 = "#{JZGSH_210222_203}",
		skilltitle2 = "#{JZGSH_210222_204}",
		skillcontent2 = "#{JZGSH_210222_205}",
		skilltitle3 = "#{JZGSH_210222_206}",
		skillcontent3 = "#{JZGSH_210222_207}",
		advice = "#{JZGSH_210222_248}",
	},
	-- 天山
	[9] =
	{
		name = "#{PTFB_191228_78}",
		image = "set:GuanShanHai21 image:TS",
		skilltitle1 = "#{JZGSH_210222_196}",
		skillcontent1 = "#{JZGSH_210222_197}",
		skilltitle2 = "#{JZGSH_210222_198}",
		skillcontent2 = "#{JZGSH_210222_199}",
		skilltitle3 = "#{JZGSH_210222_200}",
		skillcontent3 = "#{JZGSH_210222_201}",
		advice = "#{JZGSH_210222_247}",
	},
	-- 逍遥
	[10] =
	{
		name = "#{PTFB_191228_83}",
		image = "set:GuanShanHai23 image:XY",
		skilltitle1 = "#{JZGSH_210222_256}",
		skillcontent1 = "#{JZGSH_210222_257}",
		skilltitle2 = "#{JZGSH_210222_208}",
		skillcontent2 = "#{JZGSH_210222_209}",
		skilltitle3 = "#{JZGSH_210222_210}",
		skillcontent3 = "#{JZGSH_210222_211}",
		advice = "#{JZGSH_210222_249}",
	},
	-- 慕容
	[11] =
	{
		name = "#{PTFB_191228_84}",
		image = "set:GuanShanHai19 image:MR",
		skilltitle1 = "#{JZGSH_210222_192}",
		skillcontent1 = "#{JZGSH_210222_193}",
		skilltitle2 = "#{JZGSH_210222_194}",
		skillcontent2 = "#{JZGSH_210222_195}",
		skilltitle3 = nil,
		skillcontent3 = nil,
		advice = "#{JZGSH_210222_246}",
	},
	-- 少林
	[12] =
	{
		name = "#{PTFB_191228_85}",
		image = "set:GuanShanHai19 image:SL",
		skilltitle1 = "#{JZGSH_210222_230}",
		skillcontent1 = "#{JZGSH_210222_231}",
		skilltitle2 = "#{JZGSH_210222_232}",
		skillcontent2 = "#{JZGSH_210222_233}",
		skilltitle3 = "#{JZGSH_210222_234}",
		skillcontent3 = "#{JZGSH_210222_235}",
		advice = "#{JZGSH_210222_253}",
	},
	-- 鬼谷
	[13] =
	{
		name = "#{PTFB_191228_82}",
		image = "set:GuanShanHai18 image:GG",
		skilltitle1 = "#{JZGSH_210222_236}",
		skillcontent1 = "#{JZGSH_210222_237}",
		skilltitle2 = "#{JZGSH_210222_238}",
		skillcontent2 = "#{JZGSH_210222_239}",
		skilltitle3 = "#{JZGSH_210222_240}",
		skillcontent3 = "#{JZGSH_210222_241}",
		advice = "#{JZGSH_210222_254}",
	},
} -- end WuLin_BossInfo_New_BossInfo


function WuLin_BossInfo_New_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("JZWLZD_OPEN_BOSSINFO", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_BossInfo_New_PreLoad()

function WuLin_BossInfo_New_OnLoad()
	WuLin_BossInfo_New_UnifiedPosition = WuLin_BossInfo_New_Frame:GetProperty("UnifiedPosition")

	WuLin_BossInfo_New_BtnFenYe = {}
	WuLin_BossInfo_New_BtnFenYe[1] = WuLin_BossInfo_New_LittleFenYe1
	WuLin_BossInfo_New_BtnFenYe[2] = WuLin_BossInfo_New_LittleFenYe2
	WuLin_BossInfo_New_BtnFenYe[3] = WuLin_BossInfo_New_LittleFenYe3
	WuLin_BossInfo_New_BtnFenYe[4] = WuLin_BossInfo_New_LittleFenYe4
	WuLin_BossInfo_New_BtnFenYe[5] = WuLin_BossInfo_New_LittleFenYe5
	WuLin_BossInfo_New_BtnFenYe[6] = WuLin_BossInfo_New_LittleFenYe6
	WuLin_BossInfo_New_BtnFenYe[7] = WuLin_BossInfo_New_LittleFenYe7
	WuLin_BossInfo_New_BtnFenYe[8] = WuLin_BossInfo_New_LittleFenYe8
	WuLin_BossInfo_New_BtnFenYe[9] = WuLin_BossInfo_New_LittleFenYe9
	WuLin_BossInfo_New_BtnFenYe[10] = WuLin_BossInfo_New_LittleFenYe10
	WuLin_BossInfo_New_BtnFenYe[11] = WuLin_BossInfo_New_LittleFenYe11
	WuLin_BossInfo_New_BtnFenYe[12] = WuLin_BossInfo_New_LittleFenYe12
	WuLin_BossInfo_New_BtnFenYe[13] = WuLin_BossInfo_New_LittleFenYe13
end -- end func WuLin_BossInfo_New_OnLoad()

function WuLin_BossInfo_New_OnEvent(event)
	if (event == "JZWLZD_OPEN_BOSSINFO") then
		WuLin_BossInfo_New_Show(arg0)
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (JueZhanWuLinZhiDian:IsJueZhanWuLinZhiDianScene() < 0) then
			WuLin_BossInfo_New_Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_BossInfo_New_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_BossInfo_New_UnifiedPos()
	end
end -- end func WuLin_BossInfo_New_OnEvent()

-- 界面默认位置
function WuLin_BossInfo_New_UnifiedPos()
	if (WuLin_BossInfo_New_UnifiedPosition ~= nil) then
		WuLin_BossInfo_New_Frame:SetProperty("UnifiedPosition", WuLin_BossInfo_New_UnifiedPosition)
	end
end -- end func WuLin_BossInfo_New_UnifiedPos()

-- 开启UI
function WuLin_BossInfo_New_Show(menpaiIndex)
	if (this:IsVisible()) then
		this:Hide()
	end

	local menpai = 1
	if (menpaiIndex ~= nil) then
		menpai = tonumber(menpaiIndex)
	end

	WuLin_BossInfo_New_UpdateInfo(menpai)
	this:Show()
end -- end func WuLin_BossInfo_New_Show()

-- 关闭UI
function WuLin_BossInfo_New_Hide()
	this:Hide()
end -- end func WuLin_BossInfo_New_Hide()

-- 关闭事件
function WuLin_BossInfo_New_Close()
	WuLin_BossInfo_New_Hide()
end -- end func WuLin_BossInfo_New_Close()

-- 分页按钮事件
function WuLin_BossInfo_New_FenYeClick(index)
	WuLin_BossInfo_New_UpdateInfo(index)
end -- end func WuLin_BossInfo_New_FenYeClick()

-- 更新页面内容
function WuLin_BossInfo_New_UpdateInfo(index)
	local bossIndex = index
	if (bossIndex < 1 or bossIndex > 13) then
		bossIndex = JueZhanWuLinZhiDian:GetCurBossIndex()
	end
	if (bossIndex < 1 or bossIndex > 13) then
		bossIndex = 1
	end

	if (WuLin_BossInfo_New_BtnFenYe ~= nil) then
		if (WuLin_BossInfo_New_BtnFenYe[bossIndex] ~= nil) then
			WuLin_BossInfo_New_BtnFenYe[bossIndex]:SetCheck(1)
		end
	end

	local bossSkillInfo = WuLin_BossInfo_New_BossInfo[bossIndex]
	if (bossSkillInfo == nil) then
		return
	end

	if (WuLin_BossInfo_New_SchoolShow ~= nil) then
		if (bossSkillInfo.image == nil) then
			WuLin_BossInfo_New_SchoolShow:SetProperty("Image", "")
		else
			WuLin_BossInfo_New_SchoolShow:SetProperty("Image", bossSkillInfo.image)
		end
	end

	if (WuLin_BossInfo_New_Skill1Title ~= nil) then
		if (bossSkillInfo.skilltitle1 == nil) then
			WuLin_BossInfo_New_Skill1Title:SetText("")
		else
			WuLin_BossInfo_New_Skill1Title:SetText(bossSkillInfo.skilltitle1)
		end
	end
	if (WuLin_BossInfo_New_Skill1 ~= nil) then
		if (bossSkillInfo.skillcontent1 == nil) then
			WuLin_BossInfo_New_Skill1:SetText("")
		else
			WuLin_BossInfo_New_Skill1:SetText(bossSkillInfo.skillcontent1)
		end
	end

	if (WuLin_BossInfo_New_Skill12Title ~= nil) then
		if (bossSkillInfo.skilltitle2 == nil) then
			WuLin_BossInfo_New_Skill12Title:SetText("")
		else
			WuLin_BossInfo_New_Skill12Title:SetText(bossSkillInfo.skilltitle2)
		end
	end
	if (WuLin_BossInfo_New_Skill2 ~= nil) then
		if (bossSkillInfo.skillcontent2 == nil) then
			WuLin_BossInfo_New_Skill2:SetText("")
		else
			WuLin_BossInfo_New_Skill2:SetText(bossSkillInfo.skillcontent2)
		end
	end

	if (WuLin_BossInfo_New_Skill13Title ~= nil) then
		if (bossSkillInfo.skilltitle3 == nil) then
			WuLin_BossInfo_New_Skill13Title:SetText("")
		else
			WuLin_BossInfo_New_Skill13Title:SetText(bossSkillInfo.skilltitle3)
		end
	end
	if (WuLin_BossInfo_New_Skill3 ~= nil) then
		if (bossSkillInfo.skillcontent3 == nil) then
			WuLin_BossInfo_New_Skill3:SetText("")
		else
			WuLin_BossInfo_New_Skill3:SetText(bossSkillInfo.skillcontent3)
		end
	end

	if (WuLin_BossInfo_New_Method ~= nil) then
		if (bossSkillInfo.advice == nil) then
			WuLin_BossInfo_New_Method:SetText("")
		else
			WuLin_BossInfo_New_Method:SetText(bossSkillInfo.advice)
		end
	end
end -- end func WuLin_BossInfo_New_UpdateInfo()