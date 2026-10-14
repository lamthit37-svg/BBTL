--******************************************
--新杀星副本	boss选择界面
--create by  limengyue 
--2022-07-28
--******************************************

local g_ShaXing_BossChoice_Frame_UnifiedPosition;
--关心NPc
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1

local g_BossBarList		= {} --boss属性可选列表
local g_RandomBarList		= {} --boss属性可选列表
local g_ShaXing_BossChoice_Fenye = {}	--四个boss选择分页
local g_ShaXing_BossChoice_FenyeOk = {}	--四个boss 是否通关标记
local g_ShaXing_BossChoice_FenyeAbandon = {}	--四个boss 是否通关标记
local g_ShaXing_BossChoice_BossModeList = {}	--4个boss模式选择

local g_SXBossImg =	--boss难度不同图片
{
	[1] = {nName="宋姜",nEasyPoint=1000,nNormalPoint=1000,nHardPoint=1000,nMaxPoint=1000,nEasyTips="#{XSX_220705_277}",nNormalTips="#{XSX_220705_278}",nHardTips="#{XSX_220705_279}",nMaxTips="#{XSX_240326_107}",nEasyImg="set:ShaXing12 image:ShaXing_sj1",nNormalImg="set:ShaXing12 image:ShaXing_sj2",nHardImg="set:ShaXing13 image:ShaXing_sj3",nMaxImg="set:ShaXing13 image:ShaXing_sj4"},
	[2] = {nName="卢君逸",nEasyPoint=1000,nNormalPoint=1000,nHardPoint=1000,nMaxPoint=1000,nEasyTips="#{XSX_220705_277}",nNormalTips="#{XSX_220705_278}",nHardTips="#{XSX_220705_279}",nMaxTips="#{XSX_240326_107}",nEasyImg="set:ShaXing6 image:ShaXing_ljy1",nNormalImg="set:ShaXing6 image:ShaXing_ljy2",nHardImg="set:ShaXing7 image:ShaXing_ljy3",nMaxImg="set:ShaXing7 image:ShaXing_ljy4"},
	[3] = {nName="李魁",nEasyPoint=1000,nNormalPoint=1000,nHardPoint=1000,nMaxPoint=1000,nEasyTips="#{XSX_220705_277}",nNormalTips="#{XSX_220705_278}",nHardTips="#{XSX_220705_279}",nMaxTips="#{XSX_240326_107}",nEasyImg="set:ShaXing8 image:ShaXing_lk1",nNormalImg="set:ShaXing8 image:ShaXing_lk2",nHardImg="set:ShaXing9 image:ShaXing_lk3",nMaxImg="set:ShaXing9 image:ShaXing_lk4"},
	[4] = {nName="鲁志生",nEasyPoint=1000,nNormalPoint=1000,nHardPoint=1000,nMaxPoint=1000,nEasyTips="#{XSX_220705_277}",nNormalTips="#{XSX_220705_278}",nHardTips="#{XSX_220705_279}",nMaxTips="#{XSX_240326_107}",nEasyImg="set:ShaXing10 image:ShaXing_lzs1",nNormalImg="set:ShaXing10 image:ShaXing_lzs2",nHardImg="set:ShaXing11 image:ShaXing_lzs3",nMaxImg="set:ShaXing11 image:ShaXing_lzs4"},
	[5] = {nName="关盛",nEasyPoint=1000,nNormalPoint=1000,nHardPoint=1000,nMaxPoint=1000,nEasyTips="#{XSX_220705_277}",nNormalTips="#{XSX_220705_278}",nHardTips="#{XSX_220705_279}",nMaxTips="#{XSX_240326_107}",nEasyImg="set:ShaXing2 image:ShaXing_gs1",nNormalImg="set:ShaXing2 image:ShaXing_gs2",nHardImg="set:ShaXing3 image:ShaXing_gs3",nMaxImg="set:ShaXing3 image:ShaXing_gs4"},
	[6] = {nName="吴永",nEasyPoint=1000,nNormalPoint=1000,nHardPoint=1000,nMaxPoint=1000,nEasyTips="#{XSX_220705_277}",nNormalTips="#{XSX_220705_278}",nHardTips="#{XSX_220705_279}",nMaxTips="#{XSX_240326_107}",nEasyImg="set:ShaXing14 image:ShaXing_wy1",nNormalImg="set:ShaXing14 image:ShaXing_wy2",nHardImg="set:ShaXing15 image:ShaXing_wy3",nMaxImg="set:ShaXing15 image:ShaXing_wy4"},
	[7] = {nName="公孙圣",nEasyPoint=1000,nNormalPoint=1000,nHardPoint=1000,nMaxPoint=1000,nEasyTips="#{XSX_220705_277}",nNormalTips="#{XSX_220705_278}",nHardTips="#{XSX_220705_279}",nMaxTips="#{XSX_240326_107}",nEasyImg="set:ShaXing4 image:ShaXing_gss1",nNormalImg="set:ShaXing4 image:ShaXing_gss2",nHardImg="set:ShaXing5 image:ShaXing_gss3",nMaxImg="set:ShaXing5 image:ShaXing_gss4"},
}
local g_SXBossBuffInfo = --boss属性选择加分情况
{
	[1] = {nwarning="不吃放大",nName="#{XSX_220705_289}",nImg="set:FBSkill_4 image:FBSkill_4_1",nPoint={[0] =0,[1] =350,[2] =400,[3] =400},nTooltip="#{XSX_220705_256}",nTooltip2="#{XSX_240326_79}"},
	[2] = {nwarning="吸血",nName="#{XSX_220705_290}",nImg="set:FBSkill_4 image:FBSkill_4_3",nPoint={[0] =0,[1] =200,[2] =250,[3] =250},nTooltip="#{XSX_220705_257}",nTooltip2="#{XSX_240326_80}"},
	[3] = {nwarning="技能加快",nName="#{XSX_220705_291}",nImg="set:FBSkill_4 image:FBSkill_4_2",nPoint={[0] =0,[1] =350,[2] =400,[3] =400},nTooltip="#{XSX_220705_258}",nTooltip2="#{XSX_240326_81}"},
	[4] = {nwarning="狂暴",nName="#{XSX_220705_292}",nImg="set:FBSkill_4 image:FBSkill_4_4",nPoint={[0] =0,[1] =300,[2] =350,[3] =350},nTooltip="#{XSX_220705_259}",nTooltip2="#{XSX_240326_82}"},
	[5] = {nwarning="虚弱打击",nName="#{XSX_240326_1}",nImg="set:FBSkill_4 image:FBSkill_4_12",nPoint={[0] =0,[1] =200,[2] =250,[3] =250},nTooltip="#{XSX_240326_10}",nTooltip2="#{XSX_240326_83}"},
	[6] = {nwarning="复仇护盾",nName="#{XSX_240326_2}",nImg="set:FBSkill_4 image:FBSkill_4_16",nPoint={[0] =0,[1] =250,[2] =300,[3] =300},nTooltip="#{XSX_240326_11}",nTooltip2="#{XSX_240326_84}"},
	[7] = {nwarning="攻击强化",nName="#{XSX_240326_3}",nImg="set:FBSkill_4 image:FBSkill_4_15",nPoint={[0] =0,[1] =300,[2] =350,[3] =350},nTooltip="#{XSX_240326_12}",nTooltip2="#{XSX_240326_85}"},
}

local g_SXRandomInfo = --不同场地元素图片
{
	[0] = {nwarning="持续陷阱",nName="#{XSX_220705_262}",nImg="set:FBSkill_4 image:FBSkill_4_6",nPoint={[0] =0,[1] =300,[2] =350,[3] =350},nTooltip="#{XSX_220705_267}",nTooltip2="#{XSX_240326_86}"},
	[1] = {nwarning="加血圈",nName="#{XSX_220705_263}",nImg="set:FBSkill_4 image:FBSkill_4_8",nPoint={[0] =0,[1] =150,[2] =200,[3] =200},nTooltip="#{XSX_220705_268}",nTooltip2="#{XSX_240326_87}"},
	[2] = {nwarning="减治疗",nName="#{XSX_220705_264}",nImg="set:FBSkill_4 image:FBSkill_4_5",nPoint={[0] =0,[1] =200,[2] =250,[3] =250},nTooltip="#{XSX_220705_269}",nTooltip2="#{XSX_240326_88}"},
	[3] = {nwarning="吸蓝",nName="#{XSX_220705_265}",nImg="set:FBSkill_4 image:FBSkill_4_9",nPoint={[0] =0,[1] =150,[2] =200,[3] =200},nTooltip="#{XSX_220705_270}",nTooltip2="#{XSX_240326_89}"},
	[4] = {nwarning="眩晕",nName="#{XSX_220705_266}",nImg="set:FBSkill_4 image:FBSkill_4_7",nPoint={[0] =0,[1] =250,[2] =300,[3] =300},nTooltip="#{XSX_220705_271}",nTooltip2="#{XSX_240326_90}"},
	[5] = {nwarning="恐惧虚弱",nName="#{XSX_240326_13}",nImg="set:FBSkill_4 image:FBSkill_4_11",nPoint={[0] =0,[1] =200,[2] =250,[3] =250},nTooltip="#{XSX_240326_14}",nTooltip2="#{XSX_240326_91}"},
	[6] = {nwarning="心灵控制",nName="#{XSX_240326_15}",nImg="set:FBSkill_3 image:FBSkill_3_4",nPoint={[0] =0,[1] =250,[2] =300,[3] =300},nTooltip="#{XSX_240326_16}",nTooltip2="#{XSX_240326_92}"},
	[7] = {nwarning="召唤小怪",nName="#{XSX_240326_17}",nImg="set:FBSkill_3 image:FBSkill_3_3",nPoint={[0] =0,[1] =250,[2] =300,[3] =300},nTooltip="#{XSX_240326_18}",nTooltip2="#{XSX_240326_93}"},
	[8] = {nwarning="连线",nName="#{XSX_240326_19}",nImg="set:FBSkill_4 image:FBSkill_4_13",nPoint={[0] =0,[1] =300,[2] =350,[3] =350},nTooltip="#{XSX_240326_20}",nTooltip2="#{XSX_240326_94}"},
	[9] = {nwarning="炸弹",nName="#{XSX_240326_21}",nImg="set:FBSkill_4 image:FBSkill_4_14",nPoint={[0] =0,[1] =300,[2] =350,[3] =350},nTooltip="#{XSX_240326_22}",nTooltip2="#{XSX_240326_95}"},
}
local g_ShaXing_ModeMaxNum = 4	--最大难度个数
local g_ShaXing_CloseTick = 1	--倒计时
local g_ShaXing_FenyeIdx = -1	--第几个分页
local g_ShaXing_FenyeBossIdx = -1	--当前副本第几个boss索引
local g_SXBossCheck = {0,0,0,0,0,0,0}--7个boss状态选择情况
local g_SXRandomCheck = {0,0,0,0,0,0}--6个场地元素选择情况
local g_SXRandomIdxList = {1,2,3,4,6,8}--6个场地元素索引（服务器随机）
local g_SXBossAbandon = {0,0,0,0}--boss放弃情况
local g_ShaXing_targetId = -1;
--===============================================
-- OnLoad()
--===============================================
function ShaXing_BossChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
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
function ShaXing_BossChoice_OnLoad()   
	-- 保存界面的默认相对位置
	g_ShaXing_BossChoice_Frame_UnifiedPosition = ShaXing_BossChoice_Frame:GetProperty("UnifiedPosition");

	--控件
	--boss选择分页
	g_ShaXing_BossChoice_Fenye[1] = ShaXing_BossChoice_Boss1
	g_ShaXing_BossChoice_Fenye[2] = ShaXing_BossChoice_Boss2
	g_ShaXing_BossChoice_Fenye[3] = ShaXing_BossChoice_Boss3
	g_ShaXing_BossChoice_Fenye[4] = ShaXing_BossChoice_Boss4
	--是否通关标记
	g_ShaXing_BossChoice_FenyeOk[1] = ShaXing_BossChoice_Boss1_Ok
	g_ShaXing_BossChoice_FenyeOk[2] = ShaXing_BossChoice_Boss2_Ok
	g_ShaXing_BossChoice_FenyeOk[3] = ShaXing_BossChoice_Boss3_Ok
	g_ShaXing_BossChoice_FenyeOk[4] = ShaXing_BossChoice_Boss4_Ok
	g_ShaXing_BossChoice_FenyeAbandon[1] = ShaXing_BossChoice_Boss1_Abandon
	g_ShaXing_BossChoice_FenyeAbandon[2] = ShaXing_BossChoice_Boss2_Abandon
	g_ShaXing_BossChoice_FenyeAbandon[3] = ShaXing_BossChoice_Boss3_Abandon
	g_ShaXing_BossChoice_FenyeAbandon[4] = ShaXing_BossChoice_Boss4_Abandon	
	--三个boss模式选择
	g_ShaXing_BossChoice_BossModeList[1] = ShaXing_BossChoiceModel_Bind
	g_ShaXing_BossChoice_BossModeList[2] = ShaXing_BossChoiceModel_Bind2
	g_ShaXing_BossChoice_BossModeList[3] = ShaXing_BossChoiceModel_Bind3
	g_ShaXing_BossChoice_BossModeList[4] = ShaXing_BossChoiceModel_Bind4
	
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function ShaXing_BossChoice_Frame_On_ResetPos()
	ShaXing_BossChoice_Frame:SetProperty("UnifiedPosition", g_ShaXing_BossChoice_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function ShaXing_BossChoice_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 89347101) then
		--打开界面
		if(IsWindowShow("ShaXing_BossChoice")) then
			CloseWindow("ShaXing_BossChoice", true)
		end
		--添加NPC关心 不需要
		g_ShaXing_targetId = Get_XParam_INT(0)
		-- if g_ShaXing_targetId >= 0 then
			-- objCared = DataPool : GetNPCIDByServerID(g_ShaXing_targetId);
			-- ShaXing_BossChoice_BeginCareObject(objCared)
		-- end
		if Get_XParam_INT(1) > 0 then --第几个boss
			ShaXing_BossChoice_Open(Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5))
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89347104 ) then
		--PushDebugMessage("test idx="..Get_XParam_INT(1))
		if Get_XParam_INT(1) > 0 then --第几个boss
			ShaXing_BossChoice_OpenFenye(Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5),Get_XParam_INT(6),Get_XParam_INT(7),Get_XParam_INT(8),Get_XParam_INT(9))
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89347106 ) then
		--预告界面
		--PushDebugMessage("test 预告界面IDx="..Get_XParam_INT(1))
		if Get_XParam_INT(0) > 0 then --第几个boss
			ShaXing_BossChoice_JustShow(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5),Get_XParam_INT(6))
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89347102 ) then
		--开怪成功 关闭窗口
		ShaXing_BossChoice_OnClose()
	end
	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			ShaXing_BossChoice_OnClose()
		end
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		ShaXing_BossChoice_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ShaXing_BossChoice_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       ShaXing_BossChoice_OnClose()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end
         
end

--===============================================
-- ShaXing_BossChoice_OnClose()
--===============================================
function ShaXing_BossChoice_OnClose()
	--ShaXing_BossChoice_StopCareObject()
	KillTimer("ShaXing_BossChoice_CloseWindow()")
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function ShaXing_BossChoice_BeginCareObject(objCaredId)
	-- if g_Object ~= -1 then
		-- this:CareObject(objCaredId, 0, "ShaXing_BossChoice");
	-- end
	-- g_Object = objCaredId
	-- this:CareObject(g_Object, 1, "ShaXing_BossChoice")
end


--=========================================================
--停止对某NPC的关心
--=========================================================
function ShaXing_BossChoice_StopCareObject()
	-- if g_Object ~= -1 then
		-- this:CareObject(g_Object, 0, "ShaXing_BossChoice");
		-- g_Object = -1;
	-- end
end
--=========================================================
--help
--=========================================================
function ShaXing_BossChoice_Help()

end

--=========================================================
--默认打开界面
--nSelectIdx 选的第几个boss
--nBossIdx boss索引
--nRandomList本期场地元素列表 需要拆分
--=========================================================
function ShaXing_BossChoice_Open(nSelectIdx,nBossIdx,nBossAbandonList,nRandomList,bLeader)
	if nSelectIdx < 1 or nSelectIdx > 4 then
		return
	end
	--设置参数
	g_ShaXing_FenyeIdx = nSelectIdx
	g_ShaXing_FenyeBossIdx = nBossIdx
	
	--PushDebugMessage("test ShaXing_BossChoiceModel_open nSelectIdx="..nSelectIdx.." nBossIdx="..nBossIdx.." nRandomList="..nRandomList)

	--选中当前boss分页
	for index=1,table.getn(g_ShaXing_BossChoice_Fenye)  do
		if index == g_ShaXing_FenyeIdx then
			g_ShaXing_BossChoice_Fenye[index]:SetCheck(1);
		else
			g_ShaXing_BossChoice_Fenye[index]:SetCheck(0);
		end
		if index > g_ShaXing_FenyeIdx then
			g_ShaXing_BossChoice_Fenye[index]:Disable();
		else
			g_ShaXing_BossChoice_Fenye[index]:Enable();
		end
		
	end
	--boss放弃情况
	--PushDebugMessage("test ShaXing_BossChoiceModel_open nBossAbandonList="..nBossAbandonList)
	g_SXBossAbandon[1] = math.mod(nBossAbandonList,10)
	g_SXBossAbandon[2] = math.floor(math.mod(nBossAbandonList,100)/10)  
	g_SXBossAbandon[3] = math.floor(math.mod(nBossAbandonList,1000)/100)  
	g_SXBossAbandon[4] = math.floor(math.mod(nBossAbandonList,10000)/1000) 
	
	--是否通关标记
	for index=1,table.getn(g_ShaXing_BossChoice_FenyeAbandon)  do
		if index <  g_ShaXing_FenyeIdx then
			if g_SXBossAbandon[index] == 1 then
				g_ShaXing_BossChoice_FenyeOk[index]:Hide();
				g_ShaXing_BossChoice_FenyeAbandon[index]:Show();
			else
				g_ShaXing_BossChoice_FenyeOk[index]:Show();
				g_ShaXing_BossChoice_FenyeAbandon[index]:Hide();
			end
		else
			g_ShaXing_BossChoice_FenyeOk[index]:Hide();
			g_ShaXing_BossChoice_FenyeAbandon[index]:Hide();
		end	
		
	end
	
	--boss模式默认选简单	
	--展示boss 默认展示难度1
	ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nEasyImg )
	for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
		if index == 1 then
			g_ShaXing_BossChoice_BossModeList[index]:SetCheck(1);
		else
			g_ShaXing_BossChoice_BossModeList[index]:SetCheck(0);
		end
	end
	ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nEasyTips);
	ShaXing_BossChoice_Text:Hide()
	--场地元素信息
	--PushDebugMessage("test ShaXing_BossChoice nRandomList="..nRandomList)
	g_SXRandomIdxList[1] = math.mod(nRandomList,10)
	g_SXRandomIdxList[2] = math.floor(math.mod(nRandomList,100)/10)  
	g_SXRandomIdxList[3] = math.floor(math.mod(nRandomList,1000)/100)  
	g_SXRandomIdxList[4] = math.floor(math.mod(nRandomList,10000)/1000) 
	g_SXRandomIdxList[5] = math.floor(math.mod(nRandomList,100000)/10000)
	g_SXRandomIdxList[6] = math.floor(math.mod(nRandomList,1000000)/100000)
	--默认难度1 重置数据 可选
	ShaXing_BossChoice_ShowAll(1,1,1,0,0,0)

	--难度可选
	for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
		g_ShaXing_BossChoice_BossModeList[index]:Enable();
	end

	--队长显示
	if bLeader == 1 then
		ShaXing_BossChoice_ActionFrame:Show()
		ShaXing_BossChoice_ActionFrame2:Hide()
	else
		ShaXing_BossChoice_ActionFrame:Hide()
		ShaXing_BossChoice_ActionFrame2:Show()
		ShaXing_BossChoice_ActionFrame2_Text:SetText("#{XSX_220705_360}");
	end
	--动画重置
	KillTimer("ShaXing_BossChoice_CloseWindow()")
	this:Show()
end

--=========================================================
--不同难度展示区不一样
--nBossMode 难度模式  
--nIsReset 是否重置
--nIsEnable 按钮是否可选
--nIsUseList 是否使用传入数据
--nBossChoiceList 当前boss选择
--nRandomChoiceList 当前场地元素选择
--=========================================================
function ShaXing_BossChoice_ShowAll(nBossMode,nIsReset,nIsEnable,nIsUseList,nBossChoiceList,nRandomChoiceList)
	--boss加成选择
	--PushDebugMessage("test  nBossChoiceList="..nBossChoiceList)
	local g_BossChoiceList = {0,0,0,0,0,0,0}
	if nIsUseList == 1 then
		g_BossChoiceList[1] = math.mod(nBossChoiceList,10)
		g_BossChoiceList[2] = math.floor(math.mod(nBossChoiceList,100)/10)  
		g_BossChoiceList[3] = math.floor(math.mod(nBossChoiceList,1000)/100)
		g_BossChoiceList[4] = math.floor(math.mod(nBossChoiceList,10000)/1000) 
		g_BossChoiceList[5] = math.floor(math.mod(nBossChoiceList,100000)/10000) 
		g_BossChoiceList[6] = math.floor(math.mod(nBossChoiceList,1000000)/100000) 
		g_BossChoiceList[7] = math.floor(math.mod(nBossChoiceList,10000000)/1000000) 
	end
	if nIsReset == 1 then
		g_SXBossCheck = {0,0,0,0,0,0,0}--7个boss状态选择情况
		g_SXRandomCheck = {0,0,0,0,0,0}--6个场地元素选择情况
	end 
	
	--场地元素选择
	local g_RandomChoiceList = {0,0,0,0,0,0}
	--PushDebugMessage("test  g_RandomChoiceList="..nRandomChoiceList)
	if nIsUseList == 1 then
		g_RandomChoiceList[1] = math.mod(nRandomChoiceList,10)
		g_RandomChoiceList[2] = math.floor(math.mod(nRandomChoiceList,100)/10)  
		g_RandomChoiceList[3] = math.floor(math.mod(nRandomChoiceList,1000)/100)  
		g_RandomChoiceList[4] = math.floor(math.mod(nRandomChoiceList,10000)/1000) 
		g_RandomChoiceList[5] = math.floor(math.mod(nRandomChoiceList,100000)/10000) 
		g_RandomChoiceList[6] = math.floor(math.mod(nRandomChoiceList,1000000)/100000) 
	end
	
	--PushDebugMessage("test 前三个选项 A="..g_SXBossCheck[1].." B="..g_SXBossCheck[2].." C="..g_SXBossCheck[3])
	if nBossMode < g_ShaXing_ModeMaxNum then
		--前三个难度展示模式
		ShaXing_BossChoice_Right1:Show();
		ShaXing_BossChoice_Right2:Hide();
		g_BossBarList		= {} --boss属性可选列表
		g_RandomBarList		= {} --boss属性可选列表
		--boss属性扩展区
		ShaXing_BossChoice_Add1Frame_List:Clear()
		--加载不同个数
		local nBossMaxItemNum = 4
		if nBossMode == 2 then
			nBossMaxItemNum = 6
		elseif nBossMode == 3 then
			nBossMaxItemNum = 7
		end
		for i = 1, nBossMaxItemNum do
			local bar = ShaXing_BossChoice_Add1Frame_List:AddChild("ShaXing_BossChoice_Add1Frame_Gift1")
			-- 填充信息
			bar:GetSubItem("ShaXing_BossChoice_Add1"):Enable() --可选
			bar:GetSubItem("ShaXing_BossChoice_Add1"):SetCheck(0) --未选中
			--悬浮tips
			bar:GetSubItem("ShaXing_BossChoice_Add1"):SetToolTip(g_SXBossBuffInfo[i].nTooltip);
			bar:GetSubItem("ShaXing_BossChoice_Add1"):SetEvent("Clicked", string.format("ShaXing_BossChoice_BossClicked(%d,%d)",1, i))

			--非展示界面
			bar:GetSubItem("ShaXing_BossChoice_Add1_Mask"):Hide()	
			--属性名
			bar:GetSubItem("ShaXing_BossChoice_Add1Text"):SetText(g_SXBossBuffInfo[i].nName);
			--图片
			bar:GetSubItem("ShaXing_BossChoice_Add1Image"):SetProperty("Image",g_SXBossBuffInfo[i].nImg);
			--分数
			bar:GetSubItem("ShaXing_BossChoice_Add1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_255}",tostring(g_SXBossBuffInfo[i].nPoint[1])));
			if nIsReset < 1 then
				--非重置直接读数据
				if nIsUseList == 1 then
					if g_BossChoiceList[i] > 0 then
						bar:GetSubItem("ShaXing_BossChoice_Add1"):SetCheck(1) --选中
						--分数
						bar:GetSubItem("ShaXing_BossChoice_Add1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXBossBuffInfo[i].nPoint[1])));
					end
				else
					if g_SXBossCheck[i] > 0 then
						bar:GetSubItem("ShaXing_BossChoice_Add1"):SetCheck(1) --选中
						--分数
						bar:GetSubItem("ShaXing_BossChoice_Add1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXBossBuffInfo[i].nPoint[1])));
					end
				end
			end
			if nIsEnable < 1 then
				bar:GetSubItem("ShaXing_BossChoice_Add1"):Disable() --不可选
			end
			table.insert(g_BossBarList, bar)
		end

		--场地元素区域
		ShaXing_BossChoice_Place1Frame_List:Clear()
		--加载不同个数
		local nRandomMaxItemNum = 4
		if nBossMode == 2 then
			nRandomMaxItemNum = 5
		elseif nBossMode == 3 then
			nRandomMaxItemNum = 6
		end
		for i = 1, nRandomMaxItemNum do
			local bar = ShaXing_BossChoice_Place1Frame_List:AddChild("ShaXing_BossChoice_Place1Frame_Gift1")
			-- 填充信息
			local nCurRandomIdx = g_SXRandomIdxList[i]
			-- 填充信息
			bar:GetSubItem("ShaXing_BossChoice_Place1"):Enable() --可选
			bar:GetSubItem("ShaXing_BossChoice_Place1"):SetCheck(0) --未选中
			--悬浮tips
			bar:GetSubItem("ShaXing_BossChoice_Place1"):SetToolTip(g_SXRandomInfo[nCurRandomIdx].nTooltip);
			bar:GetSubItem("ShaXing_BossChoice_Place1"):SetEvent("Clicked", string.format("ShaXing_BossChoice_RandomClicked(%d,%d)",1, i))
			--未选中不显示高亮
			bar:GetSubItem("ShaXing_BossChoice_Place1_Mask"):Hide()	
			--属性名
			bar:GetSubItem("ShaXing_BossChoice_Place1Text"):SetText(g_SXRandomInfo[nCurRandomIdx].nName);
			--图片
			bar:GetSubItem("ShaXing_BossChoice_Place1Image"):SetProperty("Image",g_SXRandomInfo[nCurRandomIdx].nImg);
			--分数
			bar:GetSubItem("ShaXing_BossChoice_Place1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_255}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));
			if nIsReset < 1 then
				--非重置直接读数据
				if nIsUseList == 1 then
					if g_RandomChoiceList[i] > 0 then
						bar:GetSubItem("ShaXing_BossChoice_Place1"):SetCheck(1) --选中
						--分数
						bar:GetSubItem("ShaXing_BossChoice_Place1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));
					end
				else
					if g_SXRandomCheck[i] > 0 then
						bar:GetSubItem("ShaXing_BossChoice_Place1"):SetCheck(1) --选中
						--分数
						bar:GetSubItem("ShaXing_BossChoice_Place1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));
					end
				end
			end
			if nIsEnable < 1 then
				bar:GetSubItem("ShaXing_BossChoice_Place1"):Disable() --不可选
			end
			table.insert(g_RandomBarList, bar)
		end
	else
		--最后一个模式特殊处理
		ShaXing_BossChoice_Right1:Hide();
		ShaXing_BossChoice_Right2:Show();
		g_BossBarList		= {} --boss属性可选列表
		g_RandomBarList		= {} --boss属性可选列表
		--boss属性扩展区
		ShaXing_BossChoice_Add2Frame_List:Clear()
		--加载不同个数
		local nBossMaxItemNum = 7
		for i = 1, nBossMaxItemNum do
			local bar = ShaXing_BossChoice_Add2Frame_List:AddChild("ShaXing_BossChoice_Add2Frame_Gift1")
			-- 填充信息
			bar:GetSubItem("ShaXing_BossChoice_Add2"):Enable() --可选
			bar:GetSubItem("ShaXing_BossChoice_Add2"):SetCheck(0) --未选中
			--悬浮tips
			bar:GetSubItem("ShaXing_BossChoice_Add2"):SetToolTip(g_SXBossBuffInfo[i].nTooltip);
			bar:GetSubItem("ShaXing_BossChoice_Add2"):SetEvent("Clicked", string.format("ShaXing_BossChoice_BossClicked(%d,%d)",2, i))

			--未选中不显示高亮
			bar:GetSubItem("ShaXing_BossChoice_Add2_Mask"):Hide()	
			--属性名
			bar:GetSubItem("ShaXing_BossChoice_Add2Text"):SetText(g_SXBossBuffInfo[i].nName);
			--图片
			bar:GetSubItem("ShaXing_BossChoice_Add2Image"):SetProperty("Image",g_SXBossBuffInfo[i].nImg);
			--分数
			bar:GetSubItem("ShaXing_BossChoice_Add2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_255}",tostring(g_SXBossBuffInfo[i].nPoint[1])));
			--下拉列表
			bar:GetSubItem("ShaXing_BossChoice_Add2_select"):Enable()
			bar:GetSubItem("ShaXing_BossChoice_Add2_select"):ResetList()
			bar:GetSubItem("ShaXing_BossChoice_Add2_select"):SetEvent("ListSelectionAccepted", string.format("ShaXing_BossChoice_BossSelecCK(%d)", i))
			bar:GetSubItem("ShaXing_BossChoice_Add2_select"):AddTextItem("等级1", 0)
			bar:GetSubItem("ShaXing_BossChoice_Add2_select"):AddTextItem("等级2", 1)
			bar:GetSubItem("ShaXing_BossChoice_Add2_select"):SetCurrentSelect(0)
			if nIsReset < 1 then
				--非重置直接读数据
				if nIsUseList == 1 then
					if g_BossChoiceList[i] > 0 then
						bar:GetSubItem("ShaXing_BossChoice_Add2"):SetCheck(1) --选中
						--分数
						bar:GetSubItem("ShaXing_BossChoice_Add2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXBossBuffInfo[i].nPoint[g_SXBossCheck[i]])));
						if g_BossChoiceList[i] > 1 then
							bar:GetSubItem("ShaXing_BossChoice_Add2"):SetToolTip(g_SXBossBuffInfo[i].nTooltip2);
							bar:GetSubItem("ShaXing_BossChoice_Add2_select"):SetCurrentSelect(1)
						end					
					end
				else
					if g_SXBossCheck[i] > 0 then
						bar:GetSubItem("ShaXing_BossChoice_Add2"):SetCheck(1) --选中
						--分数
						bar:GetSubItem("ShaXing_BossChoice_Add2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXBossBuffInfo[i].nPoint[g_SXBossCheck[i]])));
						if g_SXBossCheck[i] > 1 then
							bar:GetSubItem("ShaXing_BossChoice_Add2"):SetToolTip(g_SXBossBuffInfo[i].nTooltip2);
							bar:GetSubItem("ShaXing_BossChoice_Add2_select"):SetCurrentSelect(1)
						end					
					end
				end
				
			end
			if nIsEnable < 1 then
				bar:GetSubItem("ShaXing_BossChoice_Add2"):Disable() --不可选
				bar:GetSubItem("ShaXing_BossChoice_Add2_select"):Disable() --不可选
			end
			table.insert(g_BossBarList, bar)
		end

		--场地元素区域
		ShaXing_BossChoice_Place2Frame_List:Clear()
		--加载不同个数
		local nRandomMaxItemNum = 6
		for i = 1, nRandomMaxItemNum do
			local bar = ShaXing_BossChoice_Place2Frame_List:AddChild("ShaXing_BossChoice_Place2Frame_Gift1")
			local nCurRandomIdx = g_SXRandomIdxList[i]
			-- 填充信息
			bar:GetSubItem("ShaXing_BossChoice_Place2"):Enable() --可选
			bar:GetSubItem("ShaXing_BossChoice_Place2"):SetCheck(0) --未选中
			--悬浮tips
			bar:GetSubItem("ShaXing_BossChoice_Place2"):SetToolTip(g_SXRandomInfo[nCurRandomIdx].nTooltip);
			bar:GetSubItem("ShaXing_BossChoice_Place2"):SetEvent("Clicked", string.format("ShaXing_BossChoice_RandomClicked(%d,%d)",2, i))
			
			--未选中不显示高亮
			bar:GetSubItem("ShaXing_BossChoice_Place2_Mask"):Hide()	
			--属性名
			bar:GetSubItem("ShaXing_BossChoice_Place2Text"):SetText(g_SXRandomInfo[nCurRandomIdx].nName);
			--图片
			bar:GetSubItem("ShaXing_BossChoice_Place2Image"):SetProperty("Image",g_SXRandomInfo[nCurRandomIdx].nImg);
			--分数
			bar:GetSubItem("ShaXing_BossChoice_Place2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_255}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));
			--下拉列表
			bar:GetSubItem("ShaXing_BossChoice_Place2_select"):Enable()
			bar:GetSubItem("ShaXing_BossChoice_Place2_select"):ResetList()
			bar:GetSubItem("ShaXing_BossChoice_Place2_select"):SetEvent("ListSelectionAccepted", string.format("ShaXing_BossChoice_RandomSelecCK(%d)", i))
			bar:GetSubItem("ShaXing_BossChoice_Place2_select"):AddTextItem("等级1", 0)
			bar:GetSubItem("ShaXing_BossChoice_Place2_select"):AddTextItem("等级2", 1)
			bar:GetSubItem("ShaXing_BossChoice_Place2_select"):SetCurrentSelect(0)
			if nIsReset < 1 then
				--非重置直接读数据
				if nIsUseList == 1 then
					if g_RandomChoiceList[i] > 0 then
						bar:GetSubItem("ShaXing_BossChoice_Place2"):SetCheck(1) --选中
						--分数
						bar:GetSubItem("ShaXing_BossChoice_Place2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[g_SXRandomCheck[i]])));
						if g_RandomChoiceList[i] > 1 then
							bar:GetSubItem("ShaXing_BossChoice_Place2"):SetToolTip(g_SXRandomInfo[nCurRandomIdx].nTooltip2);
							bar:GetSubItem("ShaXing_BossChoice_Place2_select"):SetCurrentSelect(1)
						end					
					end
				else
					if g_SXRandomCheck[i] > 0 then
						bar:GetSubItem("ShaXing_BossChoice_Place2"):SetCheck(1) --选中
						--分数
						bar:GetSubItem("ShaXing_BossChoice_Place2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[g_SXRandomCheck[i]])));
						if g_SXRandomCheck[i] > 1 then
							bar:GetSubItem("ShaXing_BossChoice_Place2"):SetToolTip(g_SXRandomInfo[nCurRandomIdx].nTooltip2);
							bar:GetSubItem("ShaXing_BossChoice_Place2_select"):SetCurrentSelect(1)
						end					
					end
				end
				
			end
			if nIsEnable < 1 then
				bar:GetSubItem("ShaXing_BossChoice_Place2"):Disable() --不可选
				bar:GetSubItem("ShaXing_BossChoice_Place2_select"):Disable() --不可选
			end
			table.insert(g_RandomBarList, bar)
		end
	end
	
	--重新计算积分
	ShaXing_BossChoice_Point(nIsUseList,nBossChoiceList,nRandomChoiceList)
end
--=========================================================
--打开其他界面
--nSelectIdx 选的第几个boss
--nBossIdx boss索引
--nRandomList本期场地元素列表 需要拆分
--=========================================================
function ShaXing_BossChoice_OpenFenye(nKillBossCount,nSelectIdx,nBossIdx,nIsCurBoss,nBossMode,nBossChoiceList,nRandomList,nRandomChoiceList,nBossAbandonList)
	if nSelectIdx < 1 or nSelectIdx > 4 then
		return
	end
	--设置参数
	g_ShaXing_FenyeIdx = nSelectIdx
	g_ShaXing_FenyeBossIdx = nBossIdx
	local nFenyeMax = g_ShaXing_FenyeIdx
	if nKillBossCount +1  > g_ShaXing_FenyeIdx then
		nFenyeMax = nKillBossCount +1 
	end
	--PushDebugMessage("test  ShaXing_BossChoice_OpenFenye nSelectIdx="..nSelectIdx.." g_ShaXing_FenyeBossIdx="..g_ShaXing_FenyeBossIdx.." nBossChoiceList="..nBossChoiceList.." nRandomChoiceList="..nRandomChoiceList )
	--选中当前boss分页
	for index=1,table.getn(g_ShaXing_BossChoice_Fenye)  do
		if index == g_ShaXing_FenyeIdx then
			g_ShaXing_BossChoice_Fenye[index]:SetCheck(1);
		else
			g_ShaXing_BossChoice_Fenye[index]:SetCheck(0);
		end
		if index > nFenyeMax  then
			g_ShaXing_BossChoice_Fenye[index]:Disable();
		else
			g_ShaXing_BossChoice_Fenye[index]:Enable();
		end		
	end
	
	--屏蔽按钮
	if nIsCurBoss == 0 then
		--确认键不可点
		ShaXing_BossChoice_ActionFrame:Hide()
		ShaXing_BossChoice_ActionFrame2:Hide()
		--难度不可选
		for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
			g_ShaXing_BossChoice_BossModeList[index]:Disable();
		end
	else
		--确认键可点
		ShaXing_BossChoice_ActionFrame:Show()
		ShaXing_BossChoice_ActionFrame2:Hide()
		--难度可选
		for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
			g_ShaXing_BossChoice_BossModeList[index]:Enable();
		end
	end
		
	--boss放弃情况
	--PushDebugMessage("test fenye nBossAbandonList="..nBossAbandonList.." nKillBossCount="..nKillBossCount)
	g_SXBossAbandon[1] = math.mod(nBossAbandonList,10)
	g_SXBossAbandon[2] = math.floor(math.mod(nBossAbandonList,100)/10)  
	g_SXBossAbandon[3] = math.floor(math.mod(nBossAbandonList,1000)/100)  
	g_SXBossAbandon[4] = math.floor(math.mod(nBossAbandonList,10000)/1000) 
	
	--是否通关标记
	for index=1,table.getn(g_ShaXing_BossChoice_FenyeAbandon)  do
		if index <=  nKillBossCount then
			if g_SXBossAbandon[index] == 1 then
				g_ShaXing_BossChoice_FenyeOk[index]:Hide();
				g_ShaXing_BossChoice_FenyeAbandon[index]:Show();
			else
				g_ShaXing_BossChoice_FenyeOk[index]:Show();
				g_ShaXing_BossChoice_FenyeAbandon[index]:Hide();
			end
		else
			g_ShaXing_BossChoice_FenyeOk[index]:Hide();
			g_ShaXing_BossChoice_FenyeAbandon[index]:Hide();
		end	
	end
	
	if nIsCurBoss == 1 then
		--当前选择boss客户端显示修正
		nBossMode = 1 
	end
	
	if g_SXBossAbandon[g_ShaXing_FenyeIdx] == 1 then
		--放弃boss客户端显示修正
		nBossMode = 0 
	end
	
	--展示boss难度
	for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
		if index == nBossMode then
			g_ShaXing_BossChoice_BossModeList[index]:SetCheck(1);
		else
			g_ShaXing_BossChoice_BossModeList[index]:SetCheck(0);
		end
	end
	
	--PushDebugMessage("test  nBossMode="..nBossMode.." nIsCurBoss="..nIsCurBoss)
	ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nEasyImg )
	ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nEasyTips);
	ShaXing_BossChoice_Text:Hide()
	if nBossMode == 2 then
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nNormalImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nNormalTips);
		ShaXing_BossChoice_Text:Hide()
	elseif nBossMode == 3 then
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nHardImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nHardTips);
		ShaXing_BossChoice_Text:Hide()
	elseif nBossMode == 4 then
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nMaxImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nMaxTips);
		ShaXing_BossChoice_Text:Show()
	end

	--场地元素信息
	--PushDebugMessage("test fenye nRandomList="..nRandomList)
	g_SXRandomIdxList[1] = math.mod(nRandomList,10)
	g_SXRandomIdxList[2] = math.floor(math.mod(nRandomList,100)/10)  
	g_SXRandomIdxList[3] = math.floor(math.mod(nRandomList,1000)/100)  
	g_SXRandomIdxList[4] = math.floor(math.mod(nRandomList,10000)/1000) 
	g_SXRandomIdxList[5] = math.floor(math.mod(nRandomList,100000)/10000) 
	g_SXRandomIdxList[6] = math.floor(math.mod(nRandomList,1000000)/100000) 

	if nIsCurBoss == 1 then
		--难度 重置数据  可选
		ShaXing_BossChoice_ShowAll(nBossMode,1,1,0,0,0)
	else
		if g_SXBossAbandon[g_ShaXing_FenyeIdx] == 1 then
			--放弃本关难度 重置数据  不可选
			ShaXing_BossChoice_ShowAll(nBossMode,1,0,0,0,0)
		else
			--难度 重置不数据  不可选
			ShaXing_BossChoice_ShowAll(nBossMode,0,0,1,nBossChoiceList,nRandomChoiceList)
		end
	end

	--动画重置
	KillTimer("ShaXing_BossChoice_CloseWindow()")
	this:Show()
end

--=========================================================
--boss模式选择选择
--=========================================================
function ShaXing_BossChoiceModel_ModeClicked(nIndex)
	--参数校验
	if nIndex < 1 or nIndex > 4 then
		return
	end
	for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
		if nIndex == index then
			g_ShaXing_BossChoice_BossModeList[index]:SetCheck(1);
		else
			g_ShaXing_BossChoice_BossModeList[index]:SetCheck(0);
		end
	end

	--展示图片和积分
	if nIndex == 1 then
		--PushDebugMessage("test  ModeClicked nBossIdx="..g_ShaXing_FenyeBossIdx.." img"..g_SXBossImg[g_ShaXing_FenyeBossIdx].nEasyImg)
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[g_ShaXing_FenyeBossIdx].nEasyImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[g_ShaXing_FenyeBossIdx].nEasyTips);
		ShaXing_BossChoice_Text:Hide()
	elseif nIndex == 2 then
		--PushDebugMessage("test  ModeClicked idx="..nIndex)
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[g_ShaXing_FenyeBossIdx].nNormalImg )	
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[g_ShaXing_FenyeBossIdx].nNormalTips);
		ShaXing_BossChoice_Text:Hide()
	elseif nIndex == 3 then
		--PushDebugMessage("test  ModeClicked idx="..nIndex)
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[g_ShaXing_FenyeBossIdx].nHardImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[g_ShaXing_FenyeBossIdx].nHardTips);
		ShaXing_BossChoice_Text:Hide()
	elseif nIndex == 4 then
		--PushDebugMessage("test  ModeClicked idx="..nIndex)
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[g_ShaXing_FenyeBossIdx].nMaxImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[g_ShaXing_FenyeBossIdx].nMaxTips);
		ShaXing_BossChoice_Text:Show()
	end
	
	--boss属性重置
	ShaXing_BossChoice_ShowAll(nIndex,1,1,0,0,0)
end

--=========================================================
--boss属性选择
--nType 1 前三个  2是最后一个
--nIndex 7个属性顺延
--=========================================================
function ShaXing_BossChoice_BossClicked(nType,nIndex)
	--PushDebugMessage("test ShaXing_BossChoice_BossClicked  index="..nIndex)
	if nIndex < 1 or nIndex > 7 then
		return
	end

	--按钮状态选择
	local  mCurBossCheck = g_SXBossCheck[nIndex]
	if mCurBossCheck  > 0 then
		g_SXBossCheck[nIndex] = 0
		if nType == 1 then	
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add1"):SetCheck(0)
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_255}",tostring(g_SXBossBuffInfo[nIndex].nPoint[1])));
		else
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2"):SetCheck(0)
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2_select"):SetCurrentSelect(0)
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_255}",tostring(g_SXBossBuffInfo[nIndex].nPoint[1])));
		end
	else
		g_SXBossCheck[nIndex] = 1
		if nType == 1 then
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add1"):SetCheck(1)
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXBossBuffInfo[nIndex].nPoint[1])));
		else
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2"):SetCheck(1)
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2_select"):SetCurrentSelect(0)
			g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXBossBuffInfo[nIndex].nPoint[1])));
		end
	end
	--重新计算积分
	ShaXing_BossChoice_Point(0,0,0)
end


--=========================================================
--场地元素选择
--nType 1 前三个  2是最后一个
--nIndex 6个场地元素顺延
--=========================================================
function ShaXing_BossChoice_RandomClicked(nType,nIndex)
	--PushDebugMessage("test ShaXing_BossChoice_RandomClicked  index="..nIndex)
	if nIndex < 1 or nIndex > 6 then
		return
	end
	--按钮状态选择
	local mCurRandomCheck = g_SXRandomCheck[nIndex]
	local nCurRandomIdx = g_SXRandomIdxList[nIndex]
	--PushDebugMessage("test ShaXing_BossChoice_RandomClicked  index="..nIndex.." Value="..mCurRandomCheck.." nCurRandomIdx="..nCurRandomIdx)
	if mCurRandomCheck > 0 then
		g_SXRandomCheck[nIndex] = 0
		if nType == 1 then
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place1"):SetCheck(0)
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_255}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));
		else
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2"):SetCheck(0)
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2_select"):SetCurrentSelect(0)
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_255}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));
		end
	else
		g_SXRandomCheck[nIndex] = 1
		if nType == 1 then
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place1"):SetCheck(1)
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place1Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));	
		else
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2"):SetCheck(1)
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2_select"):SetCurrentSelect(0)
			g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));
		end
	end
	
	--重新计算积分
	ShaXing_BossChoice_Point(0,0,0)
end

--=========================================================
--boss属性选择下拉框
--=========================================================
function ShaXing_BossChoice_BossSelecCK(nIndex)	
	if nIndex < 1 or nIndex > 7 then
		return
	end
	--PushDebugMessage("test ShaXing_BossChoice_BossSelecCK  index="..nIndex)
	
	local szName, nSelectIdx = g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2_select"):GetCurrentSelect();
	--PushDebugMessage("test ShaXing_BossChoice_BossSelecCK  index="..nIndex.." nSelectIdx="..nSelectIdx)
	
	g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2"):SetCheck(1)
	--按钮状态选择
	if nSelectIdx  > 0 then
		g_SXBossCheck[nIndex] = 2
		g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXBossBuffInfo[nIndex].nPoint[2])));
		g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2"):SetToolTip(g_SXBossBuffInfo[nIndex].nTooltip2);
	else
		g_SXBossCheck[nIndex] = 1
		g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXBossBuffInfo[nIndex].nPoint[1])));
		g_BossBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Add2"):SetToolTip(g_SXBossBuffInfo[nIndex].nTooltip);
	end
	--重新计算积分
	ShaXing_BossChoice_Point(0,0,0)
end

--=========================================================
--场地元素选择下拉框
--=========================================================
function ShaXing_BossChoice_RandomSelecCK(nIndex)	
	if nIndex < 1 or nIndex > 6 then
		return
	end
	--PushDebugMessage("test ShaXing_BossChoice_RandomSelecCK  index="..nIndex)
	
	local szName, nSelectIdx = g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2_select"):GetCurrentSelect();
	--PushDebugMessage("test ShaXing_BossChoice_RandomSelecCK  index="..nIndex.." nSelectIdx="..nSelectIdx)
	
	--按钮状态选择
	local mCurRandomCheck = g_SXRandomCheck[nIndex]
	local nCurRandomIdx = g_SXRandomIdxList[nIndex]
	--PushDebugMessage("test ShaXing_BossChoice_RandomSelecCK  index="..nIndex.." Value="..mCurRandomCheck.." nCurRandomIdx="..nCurRandomIdx)
	g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2"):SetCheck(1)
	if nSelectIdx > 0 then
		g_SXRandomCheck[nIndex] = 2
		g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[2])));
		g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2"):SetToolTip(g_SXRandomInfo[nCurRandomIdx].nTooltip2);
	else
		g_SXRandomCheck[nIndex] = 1
		g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2Num"):SetText(ScriptGlobal_Format("#{XSX_220705_254}",tostring(g_SXRandomInfo[nCurRandomIdx].nPoint[1])));
		g_RandomBarList[nIndex]:GetSubItem("ShaXing_BossChoice_Place2"):SetToolTip(g_SXRandomInfo[nCurRandomIdx].nTooltip);
	end

	--重新计算积分
	ShaXing_BossChoice_Point(0,0,0)
end


--=========================================================
--分页点击
--=========================================================
function ShaXing_BossChoice_FenyeClicked(nIdex)
	--分页
	--PushDebugMessage("test  FenyeClicked nIdex="..nIdex.." g_ShaXing_FenyeIdx="..g_ShaXing_FenyeIdx)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FenyeClicked" )
		Set_XSCRIPT_ScriptID( 893471)
		Set_XSCRIPT_Parameter( 0 ,g_ShaXing_targetId)
		Set_XSCRIPT_Parameter( 1 ,nIdex)
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()

end


--=========================================================
--boss积分计算
--nIsUseList 特殊情况需要用传参
--nBossChoiceList 当前boss选择
--nRandomChoiceList 当前场地元素选择
--=========================================================
function ShaXing_BossChoice_Point(nIsUseList,nBossChoiceList,nRandomChoiceList)
	local  bBossMode = 0
	for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
		local bBossCheck = g_ShaXing_BossChoice_BossModeList[index]:GetCheck();
		if bBossCheck > 0 then
			bBossMode = index
		end
	end
	
	--boss属性
	local bBossCheck1 = g_SXBossCheck[1] 
	local bBossCheck2 = g_SXBossCheck[2]
	local bBossCheck3 = g_SXBossCheck[3]
	local bBossCheck4 = g_SXBossCheck[4]
	local bBossCheck5 = g_SXBossCheck[5]
	local bBossCheck6 = g_SXBossCheck[6]
	local bBossCheck7 = g_SXBossCheck[7]
	if nIsUseList == 1 then
		bBossCheck1 = math.mod(nBossChoiceList,10)
		bBossCheck2 = math.floor(math.mod(nBossChoiceList,100)/10)  
		bBossCheck3 = math.floor(math.mod(nBossChoiceList,1000)/100)
		bBossCheck4 = math.floor(math.mod(nBossChoiceList,10000)/1000) 
		bBossCheck5 = math.floor(math.mod(nBossChoiceList,100000)/10000) 
		bBossCheck6 = math.floor(math.mod(nBossChoiceList,1000000)/100000) 
		bBossCheck7 = math.floor(math.mod(nBossChoiceList,10000000)/1000000) 
	end

	--场地元素
	local bRandomCheck1 = g_SXRandomCheck[1]
	local bRandomCheck2 = g_SXRandomCheck[2]
	local bRandomCheck3 = g_SXRandomCheck[3]
	local bRandomCheck4 = g_SXRandomCheck[4]
	local bRandomCheck5 = g_SXRandomCheck[5]
	local bRandomCheck6 = g_SXRandomCheck[6]
	if nIsUseList == 1 then
		bRandomCheck1 = math.mod(nRandomChoiceList,10)
		bRandomCheck2 = math.floor(math.mod(nRandomChoiceList,100)/10)  
		bRandomCheck3 = math.floor(math.mod(nRandomChoiceList,1000)/100)  
		bRandomCheck4 = math.floor(math.mod(nRandomChoiceList,10000)/1000) 
		bRandomCheck5 = math.floor(math.mod(nRandomChoiceList,100000)/10000) 
		bRandomCheck6 = math.floor(math.mod(nRandomChoiceList,1000000)/100000) 
	end
	
	local nCurBossPoint = g_SXBossImg[1].nEasyPoint
	local modeUp = 1
	if bBossMode == 1 then
		nCurBossPoint = g_SXBossImg[1].nEasyPoint
		modeUp = 1
	elseif bBossMode == 2 then
		nCurBossPoint = g_SXBossImg[1].nNormalPoint
		modeUp = 1.7
	elseif bBossMode == 3 then
		nCurBossPoint = g_SXBossImg[1].nHardPoint
		modeUp = 2.5
	elseif bBossMode == 4 then
		nCurBossPoint = g_SXBossImg[1].nMaxPoint
		modeUp = 3
	end

	local nBaseBossPoint = g_SXBossBuffInfo[1].nPoint[bBossCheck1] + g_SXBossBuffInfo[2].nPoint[bBossCheck2] + g_SXBossBuffInfo[3].nPoint[bBossCheck3] +g_SXBossBuffInfo[4].nPoint[bBossCheck4]+g_SXBossBuffInfo[5].nPoint[bBossCheck5]+g_SXBossBuffInfo[6].nPoint[bBossCheck6]+g_SXBossBuffInfo[7].nPoint[bBossCheck7]	
	local nBaseRandomPoint = g_SXRandomInfo[g_SXRandomIdxList[1]].nPoint[bRandomCheck1]+g_SXRandomInfo[g_SXRandomIdxList[2]].nPoint[bRandomCheck2]+g_SXRandomInfo[g_SXRandomIdxList[3]].nPoint[bRandomCheck3]+g_SXRandomInfo[g_SXRandomIdxList[4]].nPoint[bRandomCheck4]+g_SXRandomInfo[g_SXRandomIdxList[5]].nPoint[bRandomCheck5]+g_SXRandomInfo[g_SXRandomIdxList[6]].nPoint[bRandomCheck6]
	local mTotalPoint = nCurBossPoint + nBaseBossPoint + nBaseRandomPoint
	--PushDebugMessage("test 积分 modeUp="..modeUp.." mTotalPoint"..mTotalPoint.." nCurBossPoint="..nCurBossPoint.." nBaseBossPoint="..nBaseBossPoint.." nBaseRandomPoint="..nBaseRandomPoint)
	if bBossMode == 1 then
		ShaXing_BossChoice_AllNum:SetText(ScriptGlobal_Format("#{XSX_220705_241}",tostring(mTotalPoint*modeUp)));
		ShaXing_BossChoice_AllNumFrame:SetProperty( "Image", "set:ShaXing1 image:ShaXing_TextBk1" )
	elseif bBossMode == 2 then
		ShaXing_BossChoice_AllNum:SetText(ScriptGlobal_Format("#{XSX_220705_242}",tostring(mTotalPoint*modeUp)));
		ShaXing_BossChoice_AllNumFrame:SetProperty( "Image", "set:ShaXing1 image:ShaXing_TextBk2" )
	elseif bBossMode == 3 then
		ShaXing_BossChoice_AllNum:SetText(ScriptGlobal_Format("#{XSX_220705_243}",tostring(mTotalPoint*modeUp)));
		ShaXing_BossChoice_AllNumFrame:SetProperty( "Image", "set:ShaXing1 image:ShaXing_TextBk3" )
	else
		ShaXing_BossChoice_AllNum:SetText(ScriptGlobal_Format("#{XSX_220705_241}",tostring(mTotalPoint*modeUp)));
		ShaXing_BossChoice_AllNumFrame:SetProperty( "Image", "set:ShaXing1 image:ShaXing_TextBk4" )
	end
	ShaXing_BossChoice_AllNum:Show();
end

--=========================================================
--放弃本关
--=========================================================
function ShaXing_BossChoice_GiveUp()

	--弹个二次确认
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GiveUpTheBoss" )
		Set_XSCRIPT_ScriptID( 893473)
		Set_XSCRIPT_Parameter( 0 ,g_ShaXing_targetId)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

--=========================================================
--boss选择确认
--=========================================================
function ShaXing_BossChoice_Confirm()
	--按钮状态选择
	local  bBossMode = 1
	for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
		local bBossCheck1 = g_ShaXing_BossChoice_BossModeList[index]:GetCheck();
		if bBossCheck1 > 0 then
			bBossMode = index
		end
	end
	--boss属性
	local bBossCheck = g_SXBossCheck[1]+g_SXBossCheck[2]*10+g_SXBossCheck[3]*100+g_SXBossCheck[4]*1000+g_SXBossCheck[5]*10000+g_SXBossCheck[6]*100000+g_SXBossCheck[7]*1000000
	--场地元素
	local bRandomCheck = g_SXRandomCheck[1]+g_SXRandomCheck[2]*10+g_SXRandomCheck[3]*100+g_SXRandomCheck[4]*1000+g_SXRandomCheck[5]*10000+g_SXRandomCheck[6]*100000	
	--PushDebugMessage("test bBossMode="..bBossMode.." bBossCheck="..bBossCheck.." bRandomCheck="..bRandomCheck)
	--bBossCheck = 2222222
	--bRandomCheck = 110000
	--PushDebugMessage("test 测试函数 bBossMode="..bBossMode.." bBossCheck="..bBossCheck.." bRandomCheck="..bRandomCheck)
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BossChoiceConfirm" )
		Set_XSCRIPT_ScriptID( 893471)	
		Set_XSCRIPT_Parameter( 0 ,g_ShaXing_targetId)
		Set_XSCRIPT_Parameter( 1 ,g_ShaXing_FenyeIdx)
		Set_XSCRIPT_Parameter( 2 ,bBossMode)
		Set_XSCRIPT_Parameter( 3 ,bBossCheck)
		Set_XSCRIPT_Parameter( 4 ,bRandomCheck)
		Set_XSCRIPT_ParamCount( 5 )
	Send_XSCRIPT()
end


--=========================================================
--预告界面
--nBossIdx boss索引
--nRandomList本期场地元素列表 需要拆分
--=========================================================
function ShaXing_BossChoice_JustShow(nSelectIdx,nBossIdx,nBossMode,nBossChoiceList,nRandomList,nRandomChoiceList,nBossAbandonList)
	if nSelectIdx < 1 or nSelectIdx > 4 then
		return
	end
	--动画重置
	KillTimer("ShaXing_BossChoice_CloseWindow()")
	--PushDebugMessage("test JustShow nSelectIdx="..nSelectIdx.." nBossIdx="..nBossIdx)
	--设置参数
	g_ShaXing_FenyeIdx = nSelectIdx
	g_ShaXing_FenyeBossIdx = nBossIdx
	--PushDebugMessage("test  ShaXing_BossChoice_OpenFenye g_ShaXing_FenyeBossIdx="..g_ShaXing_FenyeBossIdx )
	--选中当前boss分页 不可选
	for index=1,table.getn(g_ShaXing_BossChoice_Fenye)  do
		if index == g_ShaXing_FenyeIdx then
			g_ShaXing_BossChoice_Fenye[index]:SetCheck(1);
		else
			g_ShaXing_BossChoice_Fenye[index]:SetCheck(0);
		end
		g_ShaXing_BossChoice_Fenye[index]:Disable();
	end
	
	--确认键不可点
	ShaXing_BossChoice_ActionFrame:Hide()
	ShaXing_BossChoice_ActionFrame2:Hide()
	--难度不可选
	for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
		g_ShaXing_BossChoice_BossModeList[index]:Disable();
	end
	
	--boss放弃情况
	--PushDebugMessage("test JustShow nBossAbandonList="..nBossAbandonList.." nSelectIdx="..nSelectIdx)
	g_SXBossAbandon[1] = math.mod(nBossAbandonList,10)
	g_SXBossAbandon[2] = math.floor(math.mod(nBossAbandonList,100)/10)  
	g_SXBossAbandon[3] = math.floor(math.mod(nBossAbandonList,1000)/100)  
	g_SXBossAbandon[4] = math.floor(math.mod(nBossAbandonList,10000)/1000) 
	
	--是否通关标记
	for index=1,table.getn(g_ShaXing_BossChoice_FenyeAbandon)  do
		if index <  g_ShaXing_FenyeIdx then
			if g_SXBossAbandon[index] == 1 then
				g_ShaXing_BossChoice_FenyeOk[index]:Hide();
				g_ShaXing_BossChoice_FenyeAbandon[index]:Show();
			else
				g_ShaXing_BossChoice_FenyeOk[index]:Show();
				g_ShaXing_BossChoice_FenyeAbandon[index]:Hide();
			end
		else
			g_ShaXing_BossChoice_FenyeOk[index]:Hide();
			g_ShaXing_BossChoice_FenyeAbandon[index]:Hide();
		end	
	end
	
	--展示boss难度
	for index=1,table.getn(g_ShaXing_BossChoice_BossModeList)  do
		if index == nBossMode then
			g_ShaXing_BossChoice_BossModeList[index]:SetCheck(1);
		else
			g_ShaXing_BossChoice_BossModeList[index]:SetCheck(0);
		end
	end
	
	--PushDebugMessage("test  nBossMode="..nBossMode)
	ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nEasyImg )
	ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nEasyTips);
	ShaXing_BossChoice_Text:Hide()
	if nBossMode == 2 then
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nNormalImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nNormalTips);
		ShaXing_BossChoice_Text:Hide()
	elseif nBossMode == 3 then
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nHardImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nHardTips);
		ShaXing_BossChoice_Text:Hide()
	elseif nBossMode == 4 then
		ShaXing_BossChoiceFakeObject:SetProperty( "Image", g_SXBossImg[nBossIdx].nMaxImg )
		ShaXing_BossChoice_Num1:SetText(g_SXBossImg[nBossIdx].nMaxTips);
		ShaXing_BossChoice_Text:Show()
	end
	
	--场地元素信息
	--PushDebugMessage("test JustShow nRandomList="..nRandomList)
	g_SXRandomIdxList[1] = math.mod(nRandomList,10)
	g_SXRandomIdxList[2] = math.floor(math.mod(nRandomList,100)/10)  
	g_SXRandomIdxList[3] = math.floor(math.mod(nRandomList,1000)/100)  
	g_SXRandomIdxList[4] = math.floor(math.mod(nRandomList,10000)/1000) 
	g_SXRandomIdxList[5] = math.floor(math.mod(nRandomList,100000)/10000) 
	g_SXRandomIdxList[6] = math.floor(math.mod(nRandomList,1000000)/100000)	
	
	--填充数据
	ShaXing_BossChoice_ShowAll(nBossMode,0,0,1,nBossChoiceList,nRandomChoiceList)

	--显示
	ShaXing_BossChoice_ActionFrame:Hide()
	ShaXing_BossChoice_ActionFrame2:Show()

	--倒计时
	SetTimer("ShaXing_BossChoice","ShaXing_BossChoice_CloseWindow()", 1000);		--设置定时器5秒钟倒计时
	g_ShaXing_CloseTick = 5
	ShaXing_BossChoice_ActionFrame2_Text:SetText(ScriptGlobal_Format("#{XSX_220705_361}",g_ShaXing_CloseTick));

	this:Show()
end


--================================================
-- 倒计时界面
--================================================
function ShaXing_BossChoice_CloseWindow()
	KillTimer("ShaXing_BossChoice_CloseWindow()")
	g_ShaXing_CloseTick = g_ShaXing_CloseTick - 1
	ShaXing_BossChoice_ActionFrame2_Text:SetText(ScriptGlobal_Format("#{XSX_220705_361}",g_ShaXing_CloseTick));
	--PushDebugMessage("test  ShaXing_BossChoice_CloseWindow  g_ShaXing_CloseTick="..g_ShaXing_CloseTick)
	if g_ShaXing_CloseTick > 0 then
		SetTimer("ShaXing_BossChoice","ShaXing_BossChoice_CloseWindow()", 1000)
	else
		--关闭界面
		ShaXing_BossChoice_OnClose()
	end
end


--=========================================================
--各种说明
--=========================================================
function ShaXing_BossChoice_Help2Clicked()
	PushEvent("QUEST_HELPINFO", "#{XSX_220705_229}")
end

function ShaXing_BossChoice_Help3Clicked()
	PushEvent("QUEST_HELPINFO", "#{XSX_220705_245}")
end

function ShaXing_BossChoice_Help4Clicked()
	PushEvent("QUEST_HELPINFO", "#{XSX_220705_261}")
end

