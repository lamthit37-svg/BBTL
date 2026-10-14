--******************************************
--新杀星副本	玩家积分界面
--create by  limengyue 
--2022-07-29
--******************************************

local g_ShaXingDaojishi_Frame_UnifiedXPosition;
local g_ShaXingDaojishi_Frame_UnifiedYPosition;

--积分MD值
local g_ShaXingDaojishi_MD = 3384
local g_ShaXingDaojishi_SelectBossIdx = -1	--当前boss索引
--备注看的  并无引用
local g_ShaXingDaojishi_BossIdxList = 
{
	[1] = {nName="宋姜"},
	[2] = {nName="卢君逸"},
	[3] = {nName="李魁"},
	[4] = {nName="鲁志生"},
	[5] = {nName="关盛"},
	[6] = {nName="吴永"},
	[7] = {nName="公孙圣"},
}
local g_ShaXingDaojishi_RandomList = 
{
	[0] = {nwarning="持续陷阱",nName="#{XSX_220705_262}"},
	[1] = {nwarning="加血圈",nName="#{XSX_220705_263}"},
	[2] = {nwarning="减治疗",nName="#{XSX_220705_264}"},
	[3] = {nwarning="吸蓝",nName="#{XSX_220705_265}"},
	[4] = {nwarning="眩晕",nName="#{XSX_220705_266}"},
	[5] = {nwarning="恐惧虚弱",nName="#{XSX_240326_13}"},
	[6] = {nwarning="心灵控制",nName="#{XSX_240326_15}"},
	[7] = {nwarning="召唤小怪",nName="#{XSX_240326_17}"},
	[8] = {nwarning="连线",nName="#{XSX_240326_19}"},
	[9] = {nwarning="炸弹",nName="#{XSX_240326_21}"},
}


--=========================================================
--PreLoad
--=========================================================
function ShaXingDaojishi_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("XINSHAXING_MINI");
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--=========================================================
--OnLoad
--=========================================================
function ShaXingDaojishi_OnLoad()
	g_ShaXingDaojishi_Frame_UnifiedXPosition	= ShaXingDaojishi : GetProperty("UnifiedXPosition");
	g_ShaXingDaojishi_Frame_UnifiedYPosition	= ShaXingDaojishi : GetProperty("UnifiedYPosition");
end

--=========================================================
--恢复界面的默认相对位置
--=========================================================
function ShaXingDaojishi_On_ResetPos()

	
	ShaXingDaojishi : SetProperty("UnifiedXPosition", g_ShaXingDaojishi_Frame_UnifiedXPosition);
	ShaXingDaojishi : SetProperty("UnifiedYPosition", g_ShaXingDaojishi_Frame_UnifiedYPosition);

end

--=========================================================
--OnEvent
--=========================================================
function ShaXingDaojishi_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 89347103 ) then
		--打开界面
		if(IsWindowShow("ShaXingDaojishi")) then
			CloseWindow("ShaXingDaojishi", true)
		end
		if(IsWindowShow("ShaXingDaojishi_Mini")) then
			CloseWindow("ShaXingDaojishi_Mini", true)
		end
		if Get_XParam_INT(0) >= 0 then --第几个boss
			ShaXingDaojishi_Open(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5))
		end
	end
	-- 窗口变化
	if (event == "XINSHAXING_MINI" ) then
		if arg0=="1" then
			ShaXingDaojishi_Mini_Show(tonumber(arg1))
		end
	end
	if (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		ShaXingDaojishi_On_ResetPos();
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then	
		ShaXingDaojishi_On_ResetPos();
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       ShaXingDaojishi_Close()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end	
end

--=========================================================
--打开界面
--=========================================================
function ShaXingDaojishi_Open(nSelectBossIdx,nBossIdx,nPoint,nRandomList,bRandomChoice, nMode)
	g_ShaXingDaojishi_SelectBossIdx = nSelectBossIdx
	--关卡信息
	local nGuanqia = "一"
	if nSelectBossIdx == 2 then
		nGuanqia = "二"
	elseif nSelectBossIdx == 3 then
		nGuanqia = "三"
	elseif nSelectBossIdx == 4 then
		nGuanqia = "四"
	end
	ShaXingDaojishi_DragTitle:SetText(ScriptGlobal_Format("#{XSX_220705_111}",nGuanqia));
	
	--当前累计积分
	local nMDPoint = DataPool:GetPlayerMission_DataRound(g_ShaXingDaojishi_MD)
	ShaXingDaojishi_Score:SetText(ScriptGlobal_Format("#{XSX_220705_119}",tostring(nMDPoint)));
	--目标
	ShaXingDaojishi_Text:SetText(ScriptGlobal_Format("#{XSX_220705_112}",g_ShaXingDaojishi_BossIdxList[nBossIdx].nName));
	--通关奖励
	ShaXingDaojishi_Text2:SetText(ScriptGlobal_Format("#{XSX_220705_117}",tostring(nPoint)));
	--场地信息
	local g_ShaXing_RandomIdxList={1,2,3,4,6,8}--6个场地元素索引（服务器随机）
	g_ShaXing_RandomIdxList[1] = math.mod(nRandomList,10)
	g_ShaXing_RandomIdxList[2] = math.floor(math.mod(nRandomList,100)/10)  
	g_ShaXing_RandomIdxList[3] = math.floor(math.mod(nRandomList,1000)/100)  
	g_ShaXing_RandomIdxList[4] = math.floor(math.mod(nRandomList,10000)/1000) 
	g_ShaXing_RandomIdxList[5] = math.floor(math.mod(nRandomList,100000)/10000) 
	g_ShaXing_RandomIdxList[6] = math.floor(math.mod(nRandomList,1000000)/100000) 
	
	local bRandom1 = math.mod(bRandomChoice,10)
	local bRandom2 = math.floor(math.mod(bRandomChoice,100)/10)  
	local bRandom3 = math.floor(math.mod(bRandomChoice,1000)/100)  
	local bRandom4 = math.floor(math.mod(bRandomChoice,10000)/1000) 
	local bRandom5 = math.floor(math.mod(bRandomChoice,100000)/10000) 
	local bRandom6 = math.floor(math.mod(bRandomChoice,1000000)/100000) 
		
	local nRandomMSg = ""
	if bRandom1 > 0 then
		if nMode == 4 then
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[1]].nName..ScriptGlobal_Format("#{XSX_240326_110}",bRandom1).." "
		else
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[1]].nName.." "
		end
	end
	if bRandom2 > 0 then
		if nMode == 4 then
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[2]].nName..ScriptGlobal_Format("#{XSX_240326_110}",bRandom2).." "
		else
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[2]].nName.." "
		end
	end
	if bRandom3 > 0 then
		if nMode == 4 then
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[3]].nName..ScriptGlobal_Format("#{XSX_240326_110}",bRandom3).." "
		else
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[3]].nName.." "
		end
	end
	if bRandom4 > 0 then
		if nMode == 4 then
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[4]].nName..ScriptGlobal_Format("#{XSX_240326_110}",bRandom4).." "
		else
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[4]].nName.." "
		end
	end	
	if bRandom5 > 0 then
		if nMode == 4 then
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[5]].nName..ScriptGlobal_Format("#{XSX_240326_110}",bRandom5).." "
		else
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[5]].nName.." "
		end
	end	
	if bRandom6 > 0 then
		if nMode == 4 then
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[6]].nName..ScriptGlobal_Format("#{XSX_240326_110}",bRandom6).." "
		else
			nRandomMSg=nRandomMSg..g_ShaXingDaojishi_RandomList[g_ShaXing_RandomIdxList[6]].nName.." "
		end
	end	
	--PushDebugMessage("test name="..nRandomMSg);
	--名字为空时候显示暂无
	if nRandomMSg == "" then
		nRandomMSg = "#{XSX_220705_281}"
	end
	
	ShaXingDaojishi_Text4:SetText(nRandomMSg);
	this:Show()
end
--=========================================================
--关闭界面
--=========================================================
function ShaXingDaojishi_Close()

end
--=========================================================
--切换到mini
--=========================================================
function ShaXingDaojishi_OpenMini()

	this:Hide()
	PushEvent("XINSHAXING_MINI",0,g_ShaXingDaojishi_SelectBossIdx)
end