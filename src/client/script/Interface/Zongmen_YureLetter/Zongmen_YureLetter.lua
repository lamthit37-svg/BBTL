--2023Q3宗门预热活动
--门派召集界面
--!!!reloadscript =Zongmen_YureLetter

local g_Frame_Pos = nil

local g_Level = 30
local g_BeginDay = 0
local g_EndDay = 0

local MenPaiList = 
{
	[0] = "set:Zongmen_YR image:Zongmen_YR_XC",    --少林
	[1] = "set:Zongmen_YR image:Zongmen_YR_LSC",    --明教
	[2] = "set:Zongmen_YR image:Zongmen_YR_CGY",    --丐帮
	[3] = "set:Zongmen_YR image:Zongmen_YR_ZXS",    --武当
	[4] = "set:Zongmen_YR image:Zongmen_YR_MQQ",    --峨眉
	[5] = "set:Zongmen_YR image:Zongmen_YR_DCQ",    --星宿
	[6] = "set:Zongmen_YR image:Zongmen_YR_BY",    --天龙
	[7] = "set:Zongmen_YR image:Zongmen_YR_MJ",    --天山
	[8] = "set:Zongmen_YR image:Zongmen_YR_SXH",    --逍遥
	[9] = "",         --无门派
	[10] = "set:Zongmen_YR image:Zongmen_YR_MRC",   --慕容
	[11] = "set:Zongmen_YR image:Zongmen_YR_TYT",   --唐门
	[12] = "set:Zongmen_YR image:Zongmen_YR_WXZ",   --鬼谷
	[13] = "set:Zongmen_YR image:Zongmen_YR_ZMG",   --桃花岛
	[14] = "set:Zongmen_YR image:Zongmen_YR_MY",	  --绝情谷
	[15] = "set:Zongmen_YR image:Zongmen_YR_MY",	  --menpai15 mptodo
}

--=========
-- PreLoad
--=========
function Zongmen_YureLetter_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end

--=========
-- OnLoad
--=========
function Zongmen_YureLetter_OnLoad()
	g_Frame_Pos = Zongmen_YureLetter_Frame:GetProperty("UnifiedPosition")
end

--=========
-- OnEvent
--=========
function Zongmen_YureLetter_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99884001 )  then 
		g_BeginDay = Get_XParam_INT(0)
		g_EndDay = Get_XParam_INT(1)
		Zongmen_YureLetter_Open()		
	elseif event == "ADJEST_UI_POS" then
		Zongmen_YureLetter_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Zongmen_YureLetter_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Zongmen_YureLetter_Closed()
	end
end

--=========
-- 重置
--=========
function Zongmen_YureLetter_On_ResetPos()
	Zongmen_YureLetter_Frame:SetProperty("UnifiedPosition", g_Frame_Pos)
end

--=========
-- 打开
--=========
function Zongmen_YureLetter_Open()
	--显示界面
	this:Show()
	--信件内容
	local nMenpaiId = Player:GetData("MEMPAI")
	Zongmen_YureLetter_NameImg:SetProperty("Image", MenPaiList[nMenpaiId])
end

--=========
-- 关闭
--=========
function Zongmen_YureLetter_Closed()
	this:Hide()
end

--=========
-- 点击前往
--=========
function Zongmen_YureLetter_Goto_Click()
	local nLevel = Player:GetLevel()
	if nLevel < g_Level then
		PushDebugMessage("#{ZMYR_230803_02}")
		return
	end	
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_BeginDay or curDay > g_EndDay then
		PushDebugMessage("#{ZMYR_230803_03}")
		return
	end
	local nMenpaiId = Player:GetData("MEMPAI")
	if nMenpaiId == 9 then--无门派
		PushDebugMessage("#{ZMYR_230803_04}")
		return
	end
	if nMenpaiId == 0  then--少林
		AutoRuntoTargetExWithName(38,98,9,"玄慈")
	elseif nMenpaiId == 1  then--明教
		AutoRuntoTargetExWithName(98,52,11,"林世长")
	elseif nMenpaiId == 2  then--丐帮
		AutoRuntoTargetExWithName(91,98,10,"陈孤雁")
	elseif nMenpaiId == 3  then--武当
		AutoRuntoTargetExWithName(77,85,12,"张玄素")
	elseif nMenpaiId == 4  then--峨嵋
		AutoRuntoTargetExWithName(96,73,15,"孟青青")
	elseif nMenpaiId == 5  then--星宿
		AutoRuntoTargetExWithName(142,55,16,"丁春秋")
	elseif nMenpaiId == 6  then--天龙
		AutoRuntoTargetExWithName(96,66,13,"本因")
	elseif nMenpaiId == 7  then--天山
		AutoRuntoTargetExWithName(91,44,17,"梅剑")
	elseif nMenpaiId == 8  then--逍遥
		AutoRuntoTargetExWithName(125,144,14,"苏星河")
	elseif nMenpaiId == 10 then--慕容
		AutoRuntoTargetExWithName(69,109,284,"慕容垂")
	elseif nMenpaiId == 11 then--唐门
		AutoRuntoTargetExWithName(68,32,615,"唐岳天")
	elseif nMenpaiId == 12 then--鬼谷
		AutoRuntoTargetExWithName(96,52,678,"王栩之")
	elseif nMenpaiId == 13 then--桃花岛
		AutoRuntoTargetExWithName(160,51,731,"枕梦归")
	elseif nMenpaiId == 14 then--绝情谷
		AutoRuntoTargetExWithName(256,142,824,"穆宇")
	elseif nMenpaiId == 15 then--menpai15 mptodo
		AutoRuntoTargetExWithName(256,142,824,"穆宇")
	end
	Zongmen_YureLetter_Closed()
end



