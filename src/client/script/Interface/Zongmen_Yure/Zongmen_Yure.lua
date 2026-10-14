--2023Q3宗门预热活动
--正式活动界面
--!!!reloadscript =Zongmen_Yure

local g_Frame_Pos = nil

local g_Level = 30
local g_BeginDay = 0
local g_EndDay = 0

--领奖
local g_PrizeCtrl = {}
local g_Prize = 
{
	[1] = { value = 1, tip = "#{ZMYR_230803_29}", kjtip = "#{ZMYR_230803_139}", bk = "set:Zongmen_YR image:Zongmen_YR_PicBK1_Off", image = "set:Zongmen_YR image:Zongmen_YR_PicBK1_On",},
	[2] = { value = 2, tip = "#{ZMYR_230803_30}", kjtip = "#{ZMYR_230803_30}", bk = "set:Zongmen_YR image:Zongmen_YR_PicBK2_Off", image = "set:Zongmen_YR image:Zongmen_YR_PicBK2_On",},
	[3] = { value = 3, tip = "#{ZMYR_230803_31}", kjtip = "#{ZMYR_230803_31}", bk = "set:Zongmen_YR image:Zongmen_YR_PicBK3_Off", image = "set:Zongmen_YR image:Zongmen_YR_PicBK3_On",},
	[4] = { value = 5, tip = "#{ZMYR_230803_32}", kjtip = "#{ZMYR_230803_32}", bk = "set:Zongmen_YR image:Zongmen_YR_PicBK4_Off", image = "set:Zongmen_YR image:Zongmen_YR_PicBK4_On",},
}

--=========
-- PreLoad
--=========
function Zongmen_Yure_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end

--=========
-- OnLoad
--=========
function Zongmen_Yure_OnLoad()
	g_Frame_Pos = Zongmen_Yure_Frame:GetProperty("UnifiedPosition")
	g_PrizeCtrl = 
	{
		[1] = {bk=Zongmen_Yure_PicBK1,flag=Zongmen_Yure_PicBK1_OverImg,btn=Zongmen_Yure_PicBK1_Button,tip=Zongmen_Yure_PicBK1_Tips,check=Zongmen_Yure_PicBK1_BoxOpen,text=Zongmen_Yure_Text1},
		[2] = {bk=Zongmen_Yure_PicBK2,flag=Zongmen_Yure_PicBK2_OverImg,btn=Zongmen_Yure_PicBK2_Button,tip=Zongmen_Yure_PicBK2_Tips,check=Zongmen_Yure_PicBK2_BoxOpen,text=Zongmen_Yure_Text2},
		[3] = {bk=Zongmen_Yure_PicBK3,flag=Zongmen_Yure_PicBK3_OverImg,btn=Zongmen_Yure_PicBK3_Button,tip=Zongmen_Yure_PicBK3_Tips,check=Zongmen_Yure_PicBK3_BoxOpen,text=Zongmen_Yure_Text3},
		[4] = {bk=Zongmen_Yure_PicBK4,flag=Zongmen_Yure_PicBK4_OverImg,btn=Zongmen_Yure_PicBK4_Button,tip=Zongmen_Yure_PicBK4_Tips,check=Zongmen_Yure_PicBK4_BoxOpen,text=Zongmen_Yure_Text4},			
	}
end

--=========
-- OnEvent
--=========
function Zongmen_Yure_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99884002 )  then 
		local flag = Get_XParam_INT(0)
		local value = Get_XParam_INT(1)
		local flag1 = Get_XParam_INT(2)
		local flag2 = Get_XParam_INT(3)
		local flag3 = Get_XParam_INT(4)
		local flag4 = Get_XParam_INT(5)
		g_BeginDay = Get_XParam_INT(6)
		g_EndDay = Get_XParam_INT(7)
		if flag == nil or flag <= 0 then
			Zongmen_Yure_Closed()
		elseif flag == 1 then
			--显示界面
			this:Show()
			Zongmen_Yure_Open(tonumber(value),tonumber(flag1),tonumber(flag2),tonumber(flag3),tonumber(flag4))
		elseif flag == 2 then
			--刷新界面
			if( this:IsVisible() ) then
				Zongmen_Yure_Open(tonumber(value),tonumber(flag1),tonumber(flag2),tonumber(flag3),tonumber(flag4))
			end
		end
	elseif event == "ADJEST_UI_POS" then
		Zongmen_Yure_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Zongmen_Yure_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Zongmen_Yure_Closed()
	end
end

--=========
-- 重置
--=========
function Zongmen_Yure_On_ResetPos()
	Zongmen_Yure_Frame:SetProperty("UnifiedPosition", g_Frame_Pos)
end

--=========
-- 打开
--=========
function Zongmen_Yure_Open(value,flag1,flag2,flag3,flag4)
	if value == nil or flag1 == nil or flag2 == nil or flag3 == nil or flag4 == nil then
		return
	end
	--累计探索度
	Zongmen_Yure_Text:SetText(ScriptGlobal_Format("#{ZMYR_230803_26}", value))
	--显示领奖
	local flag = {flag1,flag2,flag3,flag4}
	for i=1,table.getn(g_Prize) do
		--文字
		g_PrizeCtrl[i].text:SetText(ScriptGlobal_Format("#{ZMYR_230803_27}", g_Prize[i].value))
		--背景图
		if value >= g_Prize[i].value then
			g_PrizeCtrl[i].bk:SetProperty("Image", g_Prize[i].image)
			g_PrizeCtrl[i].flag:Show()
		else
			g_PrizeCtrl[i].bk:SetProperty("Image", g_Prize[i].bk)
			g_PrizeCtrl[i].flag:Hide()
		end
		--按钮tips
		local szTip = g_Prize[i].tip
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(140) > 0 then  --卡级
			szTip = g_Prize[i].kjtip
		end
		g_PrizeCtrl[i].btn:SetToolTip(szTip)
		--已领取
		if flag[i] == 1 then
			--按钮隐藏
			g_PrizeCtrl[i].btn:Hide()
			--小红点隐藏
			g_PrizeCtrl[i].tip:Hide()
			--图片显示
			g_PrizeCtrl[i].check:Show()
		--未领取
		else
			--按钮显示
			g_PrizeCtrl[i].btn:Show()
			--小红点
			if value >= g_Prize[i].value then
				g_PrizeCtrl[i].tip:Show()
			else
				g_PrizeCtrl[i].tip:Hide()
			end
			--图片隐藏
			g_PrizeCtrl[i].check:Hide()
		end
	end
end

--=========
-- 关闭
--=========
function Zongmen_Yure_Closed()
	this:Hide()
end

--=========
-- 小问号
--=========
function Zongmen_Yure_Help()
	PushEvent("CCSHOP_HELP", 199)	
end

--=========
-- 点击前往
--=========
function Zongmen_Yure_Goto_Click()	
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
	Zongmen_Yure_Closed()
end

--=========
-- 领奖
--=========
function Zongmen_Yure_Button_Click(nIndex)
	if g_Prize[nIndex] == nil then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnPrize")
		Set_XSCRIPT_ScriptID(998840)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


