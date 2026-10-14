--2022Q3新天外预热活动-ypl

----------------------
--1、自定义变量
----------------------
local g_ThreeCity_WarmUp_UnifiedPosition

--个人进度：炎黄信物数量
local g_ThreeCity_WarmUp_JinDu_GeRen

--全服进度：炎黄信物数量
local g_ThreeCity_WarmUp_JinDu_QuanFu

--领奖标记：全服4档
local g_ThreeCity_WarmUp_Prize_All = {}

--领奖标记：个人5档
local g_ThreeCity_WarmUp_Prize_Per = {}

--全服领奖档位
local g_ThreeCity_WarmUp_ALL_Limit = {}

--个人领奖档位
local g_ThreeCity_WarmUp_Per_Limit = {}

--进度条最大值
local g_ThreeCity_WarmUp_MaxProgress = 14

--4城小红点
local g_ThreeCity_WarmUp_4City_RedPoint = {}

--------------------------------
--2、控件部分
--------------------------------

--全服奖励：6档
local g_ThreeCity_WarmUp_ALLPrize_XML = {}

--个人奖励：6档
local g_ThreeCity_WarmUp_PerPrize_XML = {}

--全服：6档左侧控件
local g_ThreeCity_WarmUp_AllLeft_XML = {}

--全服：4城左侧按钮控件
local g_ThreeCity_WarmUp_4City_XML = {}

function ThreeCity_WarmUp_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function ThreeCity_WarmUp_OnLoad()	

	g_ThreeCity_WarmUp_UnifiedPosition = ThreeCity_WarmUp_Frame:GetProperty("UnifiedPosition")
	
	g_ThreeCity_WarmUp_JinDu_GeRen = 0
	g_ThreeCity_WarmUp_JinDu_QuanFu = 0
	
	g_ThreeCity_WarmUp_Prize_All[1] = 0
	g_ThreeCity_WarmUp_Prize_All[2] = 0
	g_ThreeCity_WarmUp_Prize_All[3] = 0
	g_ThreeCity_WarmUp_Prize_All[4] = 0	
	g_ThreeCity_WarmUp_Prize_All[5] = 0
	g_ThreeCity_WarmUp_Prize_All[6] = 0		
	
	g_ThreeCity_WarmUp_ALL_Limit[1] = 1000  --替代 
	g_ThreeCity_WarmUp_ALL_Limit[2] = 2000  --替代
	g_ThreeCity_WarmUp_ALL_Limit[3] = 6000  --替代
	g_ThreeCity_WarmUp_ALL_Limit[4] = 12000 --替代
	g_ThreeCity_WarmUp_ALL_Limit[5] = 18000  --替代
	g_ThreeCity_WarmUp_ALL_Limit[6] = 26000 --替代	
	
	g_ThreeCity_WarmUp_Prize_Per[1] = 0
	g_ThreeCity_WarmUp_Prize_Per[2] = 0
	g_ThreeCity_WarmUp_Prize_Per[3] = 0
	g_ThreeCity_WarmUp_Prize_Per[4] = 0
	g_ThreeCity_WarmUp_Prize_Per[5] = 0
	g_ThreeCity_WarmUp_Prize_Per[6] = 0
	
	g_ThreeCity_WarmUp_4City_RedPoint[1] = 0
	g_ThreeCity_WarmUp_4City_RedPoint[2] = 0
	g_ThreeCity_WarmUp_4City_RedPoint[3] = 0
	g_ThreeCity_WarmUp_4City_RedPoint[4] = 0
	
	g_ThreeCity_WarmUp_Per_Limit[1] = 1 --替代
	g_ThreeCity_WarmUp_Per_Limit[2] = 3 --替代
	g_ThreeCity_WarmUp_Per_Limit[3] = 5 --替代
	g_ThreeCity_WarmUp_Per_Limit[4] = 8 --替代
	g_ThreeCity_WarmUp_Per_Limit[5] = 11 --替代
	g_ThreeCity_WarmUp_Per_Limit[6] = 14 --替代
	
	g_ThreeCity_WarmUp_ALLPrize_XML[1] = {button=ThreeCity_WarmUp_Landscape_CityGift1, redpoint=ThreeCity_WarmUp_Landscape_CityGift1_Tips, finish=ThreeCity_WarmUp_Landscape_CityGift1_Open, desc=ThreeCity_WarmUp_Landscape_Quanfu1}
	g_ThreeCity_WarmUp_ALLPrize_XML[2] = {button=ThreeCity_WarmUp_Landscape_CityGift2, redpoint=ThreeCity_WarmUp_Landscape_CityGift2_Tips, finish=ThreeCity_WarmUp_Landscape_CityGift2_Open, desc=ThreeCity_WarmUp_Landscape_Quanfu2}
	g_ThreeCity_WarmUp_ALLPrize_XML[3] = {button=ThreeCity_WarmUp_Landscape_CityGift3, redpoint=ThreeCity_WarmUp_Landscape_CityGift3_Tips, finish=ThreeCity_WarmUp_Landscape_CityGift3_Open, desc=ThreeCity_WarmUp_Landscape_Quanfu3}
	g_ThreeCity_WarmUp_ALLPrize_XML[4] = {button=ThreeCity_WarmUp_Landscape_CityGift4, redpoint=ThreeCity_WarmUp_Landscape_CityGift4_Tips, finish=ThreeCity_WarmUp_Landscape_CityGift4_Open, desc=ThreeCity_WarmUp_Landscape_Quanfu4}
	g_ThreeCity_WarmUp_ALLPrize_XML[5] = {button=ThreeCity_WarmUp_Landscape_CityGift5, redpoint=ThreeCity_WarmUp_Landscape_CityGift5_Tips, finish=ThreeCity_WarmUp_Landscape_CityGift5_Open, desc=ThreeCity_WarmUp_Landscape_Quanfu5}
	g_ThreeCity_WarmUp_ALLPrize_XML[6] = {button=ThreeCity_WarmUp_Landscape_CityGift6, redpoint=ThreeCity_WarmUp_Landscape_CityGift6_Tips, finish=ThreeCity_WarmUp_Landscape_CityGift6_Open, desc=ThreeCity_WarmUp_Landscape_Quanfu6}
	
	g_ThreeCity_WarmUp_PerPrize_XML[1] = {button=ThreeCity_WarmUp_Action_Btn1, redpoint=ThreeCity_WarmUp_Action_Tips1, finish=ThreeCity_WarmUp_Action_GetMark1,}-- desc=ThreeCity_WarmUp_Action_Self1}
	g_ThreeCity_WarmUp_PerPrize_XML[2] = {button=ThreeCity_WarmUp_Action_Btn2, redpoint=ThreeCity_WarmUp_Action_Tips2, finish=ThreeCity_WarmUp_Action_GetMark2,}-- desc=ThreeCity_WarmUp_Action_Self2}
	g_ThreeCity_WarmUp_PerPrize_XML[3] = {button=ThreeCity_WarmUp_Action_Btn3, redpoint=ThreeCity_WarmUp_Action_Tips3, finish=ThreeCity_WarmUp_Action_GetMark3,}-- desc=ThreeCity_WarmUp_Action_Self3}
	g_ThreeCity_WarmUp_PerPrize_XML[4] = {button=ThreeCity_WarmUp_Action_Btn4, redpoint=ThreeCity_WarmUp_Action_Tips4, finish=ThreeCity_WarmUp_Action_GetMark4,}-- desc=ThreeCity_WarmUp_Action_Self4}
	g_ThreeCity_WarmUp_PerPrize_XML[5] = {button=ThreeCity_WarmUp_Action_Btn5, redpoint=ThreeCity_WarmUp_Action_Tips5, finish=ThreeCity_WarmUp_Action_GetMark5,}-- desc=ThreeCity_WarmUp_Action_Self5}
	g_ThreeCity_WarmUp_PerPrize_XML[6] = {button=ThreeCity_WarmUp_Action_Btn6, redpoint=ThreeCity_WarmUp_Action_Tips6, finish=ThreeCity_WarmUp_Action_GetMark6,}-- desc=ThreeCity_WarmUp_Action_Self6}
	
	g_ThreeCity_WarmUp_AllLeft_XML[1] = {Image=ThreeCity_WarmUp_Landscape_LockedCity1}
	g_ThreeCity_WarmUp_AllLeft_XML[2] = {Image=ThreeCity_WarmUp_Landscape_LockedCity2}
	g_ThreeCity_WarmUp_AllLeft_XML[3] = {Image=ThreeCity_WarmUp_Landscape_LockedCity3}
	g_ThreeCity_WarmUp_AllLeft_XML[4] = {Image=ThreeCity_WarmUp_Landscape_LockedCity4}
	g_ThreeCity_WarmUp_AllLeft_XML[5] = {Image=ThreeCity_WarmUp_Landscape_LockedCity5}
	g_ThreeCity_WarmUp_AllLeft_XML[6] = {Image=ThreeCity_WarmUp_Landscape_LockedCity6}
	
	g_ThreeCity_WarmUp_4City_XML[1] = {limt=2000, missionid=1425, button=ThreeCity_WarmUp_Landscape_Btn2, redpoint=ThreeCity_WarmUp_Landscape_Tips2, finish=ThreeCity_WarmUp_Landscape_Status2}
	g_ThreeCity_WarmUp_4City_XML[2] = {limt=12000, missionid=1427, button=ThreeCity_WarmUp_Landscape_Btn4, redpoint=ThreeCity_WarmUp_Landscape_Tips4, finish=ThreeCity_WarmUp_Landscape_Status4}
	g_ThreeCity_WarmUp_4City_XML[3] = {limt=18000, missionid=1426, button=ThreeCity_WarmUp_Landscape_Btn5, redpoint=ThreeCity_WarmUp_Landscape_Tips5, finish=ThreeCity_WarmUp_Landscape_Status5}
	g_ThreeCity_WarmUp_4City_XML[4] = {limt=26000, missionid=1428, button=ThreeCity_WarmUp_Landscape_Btn6, redpoint=ThreeCity_WarmUp_Landscape_Tips6, finish=ThreeCity_WarmUp_Landscape_Status6}
	
end

function ThreeCity_WarmUp_OnEvent(event)

	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99819705 ) then
		local operate = Get_XParam_INT(0)
		if operate == 0 then	
			--关闭界面
			this:Hide()		
		elseif operate == 1 then
			if this:IsVisible() then
				--关闭界面
				this:Hide()				
			else
				--接收数据
				g_ThreeCity_WarmUp_JinDu_GeRen = Get_XParam_INT(1)
				g_ThreeCity_WarmUp_JinDu_QuanFu = Get_XParam_INT(2)
				g_ThreeCity_WarmUp_Prize_All[1] = Pneuma:GetMF(3788)
				g_ThreeCity_WarmUp_Prize_All[2] = Pneuma:GetMF(3789)
				g_ThreeCity_WarmUp_Prize_All[3] = Pneuma:GetMF(3790)
				g_ThreeCity_WarmUp_Prize_All[4] = Pneuma:GetMF(3791)
				g_ThreeCity_WarmUp_Prize_All[5] = Pneuma:GetMF(3815)
				g_ThreeCity_WarmUp_Prize_All[6] = Pneuma:GetMF(3816)			
				g_ThreeCity_WarmUp_Prize_Per[1] = Pneuma:GetMF(3792)
				g_ThreeCity_WarmUp_Prize_Per[2] = Pneuma:GetMF(3793)
				g_ThreeCity_WarmUp_Prize_Per[3] = Pneuma:GetMF(3794)
				g_ThreeCity_WarmUp_Prize_Per[4] = Pneuma:GetMF(3795)
				g_ThreeCity_WarmUp_Prize_Per[5] = Pneuma:GetMF(3796)
				g_ThreeCity_WarmUp_Prize_Per[6] = Pneuma:GetMF(3817)
				g_ThreeCity_WarmUp_4City_RedPoint[1] = Pneuma:GetMF(3849)
				g_ThreeCity_WarmUp_4City_RedPoint[2] = Pneuma:GetMF(3850)
				g_ThreeCity_WarmUp_4City_RedPoint[3] = Pneuma:GetMF(3851)
				g_ThreeCity_WarmUp_4City_RedPoint[4] = Pneuma:GetMF(3852)
				--刷新界面
				ThreeCity_WarmUp_UpdateUI( )		
				this:Show()
			end
		elseif operate == 2 then
			--寻路
			AutoRuntoTargetExWithName(244, 270, 0, "逍遥子")
			--关闭界面
			this:Hide()
			--刷一下小红点
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("UpdateTodayData")
				Set_XSCRIPT_ScriptID(998197)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()				
		elseif (operate == 3) then
			--接收数据
			g_ThreeCity_WarmUp_JinDu_GeRen = Get_XParam_INT(1)
			g_ThreeCity_WarmUp_JinDu_QuanFu = Get_XParam_INT(2)
			g_ThreeCity_WarmUp_Prize_All[1] = Pneuma:GetMF(3788)
			g_ThreeCity_WarmUp_Prize_All[2] = Pneuma:GetMF(3789)
			g_ThreeCity_WarmUp_Prize_All[3] = Pneuma:GetMF(3790)
			g_ThreeCity_WarmUp_Prize_All[4] = Pneuma:GetMF(3791)
			g_ThreeCity_WarmUp_Prize_All[5] = Pneuma:GetMF(3815)
			g_ThreeCity_WarmUp_Prize_All[6] = Pneuma:GetMF(3816)			
			g_ThreeCity_WarmUp_Prize_Per[1] = Pneuma:GetMF(3792)
			g_ThreeCity_WarmUp_Prize_Per[2] = Pneuma:GetMF(3793)
			g_ThreeCity_WarmUp_Prize_Per[3] = Pneuma:GetMF(3794)
			g_ThreeCity_WarmUp_Prize_Per[4] = Pneuma:GetMF(3795)
			g_ThreeCity_WarmUp_Prize_Per[5] = Pneuma:GetMF(3796)
			g_ThreeCity_WarmUp_Prize_Per[6] = Pneuma:GetMF(3817)
			g_ThreeCity_WarmUp_4City_RedPoint[1] = Pneuma:GetMF(3849)
			g_ThreeCity_WarmUp_4City_RedPoint[2] = Pneuma:GetMF(3850)
			g_ThreeCity_WarmUp_4City_RedPoint[3] = Pneuma:GetMF(3851)
			g_ThreeCity_WarmUp_4City_RedPoint[4] = Pneuma:GetMF(3852)
			--刷新界面
			ThreeCity_WarmUp_UpdateUI( )
			if this:IsVisible() then
				this:Show()		
			else
				this:Hide()
			end
		elseif operate == 4 then	
			SystemSetup:Lua_Set2022Weather(1)	
		elseif operate == 5 then	
			SystemSetup:Lua_Set2022Weather(0)				
		end
	elseif (event == "ADJEST_UI_POS" ) then
		ThreeCity_WarmUp_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ThreeCity_WarmUp_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function ThreeCity_WarmUp_UpdateUI( )

	--------------------
	--1、炎黄信物进度
	--------------------
	--全服进度
	ThreeCity_WarmUp_Quanfu:SetText(ScriptGlobal_Format("#{XTWYR_220729_09}", g_ThreeCity_WarmUp_JinDu_QuanFu))
	--个人进度
	ThreeCity_WarmUp_Self:SetText(ScriptGlobal_Format("#{XTWYR_220729_08}", g_ThreeCity_WarmUp_JinDu_GeRen))
	
	--------------------
	--2、领奖情况
	--------------------		
	--全服奖项
	ThreeCity_WarmUp_QuanFuPrizeInfo(1)
	ThreeCity_WarmUp_QuanFuPrizeInfo(2)
	ThreeCity_WarmUp_QuanFuPrizeInfo(3)
	ThreeCity_WarmUp_QuanFuPrizeInfo(4)
	ThreeCity_WarmUp_QuanFuPrizeInfo(5)
	ThreeCity_WarmUp_QuanFuPrizeInfo(6)
	--个人奖项
	ThreeCity_WarmUp_GeRenPrizeInfo(1)
	ThreeCity_WarmUp_GeRenPrizeInfo(2)
	ThreeCity_WarmUp_GeRenPrizeInfo(3)
	ThreeCity_WarmUp_GeRenPrizeInfo(4)
	ThreeCity_WarmUp_GeRenPrizeInfo(5)
	ThreeCity_WarmUp_GeRenPrizeInfo(6)
	--进度条
	local cur_progress = g_ThreeCity_WarmUp_JinDu_GeRen
	if cur_progress > g_ThreeCity_WarmUp_MaxProgress then
		cur_progress = g_ThreeCity_WarmUp_MaxProgress
	end
	ThreeCity_WarmUp_Action_Progress:SetProgress(tonumber(cur_progress), g_ThreeCity_WarmUp_MaxProgress)
	
	------------------------
	--3、全服6个档位解锁情况
	------------------------
	--解锁与否需要显隐的图片
	ThreeCity_WarmUp_QuanFuLock()	
	--4城之外的2个button要常显，其实是image
	ThreeCity_WarmUp_Landscape_Btn1:Show()
	ThreeCity_WarmUp_Landscape_Btn3:Show()
	--4城button
	ThreeCity_WarmUp_4CityButton(1)
	ThreeCity_WarmUp_4CityButton(2)
	ThreeCity_WarmUp_4CityButton(3)
	ThreeCity_WarmUp_4CityButton(4)
	
	--刷一下小红点
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UpdateTodayData")
		Set_XSCRIPT_ScriptID(998197)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

---------------------------
--全服4档领奖UI信息：更新
---------------------------
function ThreeCity_WarmUp_QuanFuPrizeInfo(nIndex)

	if g_ThreeCity_WarmUp_Prize_All[nIndex] == nil or g_ThreeCity_WarmUp_ALL_Limit[nIndex] == nil then
		return
	end

	--1、【未达到领奖进度】
	--红点：隐藏
	--已领奖：隐藏
	if g_ThreeCity_WarmUp_JinDu_QuanFu < g_ThreeCity_WarmUp_ALL_Limit[nIndex] then
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].button:Enable()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].button:Show()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].redpoint:Hide()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].finish:Hide()
	--2、【已达到领奖进度】未领奖
	--红点：显示
	--已领奖：隐藏
	elseif g_ThreeCity_WarmUp_Prize_All[nIndex] ~= 1 then
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].button:Enable()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].button:Show()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].redpoint:Show()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].finish:Hide()	
	--3、【已达到领奖进度】已领奖
	--红点：隐藏
	--已领奖：显示
	else
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].button:Disable()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].button:Hide()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].redpoint:Hide()
		g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].finish:Show()	
	end
	
	--文字
	g_ThreeCity_WarmUp_ALLPrize_XML[nIndex].desc:SetText(ScriptGlobal_Format("#{XTWYR_220729_12}", g_ThreeCity_WarmUp_ALL_Limit[nIndex]))
	
end

---------------------------
--个人5档领奖UI信息：更新
---------------------------
function ThreeCity_WarmUp_GeRenPrizeInfo(nIndex)

	if g_ThreeCity_WarmUp_Prize_Per[nIndex] == nil then
		return
	end

	--1、【未达到领奖进度】
	--红点：隐藏
	--已领奖：隐藏
	if g_ThreeCity_WarmUp_JinDu_GeRen < g_ThreeCity_WarmUp_Per_Limit[nIndex] then
		--g_ThreeCity_WarmUp_PerPrize_XML[nIndex].button:Disable()
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].button:Enable()
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].redpoint:Hide()
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].finish:Hide()
	--2、【已达到领奖进度】未领奖
	--红点：显示
	--已领奖：隐藏
	elseif g_ThreeCity_WarmUp_Prize_Per[nIndex] ~= 1 then
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].button:Enable()
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].redpoint:Show()
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].finish:Hide()	
	--3、【已达到领奖进度】已领奖
	--红点：隐藏
	--已领奖：显示
	else
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].button:Disable()
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].redpoint:Hide()
		g_ThreeCity_WarmUp_PerPrize_XML[nIndex].finish:Show()	
	end
	
	--文字
	--g_ThreeCity_WarmUp_PerPrize_XML[nIndex].desc:SetText(ScriptGlobal_Format("#{XTWYR_220729_19}", g_ThreeCity_WarmUp_Per_Limit[nIndex]))
end

------------------------
--全服6个档位解锁情况
------------------------
function ThreeCity_WarmUp_QuanFuLock()
	for i=1, table.getn(g_ThreeCity_WarmUp_ALL_Limit) do
		if g_ThreeCity_WarmUp_JinDu_QuanFu < g_ThreeCity_WarmUp_ALL_Limit[i] then
			--解锁
			g_ThreeCity_WarmUp_AllLeft_XML[i].Image:Show()
		else
			--未解锁
			g_ThreeCity_WarmUp_AllLeft_XML[i].Image:Hide()
		end
	end
end

------------------------
--全服4城按钮开城情况
------------------------
function ThreeCity_WarmUp_4CityButton(nIndex)

	local Info = g_ThreeCity_WarmUp_4City_XML[nIndex]
	if Info == nil then
		return
	end
	
	--1、4城未开放
	--button：Enable；redppint：隐藏；finish：隐藏
	if g_ThreeCity_WarmUp_JinDu_QuanFu < Info.limt then
		--Info.button:Enable()
		-- Info.button:Show()
		Info.redpoint:Hide()
		Info.finish:Hide()		
	--2、已完成对应任务
	--button：Disable；redppint：隐藏；finish：显示
	elseif DataPool:Lua_IsMissionHaveDone(Info.missionid) == 1 then
		--Info.button:Disable()
		-- Info.button:Hide()
		Info.button:SetToolTip("#{XTWYR_220729_307}")
		Info.redpoint:Hide()
		Info.finish:Show()
	--3、未完成任务
	--button：Enable；finish：隐藏
	else
		--Info.button:Enable()
		-- Info.button:Show()
		Info.finish:Hide()
		--（1）当天未点击过
		--redpoint:显示
		if g_ThreeCity_WarmUp_4City_RedPoint[nIndex] == 0 then
			Info.redpoint:Show()
		--（2）当天点击过
		--redpoint:隐藏
		else
			Info.redpoint:Hide()
		end
	end
end

----------------------------
--4城寻路按钮
--nIndex：1~4
--点击后，小红点消失，并寻路
----------------------------
function ThreeCity_WarmUp_Goto_Clicked(nIndex)
	
	if nIndex < 1 or nIndex > 4 then
		return
	end

	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GoToFindNpc" )
		Set_XSCRIPT_ScriptID(998197)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

---------------------------
--界面位置恢复
---------------------------
function ThreeCity_WarmUp_On_ResetPos()
	ThreeCity_WarmUp_Frame:SetProperty("UnifiedPosition", g_ThreeCity_WarmUp_UnifiedPosition);
end

---------------------------
--全服4档领奖：点击领奖按钮
---------------------------
function ThreeCity_WarmUp_Landscape_Clicked( nIndex )
	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize_All" )
		Set_XSCRIPT_ScriptID(998197)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
---------------------------
--全服4档领奖：领奖结束动画
---------------------------
function T3WarmUp_Landscape_StatusAnimEnd( nIndex )

end

---------------------------
--个人5档领奖：点击按钮
---------------------------
function ThreeCity_WarmUp_Action_Clicked( nIndex )
	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize_Per" )
		Set_XSCRIPT_ScriptID(998197)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

---------------------------
--获取进度：点击按钮
---------------------------
function ThreeCity_WarmUp_GetClicked()
	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GoToFindNpc" )
		Set_XSCRIPT_ScriptID(998197)
		Set_XSCRIPT_Parameter(0,0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

---------------------------
--问号：帮助按钮
---------------------------
function ThreeCity_WarmUp_Help_Clicked()
	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end

	PushEvent("CCSHOP_HELP", 171)
end

---------------------------
--购买按钮
---------------------------
function ThreeCity_WarmUp_Buy_Clicked()
	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenYuanBaoBuyUI" )
		Set_XSCRIPT_ScriptID(998197)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

---------------------------------------------------
--功能：关闭界面
---------------------------------------------------
function ThreeCity_WarmUp_Close_Clicked()
	this:Hide()
end

