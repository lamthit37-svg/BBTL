--******************************************
--周常肉鸽爬塔副本	战斗中界面
--create by  limengyue 
--2023-12-06
--******************************************

local g_RouGe_Ing_Frame_UnifiedPosition;
local g_BossBasePoint = 1000
local g_RouGe_Ing_Time = 1 --计时器
local g_RouGe_Stage = -1	--当前阶段
local g_RouGe_SKillBtn = {};
local g_RouGe_Ing_SkillList = {}	--技能列表
local g_RouGe_Ing_SkillLvTxt = {}	--技能等级显示
local g_RouGe_Ing_BossShowList = {}		--boss选择信息面板
local g_RouGe_Ing_BossSelectList = {}	--boss选择信息
local g_RouGe_Ing_BossDetailList = {}	--boss选择信息详情

--词条
local g_RouGe_BossBuff1 =
{
	[1] = {nTips="#{RGPT_231130_553}",nPoint=0,nDetail="#{RGPT_231130_554}",},
	[2] = {nTips="#{RGPT_231130_555}",nPoint=100,nDetail="#{RGPT_231130_556}", },
	[3] = {nTips="#{RGPT_231130_557}",nPoint=200,nDetail="#{RGPT_231130_558}", },
	[4] = {nTips="#{RGPT_231130_559}",nPoint=400,nDetail="#{RGPT_231130_560}", },
	[5] = {nTips="#{RGPT_240703_25}",nPoint=-100,nDetail="#{RGPT_240703_26}", },
	[6] = {nTips="#{RGPT_240703_27}",nPoint=-200,nDetail="#{RGPT_240703_28}", },
	[7] = {nTips="#{RGPT_240703_29}",nPoint=-400,nDetail="#{RGPT_240703_30}", },
}
local g_RouGe_BossBuff2 =
{
	[1] = {nTips="#{RGPT_231130_561}",nPoint=0,nDetail="#{RGPT_231130_562}", },
	[2] = {nTips="#{RGPT_231130_563}",nPoint=100,nDetail="#{RGPT_231130_564}", },
	[3] = {nTips="#{RGPT_231130_565}",nPoint=200,nDetail="#{RGPT_231130_566}", },
	[4] = {nTips="#{RGPT_231130_567}",nPoint=400,nDetail="#{RGPT_231130_568}", },
	[5] = {nTips="#{RGPT_240703_31}",nPoint=-100,nDetail="#{RGPT_240703_32}", },
	[6] = {nTips="#{RGPT_240703_33}",nPoint=-200,nDetail="#{RGPT_240703_34}", },
	[7] = {nTips="#{RGPT_240703_35}",nPoint=-400,nDetail="#{RGPT_240703_36}", },
}
local g_RouGe_BossBuff3 =
{
	[1] = {nTips="#{RGPT_231130_569}",nPoint=0,nDetail="#{RGPT_231130_570}", },
	[2] = {nTips="#{RGPT_231130_571}",nPoint=100,nDetail="#{RGPT_231130_572}", },
	[3] = {nTips="#{RGPT_231130_573}",nPoint=200,nDetail="#{RGPT_231130_574}",},
	[4] = {nTips="#{RGPT_231130_575}",nPoint=400,nDetail="#{RGPT_231130_576}", },
	[5] = {nTips="#{RGPT_240703_37}",nPoint=-100,nDetail="#{RGPT_240703_38}", },
	[6] = {nTips="#{RGPT_240703_39}",nPoint=-200,nDetail="#{RGPT_240703_40}", },
	[7] = {nTips="#{RGPT_240703_41}",nPoint=-400,nDetail="#{RGPT_240703_42}", },
}
local g_RouGe_BossBuffEx2 =
{
	[1] = {nTips="#{RGPT_231130_577}",nPoint=0,nDetail="#{RGPT_231130_578}", },
	[2] = {nTips="#{RGPT_231130_579}",nPoint=100,nDetail="#{RGPT_231130_580}", },
	[3] = {nTips="#{RGPT_231130_581}",nPoint=200,nDetail="#{RGPT_231130_582}", },
	[4] = {nTips="#{RGPT_231130_583}",nPoint=400,nDetail="#{RGPT_231130_584}", },
}
local g_RouGe_BossBuffEx3 =
{
	[1] = {nTips="#{RGPT_231130_585}",nPoint=0,nDetail="#{RGPT_231130_586}", },
	[2] = {nTips="#{RGPT_231130_587}",nPoint=100,nDetail="#{RGPT_231130_588}", },
	[3] = {nTips="#{RGPT_231130_589}",nPoint=200,nDetail="#{RGPT_231130_590}", },
	[4] = {nTips="#{RGPT_231130_591}",nPoint=400,nDetail="#{RGPT_231130_592}", },
}
local g_RouGe_BossBuffEx4 =
{
	[1] = {nTips="#{RGPT_231130_593}",nPoint=0,nDetail="#{RGPT_231130_594}", },
	[2] = {nTips="#{RGPT_231130_595}",nPoint=100,nDetail="#{RGPT_231130_596}", },
	[3] = {nTips="#{RGPT_231130_597}",nPoint=200,nDetail="#{RGPT_231130_598}", },
	[4] = {nTips="#{RGPT_231130_599}",nPoint=400,nDetail="#{RGPT_231130_600}", },
}
local g_RouGe_AllBossBuff = --boss属性选择加分情况
{
	[1] = g_RouGe_BossBuff1,
	[2] = g_RouGe_BossBuff2,
	[3] = g_RouGe_BossBuff3,
	[4] = g_RouGe_BossBuffEx2,
	[5] = g_RouGe_BossBuffEx3,
	[6] = g_RouGe_BossBuffEx4,
}

--=========================================================
--PreLoad
--=========================================================
function RouGe_Ing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("ON_SCENE_TRANS",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--=========================================================
--OnLoad
--=========================================================
function RouGe_Ing_OnLoad()
	g_RouGe_Ing_Frame_UnifiedPosition = RouGe_Ing_Frame:GetProperty("UnifiedPosition");
	
	--控件
	g_RouGe_Ing_SkillList[1] = RouGe_Ing_Action1_Bak
	g_RouGe_Ing_SkillList[2] = RouGe_Ing_Action2_Bak
	g_RouGe_Ing_SkillList[3] = RouGe_Ing_Action3_Bak
	--技能
	g_RouGe_SKillBtn[1] = RouGe_Ing_Action1
	g_RouGe_SKillBtn[2] = RouGe_Ing_Action2
	g_RouGe_SKillBtn[3] = RouGe_Ing_Action3
	--boss选择信息面板
	g_RouGe_Ing_BossShowList[1] = RouGe_Ing_Client_BOSS_Text1BK
	g_RouGe_Ing_BossShowList[2] = RouGe_Ing_Client_BOSS_Text2BK
	g_RouGe_Ing_BossShowList[3] = RouGe_Ing_Client_BOSS_Text3BK
	g_RouGe_Ing_BossShowList[4] = RouGe_Ing_Client_BOSS_Text4BK
	--boss选择信息
	g_RouGe_Ing_BossSelectList[1] = RouGe_Ing_Client_BOSS_Text1
	g_RouGe_Ing_BossSelectList[2] = RouGe_Ing_Client_BOSS_Text2
	g_RouGe_Ing_BossSelectList[3] = RouGe_Ing_Client_BOSS_Text3
	g_RouGe_Ing_BossSelectList[4] = RouGe_Ing_Client_BOSS_Text4
	--boss选择信息详情
	g_RouGe_Ing_BossDetailList[1] = RouGe_Ing_Client_BOSS_Text1_1
	g_RouGe_Ing_BossDetailList[2] = RouGe_Ing_Client_BOSS_Text2_1
	g_RouGe_Ing_BossDetailList[3] = RouGe_Ing_Client_BOSS_Text3_1
	g_RouGe_Ing_BossDetailList[4] = RouGe_Ing_Client_BOSS_Text4_1	
end

--=========================================================
--恢复界面的默认相对位置
--=========================================================
function RouGe_Ing_On_ResetPos()
	RouGe_Ing_Frame:SetProperty("UnifiedPosition", g_RouGe_Ing_Frame_UnifiedPosition);

end

--=========================================================
--OnEvent
--=========================================================
function RouGe_Ing_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99894705 ) then
		--打开界面
		if(IsWindowShow("RouGe_Ing")) then
			CloseWindow("RouGe_Ing", true)
		end
		--PushDebugMessage("test  RouGe_Ing_OnEvent  参数="..Get_XParam_INT(0).." "..Get_XParam_INT(1).." "..Get_XParam_INT(2).." "..Get_XParam_INT(3))
		--PushDebugMessage("test  RouGe_Ing_OnEvent  参数2="..Get_XParam_INT(4).." "..Get_XParam_INT(5).." "..Get_XParam_INT(6).." "..Get_XParam_INT(7))
	
		if Get_XParam_INT(0) >= 0 then --第几个阶段
			RouGe_Ing_Open(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5),Get_XParam_INT(6),Get_XParam_INT(7),Get_XParam_INT(8),Get_XParam_INT(9),Get_XParam_INT(10),Get_XParam_INT(11))
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99894706 ) then
		--单纯同步排行榜时间
		--PushDebugMessage("test  RouGe_Ing_SyncTime")
		if( this:IsVisible() ) then
			RouGe_Ing_SyncTime(Get_XParam_INT(0))
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99895501 ) then
		--同步清小怪数据
		RouGe_Ing_KillMonster(Get_XParam_INT(0),Get_XParam_INT(1))	
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99895701 ) then
		--开宝箱
		RouGe_Ing_Baoxiang(Get_XParam_INT(0),Get_XParam_INT(1))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99895801 ) then
		--同步躲圈数据	
		RouGe_Ing_AddBuff(Get_XParam_INT(0),Get_XParam_INT(1))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99901301 ) then
		--同步金币数
		RouGe_Ing_JinbiCount(Get_XParam_INT(0),Get_XParam_INT(1))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99894707 ) then
		RouGe_Ing_Close()
	end
	if (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			RouGe_Ing_Close()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		RouGe_Ing_On_ResetPos();
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then	
		RouGe_Ing_On_ResetPos();
    elseif (event == "ON_SCENE_TRANS" ) then
       RouGe_Ing_Close()
    end	
end

--=========================================================
--打开界面
--=========================================================
function RouGe_Ing_Open(nStage,nBossIdx,nTime,nPoint,nSkill1,nSkill2,nSkill3,bSelect1,bSelect2,bSelect3,bSelect4,nGametime)
	g_RouGe_Stage = nStage
	g_RouGe_Ing_Time = nTime
	local nSkillList ={nSkill1,nSkill2,nSkill3}
	--技能信息
	--默认没技能
	for index=1,table.getn(g_RouGe_SKillBtn)  do
		--空技能
		g_RouGe_SKillBtn[index]:SetActionItem(-1);
		--悬浮tips
		g_RouGe_SKillBtn[index]:SetToolTip("#{RGPT_231130_167}");
		g_RouGe_Ing_SkillList[index]:Show();
	end
	local nShowIdx = 1
	for index=1,table.getn(nSkillList)  do
		if nSkillList[index] > 0 then
			local theAction = CreateRougeSkillAction(nSkillList[index]);
			--PushDebugMessage("theAction:GetID()="..theAction:GetID())
			if theAction:GetID() ~= 0 then
				theAction:SetLockStatus(1)
				g_RouGe_Ing_SkillList[nShowIdx]:Hide();
				g_RouGe_SKillBtn[nShowIdx]:SetActionItem(theAction:GetID());
				nShowIdx = nShowIdx + 1
			end
		end
	end
		
	--PushDebugMessage("test  RouGe_Ing_Timer  nSkill1="..nSkill1.." nSkill2="..nSkill2.." nSkill3="..nSkill3)
	--关卡信息
	if math.mod(g_RouGe_Stage,2) == 1 then
		--boss关卡
		local nSelectList ={bSelect1,bSelect2,bSelect3,bSelect4}
		--boss名字
		RouGe_Ing_ClientTitle:SetText(ScriptGlobal_Format("#{RGPT_231130_175}",TServerUI:GetMonsterNamebyDataID(nBossIdx)));
		--界面显隐
		RouGe_Ing_Client_BOSS:Show()
		RouGe_Ing_Client_Monster:Hide()
		--积分
		local nBasePoint = g_BossBasePoint + g_RouGe_AllBossBuff[1][bSelect1].nPoint + g_RouGe_AllBossBuff[2][bSelect2].nPoint +g_RouGe_AllBossBuff[3][bSelect3].nPoint
		--默认第四条隐藏
		for index=1,table.getn(g_RouGe_Ing_BossSelectList)  do
			g_RouGe_Ing_BossShowList[index]:Hide()
		end
		--显示
		--选中的四个boss属性
		if g_RouGe_Stage == 1 then
			for index=1,table.getn(nSelectList)  do
				if index < table.getn(nSelectList) then
					g_RouGe_Ing_BossShowList[index]:Show()
					g_RouGe_Ing_BossSelectList[index]:SetText(g_RouGe_AllBossBuff[index][nSelectList[index]].nTips);
					g_RouGe_Ing_BossDetailList[index]:SetText(g_RouGe_AllBossBuff[index][nSelectList[index]].nDetail); 
				end
			end
		elseif g_RouGe_Stage == 3 then
			for index=1,table.getn(nSelectList)  do
				if index == table.getn(nSelectList) then
					g_RouGe_Ing_BossShowList[index]:Show();
					g_RouGe_Ing_BossSelectList[index]:SetText(g_RouGe_AllBossBuff[4][nSelectList[index]].nTips);
					g_RouGe_Ing_BossDetailList[index]:SetText(g_RouGe_AllBossBuff[4][nSelectList[index]].nDetail);
				else
					g_RouGe_Ing_BossShowList[index]:Show();
					g_RouGe_Ing_BossSelectList[index]:SetText(g_RouGe_AllBossBuff[index][nSelectList[index]].nTips);
					g_RouGe_Ing_BossDetailList[index]:SetText(g_RouGe_AllBossBuff[index][nSelectList[index]].nDetail);
				end
			end
			if bSelect4 > 1 then
				nBasePoint = nBasePoint + g_RouGe_AllBossBuff[4][bSelect4].nPoint
			end
		elseif g_RouGe_Stage == 5 then
			for index=1,table.getn(nSelectList)  do
				if index == table.getn(nSelectList) then
					g_RouGe_Ing_BossShowList[index]:Show();
					g_RouGe_Ing_BossSelectList[index]:SetText(g_RouGe_AllBossBuff[5][nSelectList[index]].nTips);
					g_RouGe_Ing_BossDetailList[index]:SetText(g_RouGe_AllBossBuff[5][nSelectList[index]].nDetail);
				else
					g_RouGe_Ing_BossShowList[index]:Show();
					g_RouGe_Ing_BossSelectList[index]:SetText(g_RouGe_AllBossBuff[index][nSelectList[index]].nTips);
					g_RouGe_Ing_BossDetailList[index]:SetText(g_RouGe_AllBossBuff[index][nSelectList[index]].nDetail);
				end
			end
			if bSelect4 > 0 then
				nBasePoint = nBasePoint + g_RouGe_AllBossBuff[5][bSelect4].nPoint
			end
		elseif g_RouGe_Stage == 7 then
			for index=1,table.getn(nSelectList)  do
				if index == table.getn(nSelectList) then
					g_RouGe_Ing_BossShowList[index]:Show();
					g_RouGe_Ing_BossSelectList[index]:SetText(g_RouGe_AllBossBuff[6][nSelectList[index]].nTips);
					g_RouGe_Ing_BossDetailList[index]:SetText(g_RouGe_AllBossBuff[6][nSelectList[index]].nDetail);
				else
					g_RouGe_Ing_BossShowList[index]:Show();
					g_RouGe_Ing_BossSelectList[index]:SetText(g_RouGe_AllBossBuff[index][nSelectList[index]].nTips);
					g_RouGe_Ing_BossDetailList[index]:SetText(g_RouGe_AllBossBuff[index][nSelectList[index]].nDetail);
				end
			end
			if bSelect4 > 1 then
				nBasePoint = nBasePoint + g_RouGe_AllBossBuff[6][bSelect4].nPoint
			end
		end
		if nBasePoint < 0 then
			nBasePoint = 0
		end
		RouGe_Ing_Client_BOSS_Text5:SetText(ScriptGlobal_Format("#{RGPT_231130_176}",tostring(nBasePoint)));	
	elseif g_RouGe_Stage == 2 then
		--清小怪
		RouGe_Ing_ClientTitle:SetText("#{RGPT_231130_177}");
		--界面显隐
		RouGe_Ing_Client_BOSS:Hide()
		RouGe_Ing_Client_Monster:Show()
		--说明文字
		RouGe_Ing_Client_Monster_Text0:SetText("#{RGPT_231130_601}");
		--击杀个数
		RouGe_Ing_Client_Monster_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_178}",bSelect1));
		RouGe_Ing_Client_Monster_Text2:SetText("#{RGPT_231130_317}");
		--剩余时间
		if nGametime > 0 then
			RouGe_Ing_Client_Monster_Time:SetProperty("Timer", tostring(nGametime))
		else
			RouGe_Ing_Client_Monster_Time:SetProperty("Timer", "0")
		end
	elseif g_RouGe_Stage == 4 then
		--界面显隐
		RouGe_Ing_Client_BOSS:Hide()
		RouGe_Ing_Client_Monster:Show()
		--随机关卡
		if bSelect1 == 1 then
			--开宝箱
			RouGe_Ing_ClientTitle:SetText("#{RGPT_231130_386}");	
			RouGe_Ing_Client_Monster_Text0:SetText("#{RGPT_231130_387}");
			--剩余时间
			RouGe_Ing_Client_Monster_Text2:SetText("#{RGPT_231130_179}");
			RouGe_Ing_Client_Monster_Time:SetProperty("Timer", tostring(nGametime))
			--开宝箱
			RouGe_Ing_Client_Monster_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_624}",bSelect2));
		elseif bSelect1 == 2 then
			--躲圈
			RouGe_Ing_ClientTitle:SetText("#{RGPT_231130_602}");	
			RouGe_Ing_Client_Monster_Text0:SetText("#{RGPT_231130_388}");
			--成功躲避次数
			RouGe_Ing_Client_Monster_Text2:SetText(ScriptGlobal_Format("#{RGPT_231130_626}",bSelect2));
			--轮次
			RouGe_Ing_Client_Monster_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_625}",bSelect3));
		end
	elseif g_RouGe_Stage == 6 then
		--捡金币
		RouGe_Ing_ClientTitle:SetText("#{RGPT_231130_390}");	
		--界面显隐
		RouGe_Ing_Client_BOSS:Hide()
		RouGe_Ing_Client_Monster:Show()
		RouGe_Ing_Client_Monster_Text0:SetText("#{RGPT_231130_393}");
		--个数
		RouGe_Ing_Client_Monster_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_391}",bSelect1));
		--剩余时间
		RouGe_Ing_Client_Monster_Text2:SetText("#{RGPT_231130_392}");
		if nGametime > 0 then
			RouGe_Ing_Client_Monster_Time:SetProperty("Timer", tostring(nGametime))
		else
			RouGe_Ing_Client_Monster_Time:SetProperty("Timer", "0")
		end
	end

	--当前累计积分
	RouGe_Ing_Client2_Num1:SetText(ScriptGlobal_Format("#{RGPT_231130_165}",tostring(nPoint)));
	--当前累计时间 纯显示
	local  skyTimeString = ""
	local skyMinute = math.floor(nTime / 60)
	local skySecond = math.mod(nTime, 60)
	if skyMinute < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skyMinute) .. ":"
	if skySecond < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skySecond)
	RouGe_Ing_Client2_Time:SetText(ScriptGlobal_Format("#{RGPT_231130_166}",tostring(skyTimeString)));
	if math.mod(g_RouGe_Stage,2) == 1 then
		--PushDebugMessage("挂计时器 g_RouGe_Stage="..g_RouGe_Stage)
		--挂个计时器
		SetTimer("RouGe_Ing","RouGe_Ing_Timer()", 1000)
	end
	
	this:Show()
end

--=========================================================
--清小怪计数
--=========================================================
function RouGe_Ing_KillMonster(bKillNum,nReTime)
	--清小怪
	RouGe_Ing_ClientTitle:SetText("#{RGPT_231130_177}");
	--界面显隐
	RouGe_Ing_Client_BOSS:Hide()
	RouGe_Ing_Client_Monster:Show()
	--说明文字
	RouGe_Ing_Client_Monster_Text0:SetText("#{RGPT_231130_601}");
	--击杀个数
	RouGe_Ing_Client_Monster_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_178}",bKillNum));
	RouGe_Ing_Client_Monster_Text2:SetText("#{RGPT_231130_317}");
	--剩余时间
	if nReTime > 0 then
		RouGe_Ing_Client_Monster_Time:SetProperty("Timer", tostring(nReTime))
	else
		RouGe_Ing_Client_Monster_Time:SetProperty("Timer", "0")
	end
	
	if( this:IsVisible() == 0 ) then
		this:Show()
	end
end

--=========================================================
--开宝箱
--=========================================================
function RouGe_Ing_Baoxiang(bBaoxaingNum,nReTime)
	--界面显隐
	RouGe_Ing_Client_BOSS:Hide()
	RouGe_Ing_Client_Monster:Show()
	--开宝箱
	RouGe_Ing_ClientTitle:SetText("#{RGPT_231130_386}");	
	RouGe_Ing_Client_Monster_Text0:SetText("#{RGPT_231130_387}");
	--剩余时间
	RouGe_Ing_Client_Monster_Text2:SetText("#{RGPT_231130_179}");
	--开宝箱
	RouGe_Ing_Client_Monster_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_624}",bBaoxaingNum));

	--剩余时间
	if nReTime > 0 then
		RouGe_Ing_Client_Monster_Time:SetProperty("Timer", tostring(nReTime))
	else
		RouGe_Ing_Client_Monster_Time:SetProperty("Timer", "0")
	end
	
	if( this:IsVisible() == 0 ) then
		this:Show()
	end
end


--=========================================================
--躲圈计数
--=========================================================
function RouGe_Ing_AddBuff(bAddNum,nCount)
	--躲圈
	RouGe_Ing_ClientTitle:SetText("#{RGPT_231130_602}");	
	RouGe_Ing_Client_Monster_Text0:SetText("#{RGPT_231130_388}");
	--剩余时间
	RouGe_Ing_Client_Monster_Text2:SetText(ScriptGlobal_Format("#{RGPT_231130_626}",bAddNum));
	--次数
	RouGe_Ing_Client_Monster_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_625}",nCount));

	if( this:IsVisible() == 0 ) then
		this:Show()
	end
end



--=========================================================
--金币数
--=========================================================
function RouGe_Ing_JinbiCount(bJinbiNum,nReTime)
	--捡金币
	RouGe_Ing_ClientTitle:SetText("#{RGPT_231130_390}");	
	--界面显隐
	RouGe_Ing_Client_BOSS:Hide()
	RouGe_Ing_Client_Monster:Show()
	RouGe_Ing_Client_Monster_Text0:SetText("#{RGPT_231130_393}");
	--个数
	RouGe_Ing_Client_Monster_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_391}",bJinbiNum));
	--剩余时间
	RouGe_Ing_Client_Monster_Text2:SetText("#{RGPT_231130_392}");
	if nReTime > 0 then
		RouGe_Ing_Client_Monster_Time:SetProperty("Timer", tostring(nReTime))
	else
		RouGe_Ing_Client_Monster_Time:SetProperty("Timer", "0")
	end
	
	if( this:IsVisible() == 0 ) then
		this:Show()
	end
end

--=========================================================
--同步排行榜时间
--=========================================================
function RouGe_Ing_SyncTime(nTime)
	g_RouGe_Ing_Time = nTime	
	KillTimer("RouGe_Ing_Timer()")
	--当前累计时间
	local  skyTimeString = ""
	local skyMinute = math.floor(nTime / 60)
	local skySecond = math.mod(nTime, 60)
	if skyMinute < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skyMinute) .. ":"
	if skySecond < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skySecond)
	RouGe_Ing_Client2_Time:SetText(ScriptGlobal_Format("#{RGPT_231130_166}",tostring(skyTimeString)));
	--挂个计时器
	SetTimer("RouGe_Ing","RouGe_Ing_Timer()", 1000)
end

--=========================================================
--关闭界面
--=========================================================
function RouGe_Ing_Close()
	KillTimer("RouGe_Ing_Timer()")
	this:Hide()
end

--================================================
-- 计时界面
--================================================
function RouGe_Ing_Timer()
	if( this:IsVisible() == 0 ) then
		KillTimer("RouGe_Ing_Timer()")
	end
	--PushDebugMessage("挂计时器 回调="..g_RouGe_Ing_Time)
	KillTimer("RouGe_Ing_Timer()")
	g_RouGe_Ing_Time = g_RouGe_Ing_Time + 1
	local  skyTimeString = ""
	local skyMinute = math.floor(g_RouGe_Ing_Time / 60)
	local skySecond = math.mod(g_RouGe_Ing_Time, 60)
	if skyMinute < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skyMinute) .. ":"
	if skySecond < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skySecond)
	RouGe_Ing_Client2_Time:SetText(ScriptGlobal_Format("#{RGPT_231130_166}",skyTimeString));
	if g_RouGe_Ing_Time >= 0 then
		SetTimer("RouGe_Ing","RouGe_Ing_Timer()", 1000)
	end
end

--=========================================================
--使用技能
--=========================================================
function RouGe_Ing_UseSkill(nIndex)
	local  tmpItem = g_RouGe_SKillBtn[nIndex]:GetActionItem();
	--PushDebugMessage("nIndex="..nIndex.." tmpItem="..tmpItem)
	g_RouGe_SKillBtn[nIndex]:DoAction();
end