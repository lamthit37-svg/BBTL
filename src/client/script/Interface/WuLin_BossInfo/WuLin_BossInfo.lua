-- 武林之巅 boss挑战倒计时

-- 保存UI默认位置
local WuLin_BossInfo_UnifiedPosition = nil

local WuLin_BossInfo_BtnFenYe = nil

-- NPC
local WuLin_BossInfo_BossInfo =
{
	-- 明教
	[1] =
	{
		name = "#{PTFB_191228_86}", 
		image = "set:GuanShanHai18 image:MJ",
		skilltitle1 = "#{PTFB_191228_386}",
		skillcontent1 = "#{PTFB_191228_387}",
		skilltitle2 = "#{PTFB_191228_388}",
		skillcontent2 = "#{PTFB_191228_389}",
		skilltitle3 = "#{PTFB_191228_390}",
		skillcontent3 = "#{PTFB_191228_391}",
		advice = "#{PTFB_191228_414}",
	},
	-- 丐帮
	[2] =
	{
		name = "#{PTFB_191228_87}",
		image = "set:GuanShanHai17 image:GB",
		skilltitle1 = "#{PTFB_191228_374}",
		skillcontent1 = "#{PTFB_191228_375}",
		skilltitle2 = "#{PTFB_191228_376}",
		skillcontent2 = "#{PTFB_191228_377}",
		skilltitle3 = "#{PTFB_191228_378}",
		skillcontent3 = "#{PTFB_191228_379}",
		advice = "#{PTFB_191228_412}",
	},
	-- 唐门
	[3] =
	{
		name = "#{PTFB_191228_79}",
		image = "set:GuanShanHai21 image:TM",
		skilltitle1 = "#{PTFB_191228_331}",
		skillcontent1 = "#{PTFB_191228_332}",
		skilltitle2 = "#{PTFB_191228_333}",
		skillcontent2 = "#{PTFB_191228_334}",
		skilltitle3 = "#{PTFB_191228_335}",
		skillcontent3 = "#{PTFB_191228_336}",
		advice = "#{PTFB_191228_404}",
	},
	-- 峨嵋
	[4] =
	{
		name = "#{PTFB_191228_80}",
		image = "set:GuanShanHai17 image:EM",
		skilltitle1 = "#{PTFB_191228_337}",
		skillcontent1 = "#{PTFB_191228_338}",
		skilltitle2 = "#{PTFB_191228_339}",
		skillcontent2 = "#{PTFB_191228_340}",
		skilltitle3 = "#{PTFB_191228_341}",
		skillcontent3 = "#{PTFB_191228_342}",
		advice = "#{PTFB_191228_405}",
	},
	-- 星宿
	[5] =
	{
		name = "#{PTFB_191228_90}",
		image = "set:GuanShanHai20 image:XX",
		skilltitle1 = "#{PTFB_191228_380}",
		skillcontent1 = "#{PTFB_191228_381}",
		skilltitle2 = "#{PTFB_191228_382}",
		skillcontent2 = "#{PTFB_191228_383}",
		skilltitle3 = "#{PTFB_191228_384}",
		skillcontent3 = "#{PTFB_191228_385}",
		advice = "#{PTFB_191228_413}",
	},
	-- 武当
	[6] =
	{
		name = "#{PTFB_191228_88}",
		image = "set:GuanShanHai20 image:WD",
		skilltitle1 = "#{PTFB_191228_348}",
		skillcontent1 = "#{PTFB_191228_349}",
		skilltitle2 = "#{PTFB_191228_350}",
		skillcontent2 = "#{PTFB_191228_351}",
		skilltitle3 = "#{PTFB_191228_352}",
		skillcontent3 = "#{PTFB_191228_353}",
		advice = "#{PTFB_191228_407}",
	},
	-- 桃花岛
	[7] =
	{
		name = "#{PTFB_191228_81}",
		image = "set:GuanShanHai22 image:THD",
		skilltitle1 = "#{PTFB_191228_343}",
		skillcontent1 = "#{PTFB_191228_344}",
		skilltitle2 = "#{PTFB_191228_429}",
		skillcontent2 = "#{PTFB_191228_345}",
		skilltitle3 = "#{PTFB_191228_346}",
		skillcontent3 = "#{PTFB_191228_347}",
		advice = "#{PTFB_191228_406}",
	},
	-- 天龙
	[8] =
	{
		name = "#{PTFB_191228_89}",
		image = "set:GuanShanHai22 image:TL",
		skilltitle1 = "#{PTFB_191228_364}",
		skillcontent1 = "#{PTFB_191228_365}",
		skilltitle2 = "#{PTFB_191228_366}",
		skillcontent2 = "#{PTFB_191228_367}",
		skilltitle3 = "#{PTFB_191228_368}",
		skillcontent3 = "#{PTFB_191228_369}",
		advice = "#{PTFB_191228_410}",
	},
	-- 天山
	[9] =
	{
		name = "#{PTFB_191228_78}",
		image = "set:GuanShanHai21 image:TS",
		skilltitle1 = "#{PTFB_191228_358}",
		skillcontent1 = "#{PTFB_191228_359}",
		skilltitle2 = "#{PTFB_191228_360}",
		skillcontent2 = "#{PTFB_191228_361}",
		skilltitle3 = "#{PTFB_191228_362}",
		skillcontent3 = "#{PTFB_191228_363}",
		advice = "#{PTFB_191228_409}",
	},
	-- 逍遥
	[10] =
	{
		name = "#{PTFB_191228_83}",
		image = "set:GuanShanHai23 image:XY",
		skilltitle1 = "#{PTFB_191228_453}",
		skillcontent1 = "#{PTFB_191228_454}",
		skilltitle2 = "#{PTFB_191228_370}",
		skillcontent2 = "#{PTFB_191228_371}",
		skilltitle3 = "#{PTFB_191228_372}",
		skillcontent3 = "#{PTFB_191228_373}",
		advice = "#{PTFB_191228_411}",
	},
	-- 慕容
	[11] =
	{
		name = "#{PTFB_191228_84}",
		image = "set:GuanShanHai19 image:MR",
		skilltitle1 = "#{PTFB_191228_354}",
		skillcontent1 = "#{PTFB_191228_355}",
		skilltitle2 = "#{PTFB_191228_356}",
		skillcontent2 = "#{PTFB_191228_357}",
		skilltitle3 = nil,
		skillcontent3 = nil,
		advice = "#{PTFB_191228_408}",
	},
	-- 少林
	[12] =
	{
		name = "#{PTFB_191228_85}",
		image = "set:GuanShanHai19 image:SL",
		skilltitle1 = "#{PTFB_191228_392}",
		skillcontent1 = "#{PTFB_191228_393}",
		skilltitle2 = "#{PTFB_191228_394}",
		skillcontent2 = "#{PTFB_191228_395}",
		skilltitle3 = "#{PTFB_191228_396}",
		skillcontent3 = "#{PTFB_191228_397}",
		advice = "#{PTFB_191228_415}",
	},
	-- 鬼谷
	[13] =
	{
		name = "#{PTFB_191228_82}",
		image = "set:GuanShanHai18 image:GG",
		skilltitle1 = "#{PTFB_191228_398}",
		skillcontent1 = "#{PTFB_191228_399}",
		skilltitle2 = "#{PTFB_191228_400}",
		skillcontent2 = "#{PTFB_191228_401}",
		skilltitle3 = "#{PTFB_191228_402}",
		skillcontent3 = "#{PTFB_191228_403}",
		advice = "#{PTFB_191228_416}",
	},
} -- end WuLin_BossInfo_BossInfo


function WuLin_BossInfo_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("WLZD_OPEN_BOSSINFO", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_BossInfo_PreLoad()

function WuLin_BossInfo_OnLoad()
	WuLin_BossInfo_UnifiedPosition = WuLin_BossInfo_Frame:GetProperty("UnifiedPosition")

	WuLin_BossInfo_BtnFenYe = {}
	WuLin_BossInfo_BtnFenYe[1] = WuLin_BossInfo_LittleFenYe1
	WuLin_BossInfo_BtnFenYe[2] = WuLin_BossInfo_LittleFenYe2
	WuLin_BossInfo_BtnFenYe[3] = WuLin_BossInfo_LittleFenYe3
	WuLin_BossInfo_BtnFenYe[4] = WuLin_BossInfo_LittleFenYe4
	WuLin_BossInfo_BtnFenYe[5] = WuLin_BossInfo_LittleFenYe5
	WuLin_BossInfo_BtnFenYe[6] = WuLin_BossInfo_LittleFenYe6
	WuLin_BossInfo_BtnFenYe[7] = WuLin_BossInfo_LittleFenYe7
	WuLin_BossInfo_BtnFenYe[8] = WuLin_BossInfo_LittleFenYe8
	WuLin_BossInfo_BtnFenYe[9] = WuLin_BossInfo_LittleFenYe9
	WuLin_BossInfo_BtnFenYe[10] = WuLin_BossInfo_LittleFenYe10
	WuLin_BossInfo_BtnFenYe[11] = WuLin_BossInfo_LittleFenYe11
	WuLin_BossInfo_BtnFenYe[12] = WuLin_BossInfo_LittleFenYe12
	WuLin_BossInfo_BtnFenYe[13] = WuLin_BossInfo_LittleFenYe13
end -- end func WuLin_BossInfo_OnLoad()

function WuLin_BossInfo_OnEvent(event)
	if (event == "WLZD_OPEN_BOSSINFO") then
		WuLin_BossInfo_Show(arg0)
	elseif (event == "WLZD_CLOSE_ALL") then
		WuLin_BossInfo_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (WuLinZhiDian:IsWuLinZhiDianScene() < 0) then
			WuLin_BossInfo_Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_BossInfo_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_BossInfo_UnifiedPos()
	end
end -- end func WuLin_BossInfo_OnEvent()

-- 界面默认位置
function WuLin_BossInfo_UnifiedPos()
	if (WuLin_BossInfo_UnifiedPosition ~= nil) then
		WuLin_BossInfo_Frame:SetProperty("UnifiedPosition", WuLin_BossInfo_UnifiedPosition)
	end
end -- end func WuLin_BossInfo_UnifiedPos()

-- 开启UI
function WuLin_BossInfo_Show(menpaiIndex)
	if (this:IsVisible()) then
		this:Hide()
	end

	WuLin_BossInfo_UpdateInfo(tonumber(menpaiIndex))
	this:Show()
end -- end func WuLin_BossInfo_Show()

-- 关闭UI
function WuLin_BossInfo_Hide()
	this:Hide()
end -- end func WuLin_BossInfo_Hide()

-- 关闭事件
function WuLin_BossInfo_Close()
	WuLin_BossInfo_Hide()
end -- end func WuLin_BossInfo_Close()

-- 分页按钮事件
function WuLin_BossInfo_FenYeClick(index)
	WuLin_BossInfo_UpdateInfo(index)
end -- end func WuLin_BossInfo_FenYeClick()

-- 更新页面内容
function WuLin_BossInfo_UpdateInfo(index)
	local bossIndex = index
	if (index < 1 or index > 13) then
		bossIndex = WuLinZhiDian:GetCurBossIndex()
	end

	if (WuLin_BossInfo_BtnFenYe ~= nil) then
		if (WuLin_BossInfo_BtnFenYe[bossIndex] ~= nil) then
			WuLin_BossInfo_BtnFenYe[bossIndex]:SetCheck(1)
		end
	end

	local bossSkillInfo = WuLin_BossInfo_BossInfo[bossIndex]
	if (bossSkillInfo == nil) then
		return
	end

	if (WuLin_BossInfo_SchoolShow ~= nil) then
		if (bossSkillInfo.image == nil) then
			WuLin_BossInfo_SchoolShow:SetProperty("Image", "")
		else
			WuLin_BossInfo_SchoolShow:SetProperty("Image", bossSkillInfo.image)
		end
	end

	if (WuLin_BossInfo_Skill1Title ~= nil) then
		if (bossSkillInfo.skilltitle1 == nil) then
			WuLin_BossInfo_Skill1Title:SetText("")
		else
			WuLin_BossInfo_Skill1Title:SetText(bossSkillInfo.skilltitle1)
		end
	end
	if (WuLin_BossInfo_Skill1 ~= nil) then
		if (bossSkillInfo.skillcontent1 == nil) then
			WuLin_BossInfo_Skill1:SetText("")
		else
			WuLin_BossInfo_Skill1:SetText(bossSkillInfo.skillcontent1)
		end
	end

	if (WuLin_BossInfo_Skill12Title ~= nil) then
		if (bossSkillInfo.skilltitle2 == nil) then
			WuLin_BossInfo_Skill12Title:SetText("")
		else
			WuLin_BossInfo_Skill12Title:SetText(bossSkillInfo.skilltitle2)
		end
	end
	if (WuLin_BossInfo_Skill2 ~= nil) then
		if (bossSkillInfo.skillcontent2 == nil) then
			WuLin_BossInfo_Skill2:SetText("")
		else
			WuLin_BossInfo_Skill2:SetText(bossSkillInfo.skillcontent2)
		end
	end

	if (WuLin_BossInfo_Skill13Title ~= nil) then
		if (bossSkillInfo.skilltitle3 == nil) then
			WuLin_BossInfo_Skill13Title:SetText("")
		else
			WuLin_BossInfo_Skill13Title:SetText(bossSkillInfo.skilltitle3)
		end
	end
	if (WuLin_BossInfo_Skill3 ~= nil) then
		if (bossSkillInfo.skillcontent3 == nil) then
			WuLin_BossInfo_Skill3:SetText("")
		else
			WuLin_BossInfo_Skill3:SetText(bossSkillInfo.skillcontent3)
		end
	end

	if (WuLin_BossInfo_Method ~= nil) then
		if (bossSkillInfo.advice == nil) then
			WuLin_BossInfo_Method:SetText("")
		else
			WuLin_BossInfo_Method:SetText(bossSkillInfo.advice)
		end
	end
end -- end func WuLin_BossInfo_UpdateInfo()