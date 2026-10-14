-- 次级战场、原服战场
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

--夺得城市信息
local nMyCityList = {}


--夺得界碑信息
local nJieBeiList = {}
local nJieBeiNum  --个人夺碑数

--获取存储的数据
local PlayerName
local curTime

local nPoints --获得城战团队击杀
local nKillerKillNum --获得城战最大连续击杀人数
local nKillFlag --城战连杀标记 五十人斩
local nFlashFlag --城战高光时刻标记 力挽狂澜
local nFlagNum --获得城战夺旗数

--评分得分
local nScore


local g_StrCity = {
	[1] = "#{BZTX_220823_14}", --潮京城
	[2] = "#{BZTX_220823_13}", --钧天城
	[3] = "#{BZTX_220823_15}", --罗浮城
}

local g_StrnJieBei = {
    [1] = "#{BZTX_220823_20}", --潮京烽火石振奋
    [2] = "#{BZTX_220823_21}", --潮京烽火石复苏
	[3] = "#{BZTX_220823_16}", --钧天烽火石振奋
    [4] = "#{BZTX_220823_17}", --钧天烽火石复苏
    [5] = "#{BZTX_220823_18}", --罗浮烽火石振奋
    [6] = "#{BZTX_220823_19}", --罗浮烽火石复苏
	[7] = "#{BZTX_220823_33}", --潮京烽火石蓄锐
	[8] = "#{BZTX_220823_31}", --钧天烽火石蓄锐
	[9] = "#{BZTX_220823_32}", --罗浮烽火石蓄锐
}

local g_StrHightLightTips = {
	[1] = "#{BZTX_220823_11}", --连斩50人而自身毫发无伤
	[2] = "#{BZTX_220823_10}", --在霸者天下结束前5秒夺得城市战旗
}

local g_StrHightLightPhoto = {
	[1] = "set:GongChengZhan image:GongChengZhan_Bobao_Img01",
	[2] = "set:GongChengZhan image:GongChengZhan_Bobao_Img02",
}

local g_EveryLevelMaxScore = {
	[1] = 19, --0-19
	[2] = 59, --20-59
	[3] = 149, --60-149
	[4] = 299 --150-299 [5] 300以上
}

local g_LevelImage = {
	[1] = "set:GongChengZhan image:GongChengZhan_LV01",
	[2] = "set:GongChengZhan image:GongChengZhan_LV02",
	[3] = "set:GongChengZhan image:GongChengZhan_LV03",
	[4] = "set:GongChengZhan image:GongChengZhan_LV04",
	[5] = "set:GongChengZhan image:GongChengZhan_LV05"
}

function ThreeCityZhanBao_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("ZHANBAO_TOOLTIP",true)
	
end

function ThreeCityZhanBao_OnLoad()
	g_Frame_UnifiedXPosition = ThreeCityZhanBao_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition = ThreeCityZhanBao_Frame:GetProperty("UnifiedYPosition")
end

function ThreeCityZhanBao_ResetPos()
	ThreeCityZhanBao_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition)
	ThreeCityZhanBao_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition)
end

function ThreeCityZhanBao_OnHiden()
	ThreeCityZhanBao_Close()
end

function ThreeCityZhanBao_Close()
	this:Hide()
end

function ThreeCityZhanBao_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber( arg0 ) == 99816305) then
		--此处为第一次打开看到的战况总结，此时玩家还没有分享，所有数据都由攻城战Lua传过来
        --清空一下
        ThreeCityZhanBao_CleanData()
	    --帮会占领信息
		local nGuildData = Get_XParam_INT( 0 )
		--基本信息
		PlayerName = Player:GetName()
		curTime = Get_XParam_INT( 1 )
		nPoints = Get_XParam_INT( 2 )
		nKillerKillNum = Get_XParam_INT( 3 )
		nKillFlag = Get_XParam_INT( 4 )
		nFlashFlag = Get_XParam_INT( 5 )
		local nFlagAndJieBeiNum = Get_XParam_INT( 6 )--城战个人夺旗数 和 个人夺碑数

		local nGuildExtendData = Get_XParam_INT( 7 ) --新增界碑
		local misData = DataPool:GetPlayerMission_DataRound(3216)

		ThreeCityZhanBao_SetJieBeiAndCity( nGuildData,nGuildExtendData)
		ThreeCityZhanBao_SetFlagAndJieBeiNum( nFlagAndJieBeiNum)

		ThreeCityZhanBao_Btn:Show()


		ThreeCityZhanBao_ShowUI(curTime,misData)

    elseif(event == "UI_COMMAND" and tonumber( arg0 ) == 99816306) then
		--废弃不用
		----此处为根据传入玩家的WorldId和GuildId，得到城市和界碑信息
		----超链中帮会占领情况
		--local nGuildData = Get_XParam_INT( 0 )
		--ThreeCityZhanBao_SetJieBeiAndCity( nGuildData)
		--ThreeCityZhanBao_Btn:Hide()
		--ThreeCityZhanBao_ShowUI(curTime)

	elseif (event == "ADJEST_UI_POS" ) then
		ThreeCityZhanBao_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ThreeCityZhanBao_ResetPos()			
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ThreeCityZhanBao_Close()
	elseif (event == "ZHANBAO_TOOLTIP") then
		--此时所有数据都是由UI缓存的元素中传过来的数据
		--清空一下
		ThreeCityZhanBao_CleanData()
		--接受从元素传来的信息
		PlayerName = tostring(arg0)
		curTime = tonumber(arg1)
		nPoints = tonumber(arg2)
		nKillerKillNum = tonumber(arg3)
		nKillFlag = tonumber(arg4)
		nFlashFlag = tonumber(arg5)
		local nFlagAndJieBeiNum = tonumber(arg6)
		local nGuildData = tonumber(arg7)
		local nGuildExtendData = tonumber(arg8)
		local nCityWarMode = tonumber(arg9)

		ThreeCityZhanBao_SetFlagAndJieBeiNum( nFlagAndJieBeiNum)
		ThreeCityZhanBao_SetJieBeiAndCity( nGuildData,nGuildExtendData)
		
		ThreeCityZhanBao_Btn:Hide()
		ThreeCityZhanBao_ShowUI(curTime,nCityWarMode)
	end
	
end


--显示UI
function ThreeCityZhanBao_ShowUI(curTime,nCityWarMode)

	--计算评价得分
	ThreeCityZhanBao_CalculateScore()
    local year,month,day = ThreeCityZhanBao_GetYearMonthDay(curTime)
	ThreeCityZhanBao_Title:SetText(ScriptGlobal_Format("#{BZTX_220823_02}",PlayerName)) --%s0的霸者天下战报
	if nCityWarMode == 1 then
		ThreeCityZhanBao_Text1:SetText(ScriptGlobal_Format("#{BZTX_220823_03}",month,day,PlayerName))--%s0月%s1日#霸者天下中，%s2少侠：
	else
		ThreeCityZhanBao_Text1:SetText(ScriptGlobal_Format("#{BZTX_250605_17}",month,day,PlayerName))--%s0月%s1日#霸者天下-演武中，%s2少侠：
	end
    ThreeCityZhanBao_Text2:SetText(ScriptGlobal_Format("#{BZTX_220823_04}",nPoints)) --团队杀敌：#G%s
    ThreeCityZhanBao_Text3:SetText(ScriptGlobal_Format("#{BZTX_220823_06}",nKillerKillNum))--个人最高连杀：#G%s0
    ThreeCityZhanBao_Text4:SetText(ScriptGlobal_Format("#{BZTX_220823_08}",nFlagNum))--夺旗

	--高光时刻
	--什么都没有
	if nKillFlag == 0 and nFlashFlag == 0 then
		ThreeCityZhanBao_Img2:Hide()
		ThreeCityZhanBao_Img5:Hide()
		ThreeCityZhanBao_Text5:SetText("#{BZTX_220823_26}")
		ThreeCityZhanBao_Text5:Show()
	--连杀50人
	elseif nKillFlag == 1 and nFlashFlag == 0 then

		ThreeCityZhanBao_Img2:SetProperty("Image", g_StrHightLightPhoto[1])
		ThreeCityZhanBao_Img2:SetToolTip(g_StrHightLightTips[1])
		ThreeCityZhanBao_Img2:Show()
		ThreeCityZhanBao_Text5:Hide()

		ThreeCityZhanBao_Img5:Hide()
	--力挽狂澜
	elseif nKillFlag == 0 and nFlashFlag == 1 then

		ThreeCityZhanBao_Img2:SetProperty("Image", g_StrHightLightPhoto[2])
		ThreeCityZhanBao_Img2:SetToolTip(g_StrHightLightTips[2])
		ThreeCityZhanBao_Img2:Show()
		ThreeCityZhanBao_Text5:Hide()


		ThreeCityZhanBao_Img5:Hide()
	--俩都有
	elseif nKillFlag == 1 and nFlashFlag == 1 then
		ThreeCityZhanBao_Img2:SetProperty("Image", g_StrHightLightPhoto[2])
		ThreeCityZhanBao_Img2:SetToolTip(g_StrHightLightTips[2])
		ThreeCityZhanBao_Img2:Show()
		ThreeCityZhanBao_Text5:Hide()
	
		ThreeCityZhanBao_Img5:SetProperty("Image", g_StrHightLightPhoto[1])
		ThreeCityZhanBao_Img5:SetToolTip(g_StrHightLightTips[1])
		ThreeCityZhanBao_Img5:Show()

	end

	--帮会夺取
    --占领城市
    if nMyCityList[1] ~= 0 or nMyCityList[2] ~= 0 or nMyCityList[3] ~= 0 then
		local nMark = 0
		local nList = {}
		local szStr = ""

		--一共3个城
		for i = 1,3 do
			if nMyCityList[i] == 1 then
				nMark = nMark + 1
				nList[nMark] = i
			end
		end

		for i = 1, nMark do
			if i == nMark then
				szStr = szStr..g_StrCity[nList[nMark]]
			else
				szStr = szStr..g_StrCity[nList[i]].."#{BZTX_220823_22}"
			end
		end
		ThreeCityZhanBao_Text7:SetText(szStr)
		ThreeCityZhanBao_Text7:Show()
	else
		ThreeCityZhanBao_Text7:Hide()
	end

    --碑界
    if ThreeCityZhanBao_IsBeiJieListEmpty() ~= 1 then
		local nMark = 0
		local nList = {}
		local szStr = ""

		--一共9个碑
		for i = 1,9 do
			if nJieBeiList[i] == 1 then
				nMark = nMark + 1
				nList[nMark] = i
			end
		end

		for i = 1, nMark do
			if i == nMark then
				szStr = szStr..g_StrnJieBei[nList[nMark]]
			else
				szStr = szStr..g_StrnJieBei[nList[i]].."#{BZTX_220823_22}"
			end
		end
		ThreeCityZhanBao_Text8:SetText(szStr)
		ThreeCityZhanBao_Text8:Show()
	else
		ThreeCityZhanBao_Text8:Hide()
	end

	--本帮在此次霸者天下中未占领任意城市或烽火石
	if  nMyCityList[1] == 0 and nMyCityList[2] == 0 and nMyCityList[3] == 0 and ThreeCityZhanBao_IsBeiJieListEmpty() == 1 then
		ThreeCityZhanBao_Text7:SetText("#{BZTX_220823_27}")
		ThreeCityZhanBao_Text7:Show()
		ThreeCityZhanBao_Text8:Hide()
	end

	--评分
	for Index = 1,4 do
		if nScore <= g_EveryLevelMaxScore[Index] then
			ThreeCityZhanBao_Img3:SetProperty("Image", g_LevelImage[Index])
			break
		end
		--超过最大
		if nScore > g_EveryLevelMaxScore[4]  then
			ThreeCityZhanBao_Img3:SetProperty("Image", g_LevelImage[5])
			break
		end
	end

    this:Show()
end

function ThreeCityZhanBao_IsBeiJieListEmpty()
	for i =1,9 do
		 if nJieBeiList[i] ~= 0 then
			return 0
		 end
	end
	return 1
end

function ThreeCityZhanBao_CalculateScore()
	nScore = 0
	nScore = nScore + nPoints
	nScore = nScore + nKillerKillNum*2
	nScore = nScore + nFlagNum*80
	nScore = nScore + nJieBeiNum*60
	nScore = nScore + nKillFlag*100
	nScore = nScore + nFlashFlag*300
	nScore = nScore + nMyCityList[1]*40 + nMyCityList[2]*40 + nMyCityList[3]*50
	nScore = nScore + nJieBeiList[1]*30 + nJieBeiList[2]*30 + nJieBeiList[3]*30 + nJieBeiList[4]*30 + nJieBeiList[5]*30 + nJieBeiList[6]*30 + nJieBeiList[7]*30 + nJieBeiList[8]*30 + nJieBeiList[9]*30
end

function ThreeCityZhanBao_Share()
	Talk:ShareGongChengZhanBao()
end

function ThreeCityZhanBao_SetFlagAndJieBeiNum( num)
	nFlagNum = math.floor(num / 1000)
	nJieBeiNum =  math.mod(num, 1000)
end

function ThreeCityZhanBao_SetJieBeiAndCity( num,extendNum)
	local tempNum = 0
	local nMyCity = math.floor(num / 1000000)
	local nJieBei = math.mod(num, 1000000)

	--夺得城市信息
	tempNum = math.floor(nMyCity / 100)
	nMyCityList[1] = math.mod(tempNum, 10)

	tempNum = math.floor(nMyCity / 10)
	nMyCityList[2] = math.mod(tempNum, 10)

	nMyCityList[3] = math.mod(nMyCity, 10)
	tempNum = 0

	--夺得界碑信息
	tempNum = math.floor(nJieBei / 100000)
	nJieBeiList[1] = math.mod(tempNum, 10)

	tempNum = math.floor(nJieBei / 10000)
	nJieBeiList[2] = math.mod(tempNum, 10)

	tempNum = math.floor(nJieBei / 1000)
	nJieBeiList[3] = math.mod(tempNum, 10)

	tempNum = math.floor(nJieBei / 100)
	nJieBeiList[4] = math.mod(tempNum, 10)

	tempNum = math.floor(nJieBei / 10)
	nJieBeiList[5] = math.mod(tempNum, 10)

	nJieBeiList[6] = math.mod(nJieBei, 10)
	tempNum = 0
	--扩展界碑
	tempNum = math.floor(extendNum / 100)
	nJieBeiList[7] = math.mod(tempNum, 10)

	tempNum = math.floor(extendNum / 10)
	nJieBeiList[8] = math.mod(tempNum, 10)

	nJieBeiList[9] = math.mod(extendNum, 10)
end

function ThreeCityZhanBao_CleanData()
    --夺得城市信息
	nMyCityList = {}
    --夺得界碑信息
	nJieBeiList = {}
	nJieBeiNum = nil
    --获取存储的数据
    PlayerName = nil
    curTime = nil
    nPoints = nil
    nKillerKillNum = nil
	nFlagNum = nil
end

-- 获取日期的年、月、日 格式:20220830
function ThreeCityZhanBao_GetYearMonthDay(dateTime)
	local year = math.floor(dateTime / 10000)

	local temp = dateTime - year*10000
	local month = math.floor(temp / 100)

	local day = math.mod(dateTime, 100)

	return year, month, day
end