--******************************************
--冰雪世界元旦打卡-泡温泉
--任务进度界面
--create by  limengyue 
--2024-10-09
--******************************************

local g_Frozen_HotSpring_Frame_UnifiedPosition;

--体温对应分数
local g_MaxTime = 30*60
local g_MaxHappy = 1000
local g_HappySuper = 60
local g_HappySuperTemp = 74
local g_Frozen_HotSpring_Temp =
{
	[1] = {nInfo="太冷了",nMin=0,nMax=20,nPoint=1,nTips="#{BXPWQ_240927_106}",nImg="set:Frozen_HotSpring image:Frozen_HotSpring_GGL",nShowImg="set:Frozen_HotSpring image:Frozen_HotSpring_GGL1",}, --[nMin,nMax)
	[2] = {nInfo="正常",nMin=20,nMax=70,nPoint=10,nTips="#{BXPWQ_240927_107}",nImg="set:Frozen_HotSpring image:Frozen_HotSpring_ST",nShowImg="set:Frozen_HotSpring image:Frozen_HotSpring_ST10",},
	[3] = {nInfo="红温",nMin=70,nMax=80,nPoint=30,nTips="#{BXPWQ_240927_109}",nImg="set:Frozen_HotSpring image:Frozen_HotSpring_ZTK",nShowImg="set:Frozen_HotSpring image:Frozen_HotSpring_ZTK60",},
	[4] = {nInfo="太热了",nMin=80,nMax=100,nPoint=1,nTips="#{BXPWQ_240927_110}",nImg="set:Frozen_HotSpring image:Frozen_HotSpring_ZLR",nShowImg="set:Frozen_HotSpring image:Frozen_HotSpring_ZLR1",},
}

--奖励
local g_Frozen_HotSpring_Award =
{
	[1] = {nInfo="一等奖",nTime=3*60,nImgok="set:Frozen_HotSpring image:RY_Hover",nImgNo="set:Frozen_HotSpring image:RY_Disabled",},
	[2] = {nInfo="二等奖",nTime=5*60,nImgok="set:Frozen_HotSpring image:QY_Hover",nImgNo="set:Frozen_HotSpring image:QY_Disabled",},
	[3] = {nInfo="三等奖",nTime=100*60,nImgok="set:Frozen_HotSpring image:SY_Hover",nImgNo="set:Frozen_HotSpring image:SY",},
}

--控件
local g_Frozen_HotSpring_AwardList = {}	--奖励
local g_Frozen_HotSpring_ShowImgList = {}	--温度显示

--===============================================
-- PreLoad()
--===============================================
function Frozen_HotSpring_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BXSJ_PAOWENQUAN_MINI")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--===============================================
-- OnLoad()
--===============================================
function Frozen_HotSpring_OnLoad()   
	-- 保存界面的默认相对位置
	g_Frozen_HotSpring_Frame_UnifiedPosition = Frozen_HotSpring_Frame:GetProperty("UnifiedPosition");
	--控件
	g_Frozen_HotSpring_AwardList[1] = Frozen_HotSpring_TimeReward1
	g_Frozen_HotSpring_AwardList[2] = Frozen_HotSpring_TimeReward2
	g_Frozen_HotSpring_AwardList[3] = Frozen_HotSpring_TimeReward3
	--温度显示
	g_Frozen_HotSpring_ShowImgList[1] = Frozen_HotSpring_Icon1
	g_Frozen_HotSpring_ShowImgList[2] = Frozen_HotSpring_Icon3
	g_Frozen_HotSpring_ShowImgList[3] = Frozen_HotSpring_Icon5
	g_Frozen_HotSpring_ShowImgList[4] = Frozen_HotSpring_Icon6
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_HotSpring_Frame_On_ResetPos()
	Frozen_HotSpring_Frame:SetProperty("UnifiedPosition", g_Frozen_HotSpring_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Frozen_HotSpring_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 99951201) then
		
		local bUpdate = Get_XParam_INT(0)
		--PushDebugMessage(" Frozen_HotSpring_Open bUpdate="..bUpdate)
		if bUpdate == 1 then
			--更新数据
			if(IsWindowShow("Frozen_HotSpring_Mini")) then
				--
			else
				--没有mini界面就应该一直更新
				Frozen_HotSpring_Open(Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4))
			end
		else
			--打开界面
			if(IsWindowShow("Frozen_HotSpring_Mini")) then
				CloseWindow("Frozen_HotSpring_Mini", true)
			end
			if(IsWindowShow("Frozen_HotSpring")) then
				CloseWindow("Frozen_HotSpring", true)
			end
			Frozen_HotSpring_Open(Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4))
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 99951202) then
		--关闭界面
		if(IsWindowShow("Frozen_HotSpring")) then
			 Frozen_HotSpring_OnHiden()
		end
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Frozen_HotSpring_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_HotSpring_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       Frozen_HotSpring_OnHiden()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			Frozen_HotSpring_OnHiden()
		end
    end
         
end

--===============================================
-- Frozen_HotSpring_OnHiden()
--===============================================
function Frozen_HotSpring_OnHiden()
	this:Hide()
end


--=========================================================
--默认打开界面
--=========================================================
function Frozen_HotSpring_Open(mOkTick,mBodyTemp,mHappyNum,mTotalTick)
	--PushDebugMessage(" Frozen_HotSpring_Open mOkTick="..mOkTick.." mBodyTemp="..mBodyTemp.." mHappyNum="..mHappyNum.." mTotalTick="..mTotalTick)
	--倒计时
	--Frozen_HotSpring_Text7:SetText(ScriptGlobal_Format("#{BXPWQ_240927_50}",tonumber(mOkTick)));
	--状态图片
	local  mIdx = 1
	local  nLength = table.getn(g_Frozen_HotSpring_Temp)
	for index=1,table.getn(g_Frozen_HotSpring_Temp)  do
		if mBodyTemp >= g_Frozen_HotSpring_Temp[nLength].nMax then
			mIdx = nLength
			break
		end
		if mBodyTemp >= g_Frozen_HotSpring_Temp[index].nMin and mBodyTemp < g_Frozen_HotSpring_Temp[index].nMax then
			mIdx = index
			break
		end
	end
	Frozen_HotSpring_image:SetProperty( "Image", g_Frozen_HotSpring_Temp[mIdx].nImg )
	Frozen_HotSpring_Text8:SetText(g_Frozen_HotSpring_Temp[mIdx].nTips);
	--显示进度条
	Frozen_HotSpring_EXP:SetProgress( mBodyTemp , g_Frozen_HotSpring_Temp[nLength].nMax );
	--进度条bg颜色
	if mIdx == 1 then
		--太冷了 蓝色
		Frozen_HotSpring_Blue:Show()
		Frozen_HotSpring_Red:Hide()
	elseif mIdx == nLength then
		--太热了 红色
		Frozen_HotSpring_Blue:Hide()
		Frozen_HotSpring_Red:Show()
	else
		--正常
		Frozen_HotSpring_Blue:Hide()
		Frozen_HotSpring_Red:Hide()
	end
	
	-- --显示加分图片
	-- for index=1,table.getn(g_Frozen_HotSpring_Temp)  do
		-- g_Frozen_HotSpring_ShowImgList[index]:SetProperty( "Image", g_Frozen_HotSpring_Temp[index].nShowImg )
	-- end
	--当前满意度
	Frozen_HotSpring_Text:SetText(ScriptGlobal_Format("#{BXPWQ_240927_58}",mHappyNum));
	
	--累计时间
	local  skyTimeString = ""
	local skyMinute = math.floor(mTotalTick / 60)
	local skySecond = math.mod(mTotalTick, 60)
	if skyMinute < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skyMinute) .. ":"
	if skySecond < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skySecond)
	Frozen_HotSpring_TimeText:SetText(ScriptGlobal_Format("#{BXPWQ_240927_118}",skyTimeString));
	--默认奖励都不显示
	for index=1,table.getn(g_Frozen_HotSpring_AwardList)  do
		g_Frozen_HotSpring_AwardList[index]:SetProperty( "Image", g_Frozen_HotSpring_Award[index].nImgNo )
	end

	if mHappyNum >= g_MaxHappy then
		if mTotalTick <= g_Frozen_HotSpring_Award[1].nTime then
			--展示奖励
			g_Frozen_HotSpring_AwardList[1]:SetProperty( "Image", g_Frozen_HotSpring_Award[1].nImgok )
		elseif mTotalTick <= g_Frozen_HotSpring_Award[2].nTime then
			--展示奖励
			g_Frozen_HotSpring_AwardList[2]:SetProperty( "Image", g_Frozen_HotSpring_Award[2].nImgok )
		else
			--展示奖励
			g_Frozen_HotSpring_AwardList[3]:SetProperty( "Image", g_Frozen_HotSpring_Award[3].nImgok )
		end
	end
	this:Show()		
end

--===============================================
--最小化
--===============================================
function Frozen_HotSpring_Mini()
	PushEvent( "BXSJ_PAOWENQUAN_MINI" )
	--PushEvent("BXSJ_PAOWENQUAN_MINI",index)
end

--=========================================================
--帮助
--=========================================================
function Frozen_HotSpring_Help()
	PushEvent("QUEST_HELPINFO", "缺字典")
end