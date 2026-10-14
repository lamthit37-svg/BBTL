-- T300宋辽 战况界面
local SongliaoKuafu_Fight_Scene = "Songliao_War"
local SongliaoKuafu_Fight_ServerScriptId = 502011

local SongliaoKuafu_Fight_SongCamp = 156
local SongliaoKuafu_Fight_LiaoCamp = 157

local SongliaoKuafu_Fight_IsOpenMini = 0

-- 防御塔类型
local SongliaoKuafu_Fight_NPCType =
{
	-- 宋
	Song =
	{
		Being = 1,
		Boss = 1,			-- 主boss
		QingLong = 2,		-- 青龙
		BaiHu = 3,			-- 白虎
		ZhuQue = 4,			-- 朱雀
		XuanWu = 5,			-- 玄武
		Tower1 = 6,			-- 外层防御塔
		Tower2 = 7,			-- 外层防御塔
		Tower3 = 8,			-- 外层防御塔
		End = 8,
	},

	-- 辽
	Liao =
	{
		Being = 11,
		Boss = 11,			-- 主boss
		QingLong = 12,		-- 青龙
		BaiHu = 13,			-- 白虎
		ZhuQue = 14,		-- 朱雀
		XuanWu = 15,		-- 玄武
		Tower1 = 16,		-- 外层防御塔
		Tower2 = 17,		-- 外层防御塔
		Tower3 = 18,		-- 外层防御塔
		End = 18,
	},
} -- end SongliaoKuafu_Fight_NPCType

-- 保存UI默认位置
local SongliaoKuafu_Fight_UnifiedPosition = nil



function SongliaoKuafu_Fight_PreLoad()
    this:RegisterEvent("TSL_PLAYERENTERCOPY", true)
    this:RegisterEvent("TSL_BATTLEBEGIN", true)
    this:RegisterEvent("TSL_OPENFIGHT", true)
    this:RegisterEvent("TSL_CLOSEFIGHT", true)
    this:RegisterEvent("TSL_BATTLEDATA", true)
    this:RegisterEvent("TSL_TOWERDATA", true)
    this:RegisterEvent("TSL_BOSSDATA", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func SongliaoKuafu_Fight_PreLoad()

function SongliaoKuafu_Fight_OnLoad()
    SongliaoKuafu_Fight_UnifiedPosition = SongliaoKuafu_Fight_Frame:GetProperty("UnifiedPosition")
end -- end func SongliaoKuafu_Fight_OnLoad()

function SongliaoKuafu_Fight_OnEvent(event)
    if (event == "TSL_PLAYERENTERCOPY") then
        SongliaoKuafu_Fight_IsOpenMini = 0
        -- SongliaoKuafu_Fight_Show()
        -- SongliaoKuafu_Fight_UpdateBattleData()
        -- SongliaoKuafu_Fight_UpdateTowerData()
        -- SongliaoKuafu_Fight_UpdateBossData()
    elseif (event == "TSL_BATTLEBEGIN") then
        if (SongliaoKuafu_Fight_IsOpenMini <= 0) then
            SongliaoKuafu_Fight_Show()
        end

        SongliaoKuafu_Fight_UpdateBattleData()
        SongliaoKuafu_Fight_UpdateTowerData()
        SongliaoKuafu_Fight_UpdateBossData()
    elseif (event == "TSL_OPENFIGHT") then
        SongliaoKuafu_Fight_IsOpenMini = 0
        if (SongliaoKuafu_Fight_IsOpenMini <= 0) then
            SongliaoKuafu_Fight_Show()
        end

        SongliaoKuafu_Fight_UpdateBattleData()
        SongliaoKuafu_Fight_UpdateTowerData()
        SongliaoKuafu_Fight_UpdateBossData()
    elseif (event == "TSL_CLOSEFIGHT") then
        SongliaoKuafu_Fight_Hide()
    elseif (event == "TSL_BATTLEDATA") then
        if (SongliaoKuafu_Fight_IsOpenMini <= 0) then
            SongliaoKuafu_Fight_Show()
        end

        SongliaoKuafu_Fight_UpdateBattleData()
    elseif (event == "TSL_TOWERDATA") then
        if (SongliaoKuafu_Fight_IsOpenMini <= 0) then
            SongliaoKuafu_Fight_Show()
        end

        SongliaoKuafu_Fight_UpdateTowerData()
    elseif (event == "TSL_BOSSDATA") then
        if (SongliaoKuafu_Fight_IsOpenMini <= 0) then
            SongliaoKuafu_Fight_Show()
        end

        SongliaoKuafu_Fight_UpdateBossData()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        SongliaoKuafu_Fight_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        SongliaoKuafu_Fight_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        SongliaoKuafu_Fight_UnifiedPos()
    end
end -- end func SongliaoKuafu_Fight_OnEvent()

-- 界面默认位置
function SongliaoKuafu_Fight_UnifiedPos()
    if (this:IsVisible()) then
        if (SongliaoKuafu_Fight_UnifiedPosition ~= nil) then
            SongliaoKuafu_Fight_Frame:SetProperty("UnifiedPosition", SongliaoKuafu_Fight_UnifiedPosition)
        end
    end
end -- end func SongliaoKuafu_Fight_UnifiedPos()

function SongliaoKuafu_Fight_Show()
    if (not this:IsVisible()) then
        this:Show()

        -- 血量、积分先不显示 因为开始的时候可能没有数据 等数据刷过来以后再显示
        SongliaoKuafu_Fight_Info1_Text:Hide()
        SongliaoKuafu_Fight_Info2_Text:Hide()
        SongliaoKuafu_Fight_Info3_Text:Hide()
        SongliaoKuafu_Fight_Song_Info:Hide()
        SongliaoKuafu_Fight_Liao_Info:Hide()

        SongliaoKuafu_Fight_Song_Pic6Number:Hide()
        SongliaoKuafu_Fight_Liao_Pic6Number:Hide()

        SongliaoKuafu_Fight_Song_Pic6_HP:Hide()
        SongliaoKuafu_Fight_Liao_Pic6_HP:Hide()

        SongliaoKuafu_Fight_MyIconSong:Hide()
        SongliaoKuafu_Fight_MyIconLiao:Hide()

        SongliaoKuafu_Fight_Goal_Icon1:Hide()
        SongliaoKuafu_Fight_Goal_Text1:Hide()
    end
end -- end func SongliaoKuafu_Fight_Show()

function SongliaoKuafu_Fight_Hide()
    this:Hide()
end -- end func SongliaoKuafu_Fight_Hide()

-- 点开排行榜按钮
function SongliaoKuafu_Fight_OpenFame()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SyncRankList")
		Set_XSCRIPT_ScriptID(SongliaoKuafu_Fight_ServerScriptId)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func SongliaoKuafu_Fight_OpenFame()

-- 打开mini界面按钮
function SongliaoKuafu_Fight_SmallClicked()
    SongliaoKuafu_Fight_IsOpenMini = 1

    SongliaoKuafu_Fight_Hide()

    PushEvent("TSL_OPENMINI")
end -- end func SongliaoKuafu_Fight_SmallClicked()

-- 计算倒计时 返回XX:XX格式
function SongliaoKuafu_Fight_TimeLeftStr(timeLeft)
    if (timeLeft < 0) then
        return ""
    end

    -- 分
    local strMin = ""
    local min = timeLeft / 60
    if (min == 0) then
        strMin = "00"
    elseif (min < 10) then
        strMin = string.format("0%d", min)
    else
        strMin = string.format("%d", min)
    end

    -- 秒
    local strSec = ""
    local sec = math.mod(timeLeft, 60)
    if (sec == 0) then
        strSec = "00"
    elseif (sec < 10) then
        strSec = string.format("0%d", sec)
    else
        strSec = string.format("%d", sec)
    end

    local str = string.format("%s:%s", strMin, strSec)
    return str
end -- end func SongliaoKuafu_Fight_TimeLeftStr()

-- 获取防御塔数量
function SongliaoKuafu_Fight_GetTowerNum(camp)
    local typeBegin = -1
    local typeEnd = -1
    if (camp == SongliaoKuafu_Fight_SongCamp) then
        typeBegin = SongliaoKuafu_Fight_NPCType.Song.Tower1
        typeEnd = SongliaoKuafu_Fight_NPCType.Song.Tower3
    elseif (camp == SongliaoKuafu_Fight_LiaoCamp) then
        typeBegin = SongliaoKuafu_Fight_NPCType.Liao.Tower1
        typeEnd = SongliaoKuafu_Fight_NPCType.Liao.Tower3
    else
        return -1
    end

    local num = 0
    for i=typeBegin, typeEnd, 1 do
        local tower = CSongliaoWarData:TSLGetTowerData(camp, i)
        if (tower >= 0) then
            num = num + 1
        end
    end -- end for

    return num
end -- end func SongliaoKuafu_Fight_GetTowerNum()

-- 获取四象塔数量
function SongliaoKuafu_Fight_GetDefenceNum(camp)
    local typeBegin = -1
    local typeEnd = -1
    if (camp == SongliaoKuafu_Fight_SongCamp) then
        typeBegin = SongliaoKuafu_Fight_NPCType.Song.QingLong
        typeEnd = SongliaoKuafu_Fight_NPCType.Song.XuanWu
    elseif (camp == SongliaoKuafu_Fight_LiaoCamp) then
        typeBegin = SongliaoKuafu_Fight_NPCType.Liao.QingLong
        typeEnd = SongliaoKuafu_Fight_NPCType.Liao.XuanWu
    else
        return -1
    end

    local num = 0
    for i=typeBegin, typeEnd, 1 do
        local tower = CSongliaoWarData:TSLGetTowerData(camp, i)
        if (tower >= 0) then
            num = num + 1
        end
    end -- end for

    return num
end -- end func SongliaoKuafu_Fight_GetDefenceNum()

-- 获取四象塔血量
function SongliaoKuafu_Fight_GetDefenceHpPercent(camp)
    local typeBegin = -1
    local typeEnd = -1
    if (camp == SongliaoKuafu_Fight_SongCamp) then
        typeBegin = SongliaoKuafu_Fight_NPCType.Song.QingLong
        typeEnd = SongliaoKuafu_Fight_NPCType.Song.XuanWu
    elseif (camp == SongliaoKuafu_Fight_LiaoCamp) then
        typeBegin = SongliaoKuafu_Fight_NPCType.Liao.QingLong
        typeEnd = SongliaoKuafu_Fight_NPCType.Liao.XuanWu
    else
        return 0
    end

    local hptotal = 0
    local maxhptotal = 0
    for i=typeBegin, typeEnd, 1 do
        local towerHp, towerMaxHp = CSongliaoWarData:TSLGetTowerHp(camp, i)
        if (towerHp >= 0) then
            hptotal = hptotal + towerHp
        end
        if towerMaxHp >= 0 then
            maxhptotal = maxhptotal + towerMaxHp
        end
    end -- end for

    if maxhptotal <= 0 or hptotal <= 0 or hptotal > maxhptotal then
        return 0
    end

    local percent = math.ceil( (hptotal/maxhptotal)*100 )

    return percent
end -- end func SongliaoKuafu_Fight_GetDefenceHpPercent()

-- 获取防御塔血量
function SongliaoKuafu_Fight_GetTowerHpPercent(camp)
    local typeBegin = -1
    local typeEnd = -1
    if (camp == SongliaoKuafu_Fight_SongCamp) then
        typeBegin = SongliaoKuafu_Fight_NPCType.Song.Tower1
        typeEnd = SongliaoKuafu_Fight_NPCType.Song.Tower3
    elseif (camp == SongliaoKuafu_Fight_LiaoCamp) then
        typeBegin = SongliaoKuafu_Fight_NPCType.Liao.Tower1
        typeEnd = SongliaoKuafu_Fight_NPCType.Liao.Tower3
    else
        return 0
    end

    local hptotal = 0
    local maxhptotal = 0
    for i=typeBegin, typeEnd, 1 do
        local towerHp, towerMaxHp = CSongliaoWarData:TSLGetTowerHp(camp, i)
        if (towerHp >= 0) then
            hptotal = hptotal + towerHp
        end
        if towerMaxHp >= 0 then
            maxhptotal = maxhptotal + towerMaxHp
        end
    end -- end for

    if maxhptotal <= 0 or hptotal <= 0 or hptotal > maxhptotal then
        return 0
    end

    local percent = math.ceil((hptotal/maxhptotal)*100)
    return percent
end -- end func SongliaoKuafu_Fight_GetTowerHpPercent()

-- 刷新战斗数据
function SongliaoKuafu_Fight_UpdateBattleData()
    -- 刷新战斗数据
    -- 获取自己的阵营
    local myCamp = CSongliaoWarData:TSLGetMyCamp()
    -- 获取战斗数据（倒计时、积分、排名等）
    local timeLeft, myRank, myScore, songScore, liaoScore, winner = CSongliaoWarData:TSLGetBattleData()
    -- 倒计时
    if (timeLeft < 0) then
        timeLeft = 0
    end
    local timeLeftString = SongliaoKuafu_Fight_TimeLeftStr(timeLeft)
    local timeTips = ScriptGlobal_Format("#{SLDZ_220216_18}", timeLeftString)
    SongliaoKuafu_Fight_Info1_Text:SetText(timeTips)
    -- 自己的排名
    local rankTips = ScriptGlobal_Format("#{SLDZ_220216_19}", myRank+1)
    SongliaoKuafu_Fight_Info2_Text:SetText(rankTips)
    -- 自己的积分
    local scoreTips = ScriptGlobal_Format("#{SLDZ_220216_20}", myScore)
    SongliaoKuafu_Fight_Info3_Text:SetText(scoreTips)
    -- 宋阵营积分
    local songScoretips = ScriptGlobal_Format("#{SLDZ_220216_21}", songScore)
    SongliaoKuafu_Fight_Song_Info:SetText(songScoretips)
    -- 辽阵营积分
    local liaoScoreTips = ScriptGlobal_Format("#{SLDZ_220216_21}", liaoScore)
    SongliaoKuafu_Fight_Liao_Info:SetText(liaoScoreTips)

    SongliaoKuafu_Fight_Info1_Text:Show()
    SongliaoKuafu_Fight_Info2_Text:Show()
    SongliaoKuafu_Fight_Info3_Text:Show()
    SongliaoKuafu_Fight_Song_Info:Show()
    SongliaoKuafu_Fight_Liao_Info:Show()

    if (myCamp == SongliaoKuafu_Fight_SongCamp) then
        SongliaoKuafu_Fight_MyIconSong:Show()
        SongliaoKuafu_Fight_MyIconLiao:Hide()
    elseif (myCamp == SongliaoKuafu_Fight_LiaoCamp) then
        SongliaoKuafu_Fight_MyIconSong:Hide()
        SongliaoKuafu_Fight_MyIconLiao:Show()
    end

    -- 刷新一下目标提示
    SongliaoKuafu_Fight_UpdateTargetTips(myCamp)
end -- end func SongliaoKuafu_Fight_UpdateBattleData()

-- 刷新防御塔数据
function SongliaoKuafu_Fight_UpdateTowerData()
    -- 宋 防御塔数据
    local songTowerNum = 0
    local songTower1 = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_SongCamp, SongliaoKuafu_Fight_NPCType.Song.Tower1)
    local songTower2 = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_SongCamp, SongliaoKuafu_Fight_NPCType.Song.Tower2)
    local songTower3 = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_SongCamp, SongliaoKuafu_Fight_NPCType.Song.Tower3)
    local songDefenceNum = 0
    -- 宋 青龙
    local songQingLong = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_SongCamp, SongliaoKuafu_Fight_NPCType.Song.QingLong)
    -- 宋 白虎
    local songBaiHu = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_SongCamp, SongliaoKuafu_Fight_NPCType.Song.BaiHu)
    -- 宋 朱雀
    local songZhuQue = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_SongCamp, SongliaoKuafu_Fight_NPCType.Song.ZhuQue)
    -- 宋 玄武
    local songXuanWu = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_SongCamp, SongliaoKuafu_Fight_NPCType.Song.XuanWu)
    -- 宋 阵营积分
    --local songScore = CSongliaoWarData:TSLGetCampScore(SongliaoKuafu_Fight_SongCamp)
    -- 宋 四象塔血量百分比
    local songDefenceHpPercent = SongliaoKuafu_Fight_GetDefenceHpPercent(SongliaoKuafu_Fight_SongCamp)
    -- 宋 防御塔血量百分比
    local songTowerHpPercent = SongliaoKuafu_Fight_GetTowerHpPercent(SongliaoKuafu_Fight_SongCamp)
    -- 刷新UI
    -- 宋 外层防御塔数量
    if (songTower1 >= 0) then
        --SongliaoKuafu_Fight_Song_Tower1:Show()
        SongliaoKuafu_Fight_Song_Tower1:SetProperty("Image", "set:SongliaoKuafu image:Song_Normal")
        songTowerNum = songTowerNum + 1
        SongliaoKuafu_Fight_Song_Tower1:SetToolTip("#{SLDZ_220216_147}")
    else
        --SongliaoKuafu_Fight_Song_Tower1:Hide()
        SongliaoKuafu_Fight_Song_Tower1:SetProperty("Image", "set:SongliaoKuafu image:Song_Disabled")
        SongliaoKuafu_Fight_Song_Tower1:SetToolTip("#{SLDZ_220216_155}")
    end
    if (songTower2 >= 0) then
        --SongliaoKuafu_Fight_Song_Tower2:Show()
        SongliaoKuafu_Fight_Song_Tower2:SetProperty("Image", "set:SongliaoKuafu image:Song_Normal")
        songTowerNum = songTowerNum + 1
        SongliaoKuafu_Fight_Song_Tower2:SetToolTip("#{SLDZ_220216_146}")
    else
        --SongliaoKuafu_Fight_Song_Tower2:Hide()
        SongliaoKuafu_Fight_Song_Tower2:SetProperty("Image", "set:SongliaoKuafu image:Song_Disabled")
        SongliaoKuafu_Fight_Song_Tower2:SetToolTip("#{SLDZ_220216_154}")
    end
    if (songTower3 >= 0) then
        --SongliaoKuafu_Fight_Song_Tower3:Show()
        SongliaoKuafu_Fight_Song_Tower3:SetProperty("Image", "set:SongliaoKuafu image:Song_Normal")
        songTowerNum = songTowerNum + 1
        SongliaoKuafu_Fight_Song_Tower3:SetToolTip("#{SLDZ_220216_148}")
    else
        --SongliaoKuafu_Fight_Song_Tower3:Hide()
        SongliaoKuafu_Fight_Song_Tower3:SetProperty("Image", "set:SongliaoKuafu image:Song_Disabled")
        SongliaoKuafu_Fight_Song_Tower3:SetToolTip("#{SLDZ_220216_156}")
    end
    -- 宋 青龙
    if (songQingLong >= 0) then
        if (songTowerNum > 0) then
            SongliaoKuafu_Fight_Song_Pic2:SetProperty("Image", "set:SongliaoKuafu image:QingLong_Anfight")
            SongliaoKuafu_Fight_Song_Pic2:SetToolTip("#{SLDZ_220216_123}")
        else
            SongliaoKuafu_Fight_Song_Pic2:SetProperty("Image", "set:SongliaoKuafu image:QingLong_Normal")
            SongliaoKuafu_Fight_Song_Pic2:SetToolTip("#{SLDZ_220216_124}")
        end

        songDefenceNum = songDefenceNum + 1
    else
        SongliaoKuafu_Fight_Song_Pic2:SetProperty("Image", "set:SongliaoKuafu image:QingLong_Disabled")
        SongliaoKuafu_Fight_Song_Pic2:SetToolTip("#{SLDZ_220216_125}")
    end
    -- 宋 白虎
    if (songBaiHu >= 0) then
        if (songTowerNum > 0) then
            SongliaoKuafu_Fight_Song_Pic3:SetProperty("Image", "set:SongliaoKuafu image:BaiHu_Anfight")
            SongliaoKuafu_Fight_Song_Pic3:SetToolTip("#{SLDZ_220216_135}")
        else
            SongliaoKuafu_Fight_Song_Pic3:SetProperty("Image", "set:SongliaoKuafu image:BaiHu_Normal")
            SongliaoKuafu_Fight_Song_Pic3:SetToolTip("#{SLDZ_220216_143}")
        end

        songDefenceNum = songDefenceNum + 1
    else
        SongliaoKuafu_Fight_Song_Pic3:SetProperty("Image", "set:SongliaoKuafu image:BaiHu_Disabled")
        SongliaoKuafu_Fight_Song_Pic3:SetToolTip("#{SLDZ_220216_151}")
    end
    -- 宋 朱雀
    if (songZhuQue >= 0) then
        if (songTowerNum > 0) then
            SongliaoKuafu_Fight_Song_Pic4:SetProperty("Image", "set:SongliaoKuafu image:ZhuQue_Anfight")
            SongliaoKuafu_Fight_Song_Pic4:SetToolTip("#{SLDZ_220216_136}")
        else
            SongliaoKuafu_Fight_Song_Pic4:SetProperty("Image", "set:SongliaoKuafu image:ZhuQue_Normal")
            SongliaoKuafu_Fight_Song_Pic4:SetToolTip("#{SLDZ_220216_144}")
        end

        songDefenceNum = songDefenceNum + 1
    else
        SongliaoKuafu_Fight_Song_Pic4:SetProperty("Image", "set:SongliaoKuafu image:ZhuQue_Disabled")
        SongliaoKuafu_Fight_Song_Pic4:SetToolTip("#{SLDZ_220216_152}")
    end
    -- 宋 玄武
    if (songXuanWu >= 0) then
        if (songTowerNum > 0) then
            SongliaoKuafu_Fight_Song_Pic5:SetProperty("Image", "set:SongliaoKuafu image:XuanWu_Anfight")
            SongliaoKuafu_Fight_Song_Pic5:SetToolTip("#{SLDZ_220216_137}")
        else
            SongliaoKuafu_Fight_Song_Pic5:SetProperty("Image", "set:SongliaoKuafu image:XuanWu_Normal")
            SongliaoKuafu_Fight_Song_Pic5:SetToolTip("#{SLDZ_220216_145}")
        end

        songDefenceNum = songDefenceNum + 1
    else
        SongliaoKuafu_Fight_Song_Pic5:SetProperty("Image", "set:SongliaoKuafu image:XuanWu_Disabled")
        SongliaoKuafu_Fight_Song_Pic5:SetToolTip("#{SLDZ_220216_153}")
    end
    -- 宋 boss
    if (songDefenceNum > 0) then
        SongliaoKuafu_Fight_Song_Pic6:SetToolTip("#{SLDZ_220216_141}")
    else
        SongliaoKuafu_Fight_Song_Pic6:SetToolTip("#{SLDZ_220216_149}")
    end
    -- 宋 四象塔血量百分比
    local songDefenceHpTips = ScriptGlobal_Format("#{SLDZ_220216_175}", songDefenceHpPercent)
    SongliaoKuafu_Fight_Song_MiniTitle:SetText(songDefenceHpTips)
    -- 宋 防御塔血量百分比
    local songTowerHpTips = ScriptGlobal_Format("#{SLDZ_220216_176}", songTowerHpPercent)
    SongliaoKuafu_Fight_Song_MiniTitle2:SetText(songTowerHpTips)

    -- 辽 防御塔数据
    local liaoTowerNum = 0
    local liaoTower1 = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_LiaoCamp, SongliaoKuafu_Fight_NPCType.Liao.Tower1)
    local liaoTower2 = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_LiaoCamp, SongliaoKuafu_Fight_NPCType.Liao.Tower2)
    local liaoTower3 = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_LiaoCamp, SongliaoKuafu_Fight_NPCType.Liao.Tower3)
    local liaoDefenceNum = 0
    -- 辽 青龙
    local liaoQingLong = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_LiaoCamp, SongliaoKuafu_Fight_NPCType.Liao.QingLong)
    -- 辽 白虎
    local liaoBaiHu = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_LiaoCamp, SongliaoKuafu_Fight_NPCType.Liao.BaiHu)
    -- 辽 朱雀
    local liaoZhuQue = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_LiaoCamp, SongliaoKuafu_Fight_NPCType.Liao.ZhuQue)
    -- 辽 玄武
    local liaoXuanWu = CSongliaoWarData:TSLGetTowerData(SongliaoKuafu_Fight_LiaoCamp, SongliaoKuafu_Fight_NPCType.Liao.XuanWu)
    -- 辽 阵营积分
    --local liaoScore = CSongliaoWarData:TSLGetCampScore(SongliaoKuafu_Fight_LiaoCamp)
    -- 辽 四象塔血量百分比
    local liaoDefenceHpPercent = SongliaoKuafu_Fight_GetDefenceHpPercent(SongliaoKuafu_Fight_LiaoCamp)
    -- 辽 防御塔血量百分比
    local liaoTowerHpPercent = SongliaoKuafu_Fight_GetTowerHpPercent(SongliaoKuafu_Fight_LiaoCamp)
    -- 辽 外层防御塔数量
    if (liaoTower1 >= 0) then
        --SongliaoKuafu_Fight_Liao_Tower1:Show()
        SongliaoKuafu_Fight_Liao_Tower1:SetProperty("Image", "set:SongliaoKuafu image:Liao_Normal")
        liaoTowerNum = liaoTowerNum + 1
        SongliaoKuafu_Fight_Liao_Tower1:SetToolTip("#{SLDZ_220216_147}")
    else
        --SongliaoKuafu_Fight_Liao_Tower1:Hide()
        SongliaoKuafu_Fight_Liao_Tower1:SetProperty("Image", "set:SongliaoKuafu image:Liao_Disabled")
        SongliaoKuafu_Fight_Liao_Tower1:SetToolTip("#{SLDZ_220216_155}")
    end
    if (liaoTower2 >= 0) then
        --SongliaoKuafu_Fight_Liao_Tower2:Show()
        SongliaoKuafu_Fight_Liao_Tower2:SetProperty("Image", "set:SongliaoKuafu image:Liao_Normal")
        liaoTowerNum = liaoTowerNum + 1
        SongliaoKuafu_Fight_Liao_Tower2:SetToolTip("#{SLDZ_220216_146}")
    else
        --SongliaoKuafu_Fight_Liao_Tower2:Hide()
        SongliaoKuafu_Fight_Liao_Tower2:SetProperty("Image", "set:SongliaoKuafu image:Liao_Disabled")
        SongliaoKuafu_Fight_Liao_Tower2:SetToolTip("#{SLDZ_220216_154}")
    end
    if (liaoTower3 >= 0) then
        --SongliaoKuafu_Fight_Liao_Tower3:Show()
        SongliaoKuafu_Fight_Liao_Tower3:SetProperty("Image", "set:SongliaoKuafu image:Liao_Normal")
        liaoTowerNum = liaoTowerNum + 1
        SongliaoKuafu_Fight_Liao_Tower3:SetToolTip("#{SLDZ_220216_148}")
    else
        --SongliaoKuafu_Fight_Liao_Tower3:Hide()
        SongliaoKuafu_Fight_Liao_Tower3:SetProperty("Image", "set:SongliaoKuafu image:Liao_Disabled")
        SongliaoKuafu_Fight_Liao_Tower3:SetToolTip("#{SLDZ_220216_156}")
    end
    -- 辽 青龙
    if (liaoQingLong >= 0) then
        if (liaoTowerNum > 0) then
            SongliaoKuafu_Fight_Liao_Pic2:SetProperty("Image", "set:SongliaoKuafu image:QingLong_Anfight")
            SongliaoKuafu_Fight_Liao_Pic2:SetToolTip("#{SLDZ_220216_123}")
        else
            SongliaoKuafu_Fight_Liao_Pic2:SetProperty("Image", "set:SongliaoKuafu image:QingLong_Normal")
            SongliaoKuafu_Fight_Liao_Pic2:SetToolTip("#{SLDZ_220216_124}")
        end

        liaoDefenceNum = liaoDefenceNum + 1
    else
        SongliaoKuafu_Fight_Liao_Pic2:SetProperty("Image", "set:SongliaoKuafu image:QingLong_Disabled")
        SongliaoKuafu_Fight_Liao_Pic2:SetToolTip("#{SLDZ_220216_125}")
    end
    -- 辽 白虎
    if (liaoBaiHu >= 0) then
        if (liaoTowerNum > 0) then
            SongliaoKuafu_Fight_Liao_Pic3:SetProperty("Image", "set:SongliaoKuafu image:BaiHu_Anfight")
            SongliaoKuafu_Fight_Liao_Pic3:SetToolTip("#{SLDZ_220216_135}")
        else
            SongliaoKuafu_Fight_Liao_Pic3:SetProperty("Image", "set:SongliaoKuafu image:BaiHu_Normal")
            SongliaoKuafu_Fight_Liao_Pic3:SetToolTip("#{SLDZ_220216_143}")
        end

        liaoDefenceNum = liaoDefenceNum + 1
    else
        SongliaoKuafu_Fight_Liao_Pic3:SetProperty("Image", "set:SongliaoKuafu image:BaiHu_Disabled")
        SongliaoKuafu_Fight_Liao_Pic3:SetToolTip("#{SLDZ_220216_151}")
    end
    -- 辽 朱雀
    if (liaoZhuQue >= 0) then
        if (liaoTowerNum > 0) then
            SongliaoKuafu_Fight_Liao_Pic4:SetProperty("Image", "set:SongliaoKuafu image:ZhuQue_Anfight")
            SongliaoKuafu_Fight_Liao_Pic4:SetToolTip("#{SLDZ_220216_136}")
        else
            SongliaoKuafu_Fight_Liao_Pic4:SetProperty("Image", "set:SongliaoKuafu image:ZhuQue_Normal")
            SongliaoKuafu_Fight_Liao_Pic4:SetToolTip("#{SLDZ_220216_144}")
        end

        liaoDefenceNum = liaoDefenceNum + 1
    else
        SongliaoKuafu_Fight_Liao_Pic4:SetProperty("Image", "set:SongliaoKuafu image:ZhuQue_Disabled")
        SongliaoKuafu_Fight_Liao_Pic4:SetToolTip("#{SLDZ_220216_152}")
    end
    -- 辽 玄武
    if (liaoXuanWu >= 0) then
        if (liaoTowerNum > 0) then
            SongliaoKuafu_Fight_Liao_Pic5:SetProperty("Image", "set:SongliaoKuafu image:XuanWu_Anfight")
            SongliaoKuafu_Fight_Liao_Pic5:SetToolTip("#{SLDZ_220216_137}")
        else
            SongliaoKuafu_Fight_Liao_Pic5:SetProperty("Image", "set:SongliaoKuafu image:XuanWu_Normal")
            SongliaoKuafu_Fight_Liao_Pic5:SetToolTip("#{SLDZ_220216_145}")
        end

        liaoDefenceNum = liaoDefenceNum + 1
    else
        SongliaoKuafu_Fight_Liao_Pic5:SetProperty("Image", "set:SongliaoKuafu image:XuanWu_Disabled")
        SongliaoKuafu_Fight_Liao_Pic5:SetToolTip("#{SLDZ_220216_153}")
    end
    -- 辽 boss
    if (liaoDefenceNum > 0) then
        SongliaoKuafu_Fight_Liao_Pic6:SetToolTip("#{SLDZ_220216_142}")
    else
        SongliaoKuafu_Fight_Liao_Pic6:SetToolTip("#{SLDZ_220216_150}")
    end
    -- 辽 四象塔血量百分比
    local liaoDefenceHpTips = ScriptGlobal_Format("#{SLDZ_220216_175}", liaoDefenceHpPercent)
    SongliaoKuafu_Fight_Liao_MiniTitle:SetText(liaoDefenceHpTips)
    -- 辽 防御塔血量百分比
    local liaoTowerHpTips = ScriptGlobal_Format("#{SLDZ_220216_176}", liaoTowerHpPercent)
    SongliaoKuafu_Fight_Liao_MiniTitle2:SetText(liaoTowerHpTips)
end -- end func SongliaoKuafu_Fight_UpdateTowerData()

-- 刷新boss数据
function SongliaoKuafu_Fight_UpdateBossData()
    -- 宋 boss数据
    local songRet, songPosX, songPosZ, songHp, songMaxHp = CSongliaoWarData:TSLGetBossData(SongliaoKuafu_Fight_SongCamp, SongliaoKuafu_Fight_NPCType.Song.Boss)
    -- 辽 boss数据
    local liaoRet, liaoPosX, liaoPosZ, liaoHp, liaoMaxHp = CSongliaoWarData:TSLGetBossData(SongliaoKuafu_Fight_LiaoCamp, SongliaoKuafu_Fight_NPCType.Liao.Boss)

    -- 刷新宋boss数据
    if (songHp >= 0 and songMaxHp >= 0) then
        local songPercent = math.ceil((songHp / songMaxHp) * 100)
        local songTips = ScriptGlobal_Format("#{SLDZ_220216_94}", songPercent)

        SongliaoKuafu_Fight_Song_Pic6Number:Show()
        SongliaoKuafu_Fight_Song_Pic6Number:SetText(songTips)

        SongliaoKuafu_Fight_Song_Pic6_HP:Show()
        SongliaoKuafu_Fight_Song_Pic6_HP:SetProgress(songHp, songMaxHp)
    else
        --SongliaoKuafu_Fight_Song_Pic6Number:Hide()
        local songTips = ScriptGlobal_Format("#{SLDZ_220216_94}", 0)

        SongliaoKuafu_Fight_Song_Pic6Number:Show()
        SongliaoKuafu_Fight_Song_Pic6Number:SetText(songTips)

        SongliaoKuafu_Fight_Song_Pic6_HP:Show()
        SongliaoKuafu_Fight_Song_Pic6_HP:SetProgress(0, 1)
    end

    -- 刷新辽boss数据
    if (liaoHp >= 0 and liaoMaxHp >= 0) then
        local liaoPercent = math.ceil((liaoHp / liaoMaxHp) * 100)
        local liaoTips = ScriptGlobal_Format("#{SLDZ_220216_94}", liaoPercent)

        SongliaoKuafu_Fight_Liao_Pic6Number:Show()
        SongliaoKuafu_Fight_Liao_Pic6Number:SetText(liaoTips)

        SongliaoKuafu_Fight_Liao_Pic6_HP:Show()
        SongliaoKuafu_Fight_Liao_Pic6_HP:SetProgress(liaoHp, liaoMaxHp)
    else
        --SongliaoKuafu_Fight_Liao_Pic6Number:Hide()
        local liaoTips = ScriptGlobal_Format("#{SLDZ_220216_94}", 0)

        SongliaoKuafu_Fight_Liao_Pic6Number:Show()
        SongliaoKuafu_Fight_Liao_Pic6Number:SetText(liaoTips)

        SongliaoKuafu_Fight_Liao_Pic6_HP:Show()
        SongliaoKuafu_Fight_Liao_Pic6_HP:SetProgress(0, 1)
    end
end -- end func SongliaoKuafu_Fight_UpdateBossData()

-- 刷新目标提示
function SongliaoKuafu_Fight_UpdateTargetTips(myCamp)
    local targetCamp = -1
    local targetBossType = -1
    if (myCamp == SongliaoKuafu_Fight_SongCamp) then
        targetCamp = SongliaoKuafu_Fight_LiaoCamp
        targetBossType = SongliaoKuafu_Fight_NPCType.Liao.Boss
    elseif (myCamp == SongliaoKuafu_Fight_LiaoCamp) then
        targetCamp = SongliaoKuafu_Fight_SongCamp
        targetBossType = SongliaoKuafu_Fight_NPCType.Song.Boss
    else
        return
    end

    -- 获取敌对阵营的防御塔数量
    local towerNum = SongliaoKuafu_Fight_GetTowerNum(targetCamp)

    -- 刷新提示
    SongliaoKuafu_Fight_Goal_Icon1:Show()
    SongliaoKuafu_Fight_Goal_Text1:Show()
    if (towerNum > 0) then
        -- 防御塔没有全部摧毁
        SongliaoKuafu_Fight_Goal_Text1:SetText("#{SLDZ_220216_126}")
    else
        -- 四象塔已解锁
        -- 获取敌对阵营的四象塔数量
        local defenceNum = SongliaoKuafu_Fight_GetDefenceNum(targetCamp)
        if (defenceNum > 0) then
            -- 四象塔还未全部摧毁
            SongliaoKuafu_Fight_Goal_Text1:SetText("#{SLDZ_220216_128}")
        else
            -- 四象塔已摧毁
            -- 获取敌方boss数据
            local bossRet, bossPosX, bossPosZ, bossHp, bossMaxHp = CSongliaoWarData:TSLGetBossData(targetCamp, targetBossType)
            if (bossHp > 0) then
                -- boss还在
                SongliaoKuafu_Fight_Goal_Text1:SetText("#{SLDZ_220216_129}")
            else
                -- boss死亡
                SongliaoKuafu_Fight_Goal_Text1:SetText("#G#{SLDZ_220216_129}")
            end
        end
    end
end -- end func SongliaoKuafu_Fight_UpdateTargetTips()