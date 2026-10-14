-- 界面的默认相对位置
local SweepPage_Frame_UnifiedXPosition;
local SweepPage_Frame_UnifiedYPosition;

local SweepPage_open_fubenIndexId = -1

--格子及其编号
local SweepPage_ITEM_NUM = 12;
local SweepPage_ITEMS = {};

local SweepPage_BossIcon = {}
local SweepPage_BossButton = {}
local SweepPage_BossingAnimate = {}
local SweepPage_BossDieIcon = {}
local SweepPage_BossName = {}
local SeeepPage_Timer = {}

local SweepPage_MaxBoss = 6

local SweepPage_CheckButton = {}

local SweepPage_GiveUpCheckButton = 1

local SweepPage_curPassIndex = 0

local SweepPage_FuBenSecKillNum = {}

local SweepPage_DoubleOp = 0

local m_FubenKillBossStr	= 
{
	[1] ={Explain="#{YZCS_180827_2}", DoubleCheck="#{YZCS_180827_8}", DoubleText2="#{YZCS_180827_3}"},						--讨伐燕子坞	
	[2] ={Explain="#{FBSD_210806_07}", DoubleCheck="#{FBSD_210806_08}", DoubleText2="#{FBSD_210806_09}"},						--苏州四绝庄	
	[5] ={Explain="#{FBSD_210806_04}", DoubleCheck="#{FBSD_210806_05}", DoubleText2="#{FBSD_210806_06}"},						--少室山	
	[7] ={Explain="#{FBSD_210806_16}", DoubleCheck="#{FBSD_150126_25}", DoubleText2="#{FBSD_150126_83}"},						--兵圣困难	
	[8] ={Explain="#{FMCS_180705_18}", DoubleCheck="#{FMCS_180705_20}", DoubleText2="#{FMCS_180705_19}"},						--凤鸣王陵
	[9] ={Explain="#{DPMCS_180827_1}", DoubleCheck="#{DPMCS_180827_15}", DoubleText2="#{DPMCS_180827_2}"},						--挑战缥缈峰
	[10] ={Explain="#{FBSD_130127_3}", DoubleCheck="#{FBSD_150126_25}", DoubleText2="#{FBSD_150126_83}"},						--三神幻境
	[11] ={Explain="#{FBSD_210806_10}", DoubleCheck="#{FBSD_210806_11}", DoubleText2="#{FBSD_210806_12}"},						--福地普通
	[12] ={Explain="#{FBSD_210806_13}", DoubleCheck="#{FBSD_210806_14}", DoubleText2="#{FBSD_210806_15}"},						--福地困难
	[13] ={Explain="#{FBSD_210806_01}", DoubleCheck="#{FBSD_210806_02}", DoubleText2="#{FBSD_210806_03}"},						--老三环
}
function SweepPage_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REFRESH_SECKILL_PAGE")
	this:RegisterEvent("REFRESH_SECKILL_ITEM")
	this:RegisterEvent("SEND_SECKILL")
	this:RegisterEvent("UPDATE_SECKILL_FUBEN_SECKILLNUM")
end

function SweepPage_OnLoad()
	SweepPage_Frame_UnifiedXPosition	= SweepPage_Frame : GetProperty("UnifiedXPosition");
	SweepPage_Frame_UnifiedYPosition	= SweepPage_Frame : GetProperty("UnifiedYPosition");
	
	local SecKillFubenCount = GetSecKillFuBenCount()
	for i = 0, 20 do
		SweepPage_CheckButton[i] = 0
	end
	for i = 0, 50 do
		SweepPage_FuBenSecKillNum[i] = {0, 0}
	end
	
	SweepPage_ITEMS[1] = SweepPage_Item1
	SweepPage_ITEMS[2] = SweepPage_Item2
	SweepPage_ITEMS[3] = SweepPage_Item3
	SweepPage_ITEMS[4] = SweepPage_Item4
	SweepPage_ITEMS[5] = SweepPage_Item5
	SweepPage_ITEMS[6] = SweepPage_Item6
	SweepPage_ITEMS[7] = SweepPage_Item7
	SweepPage_ITEMS[8] = SweepPage_Item8
	SweepPage_ITEMS[9] = SweepPage_Item9
	SweepPage_ITEMS[10] = SweepPage_Item10
	SweepPage_ITEMS[11] = SweepPage_Item11
	SweepPage_ITEMS[12] = SweepPage_Item12
	
	SweepPage_BossIcon[1] = SweepPage_Boss1
	SweepPage_BossIcon[2] = SweepPage_Boss2
	SweepPage_BossIcon[3] = SweepPage_Boss3
	SweepPage_BossIcon[4] = SweepPage_Boss4
	SweepPage_BossIcon[5] = SweepPage_Boss5
	SweepPage_BossIcon[6] = SweepPage_Boss6
	
	SweepPage_BossButton[1] = SweepPage_Boss1AnimateImage
	SweepPage_BossButton[2] = SweepPage_Boss2AnimateImage
	SweepPage_BossButton[3] = SweepPage_Boss3AnimateImage
	SweepPage_BossButton[4] = SweepPage_Boss4AnimateImage
	SweepPage_BossButton[5] = SweepPage_Boss5AnimateImage
	SweepPage_BossButton[6] = SweepPage_Boss6AnimateImage
	
	SweepPage_BossingAnimate[1] = SweepPage_Boss1doing
	SweepPage_BossingAnimate[2] = SweepPage_Boss2doing
	SweepPage_BossingAnimate[3] = SweepPage_Boss3doing
	SweepPage_BossingAnimate[4] = SweepPage_Boss4doing
	SweepPage_BossingAnimate[5] = SweepPage_Boss5doing
	SweepPage_BossingAnimate[6] = SweepPage_Boss6doing
	
	SweepPage_BossDieIcon[1] = SweepPage_Boss1finish
	SweepPage_BossDieIcon[2] = SweepPage_Boss2finish
	SweepPage_BossDieIcon[3] = SweepPage_Boss3finish
	SweepPage_BossDieIcon[4] = SweepPage_Boss4finish
	SweepPage_BossDieIcon[5] = SweepPage_Boss5finish
	SweepPage_BossDieIcon[6] = SweepPage_Boss6finish
	
	SweepPage_BossName[1] = SweepPage_Boss1Name
	SweepPage_BossName[2] = SweepPage_Boss2Name
	SweepPage_BossName[3] = SweepPage_Boss3Name
	SweepPage_BossName[4] = SweepPage_Boss4Name
	SweepPage_BossName[5] = SweepPage_Boss5Name
	SweepPage_BossName[6] = SweepPage_Boss6Name
	
	SeeepPage_Timer[1] = SweepPage_Boss1_StopWatch
	SeeepPage_Timer[2] = SweepPage_Boss2_StopWatch
	SeeepPage_Timer[3] = SweepPage_Boss3_StopWatch
	SeeepPage_Timer[4] = SweepPage_Boss4_StopWatch
	SeeepPage_Timer[5] = SweepPage_Boss5_StopWatch
	SeeepPage_Timer[6] = SweepPage_Boss6_StopWatch
	
	SweepPage_Double2:Hide()
	SweepPage_Explain4:Hide()
end

-- OnEvent
function SweepPage_OnEvent(event)
	if (event == "UI_COMMAND" ) then
		if tonumber(arg0) == 20150212 then
			SweepPage_open_fubenIndexId = Get_XParam_INT(0)
			
			OpenWindow("Packet")
			this:Show()
			SweepPage_UpdateSeckillNum()
			SweepPage_Update(0)
			
		elseif tonumber(arg0) == 20150228 then
			if this:IsVisible() then
				local nOpType = Get_XParam_INT(0)
				if nOpType == 1 then
					SweepPage_Update(0)
				elseif nOpType == 2 then
					local fubenIndexId = Get_XParam_INT(1)
					if SweepPage_open_fubenIndexId ~= fubenIndexId then
						return
					end
					local bossIndex = Get_XParam_INT(2)
					SweepPage_OnBossButtonOld(bossIndex)
				end
			end
		end
		
	elseif (event == "REFRESH_SECKILL_PAGE") then
		if this:IsVisible() then
			SweepPage_Update(1)
		end
		
	elseif (event == "REFRESH_SECKILL_ITEM") then
		if this:IsVisible() then
			SweepPage_Item_Update()
		end
	
	elseif (event == "SEND_SECKILL") then
		if this:IsVisible() then
			if tonumber(arg0) == 0 then
				SweepPage_DoubleOp = tonumber(arg2)
				SweepPage_SendSecKill(tonumber(arg1))
			end
		end
				
		if tonumber(arg0) == 1 then
			SweepPage_SanShenSendSecKill(tonumber(arg1), tonumber(arg2))		
		end

	
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		SweepPage_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		SweepPage_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		SweepPage_OnClosed()
		
	elseif( event == "UPDATE_SECKILL_FUBEN_SECKILLNUM") then
		SweepPage_UpdateSeckillNum()
	end
end

function SweepPage_Frame_On_ResetPos()
	SweepPage_Frame : SetProperty("UnifiedXPosition", SweepPage_Frame_UnifiedXPosition);
	SweepPage_Frame : SetProperty("UnifiedYPosition", SweepPage_Frame_UnifiedYPosition);
end

function SweepPage_OnClosed()
	this:Hide();
	
	for i=1, SweepPage_MaxBoss do
		SeeepPage_Timer[i]:SetProperty("Timer", "-1");
	end
end

function SweepPage_Item_Update()
	--显示物品栏的物品
	for i=1, SweepPage_ITEM_NUM do
		SweepPage_ITEMS[i]:SetActionItem(-1);
		SweepPage_ITEMS[i]:Enable();
	end
	
	--从数据池中使用数据填入背包内的物品
	local nActIndex = 0
	
	for i=1, SweepPage_ITEM_NUM  do
		local theAction = SecKillEnumItem(nActIndex);
		nActIndex = nActIndex+1;

		if theAction:GetID() ~= 0 then
			SweepPage_ITEMS[i]:SetActionItem(theAction:GetID());
		else
			SweepPage_ITEMS[i]:SetActionItem(-1);
		end
	end
end

function SweepPage_UpdateControl(isSanShen)
	local b,SBSDYuanBao = LuaFnGetSecKillInfoByFuBenIndexIDEx(SweepPage_open_fubenIndexId, "SBSDYB")
	if nil == SBSDYuanBao then
		return
	end
	if isSanShen == 1 then
		SweepPage_Explain:Hide()
		--SweepPage_ExplainBK:Hide()
		SweepPage_Explain3:Show()
	
		SweepPage_Boss4:Hide()
		SweepPage_BossIcon[4] = SweepPage_Boss4_SanShen
		SweepPage_BossButton[4] = SweepPage_Boss4AnimateImage_SanShen
		SweepPage_BossingAnimate[4] = SweepPage_Boss4doing_SanShen
		SweepPage_BossDieIcon[4] = SweepPage_Boss4finish_SanShen
	
		SweepPage_Boss5:Hide()
		SweepPage_BossIcon[5] = SweepPage_Boss5
		SweepPage_BossButton[5] = SweepPage_Boss5AnimateImage
		SweepPage_BossingAnimate[5] = SweepPage_Boss5doing
		SweepPage_BossDieIcon[5] = SweepPage_Boss5finish
		
		SweepPage_Boss6:Hide()
		SweepPage_BossIcon[6] = SweepPage_Boss6
		SweepPage_BossButton[6] = SweepPage_Boss6AnimateImage
		SweepPage_BossingAnimate[6] = SweepPage_Boss6doing
		SweepPage_BossDieIcon[6] = SweepPage_Boss6finish
		
	else
		SweepPage_Explain:Show()
		SweepPage_Explain:SetText("#{FBSD_150126_27}")
		SweepPage_DoubleCheck:SetToolTip("#{FBSD_150126_25}")
		SweepPage_FourCheck:SetToolTip("#{FBSD_150126_25}")
		if nil ~= m_FubenKillBossStr[SweepPage_open_fubenIndexId] then
			SweepPage_Explain:SetText(m_FubenKillBossStr[SweepPage_open_fubenIndexId].Explain)
			SweepPage_DoubleCheck:SetToolTip(m_FubenKillBossStr[SweepPage_open_fubenIndexId].DoubleCheck)
			SweepPage_FourCheck:SetToolTip(ScriptGlobal_Format("#{GXB_220929_1}", SBSDYuanBao))
		end
		--SweepPage_ExplainBK:Show()
		SweepPage_Explain3:Hide()
	
		SweepPage_Boss4_SanShen:Hide()
		SweepPage_BossIcon[4] = SweepPage_Boss4
		SweepPage_BossButton[4] = SweepPage_Boss4AnimateImage
		SweepPage_BossingAnimate[4] = SweepPage_Boss4doing
		SweepPage_BossDieIcon[4] = SweepPage_Boss4finish
	
		SweepPage_BossIcon[5] = SweepPage_Boss5
		SweepPage_BossButton[5] = SweepPage_Boss5AnimateImage
		SweepPage_BossingAnimate[5] = SweepPage_Boss5doing
		SweepPage_BossDieIcon[5] = SweepPage_Boss5finish
	
		SweepPage_BossIcon[6] = SweepPage_Boss6
		SweepPage_BossButton[6] = SweepPage_Boss6AnimateImage
		SweepPage_BossingAnimate[6] = SweepPage_Boss6doing
		SweepPage_BossDieIcon[6] = SweepPage_Boss6finish
	end
end

function SweepPage_SanUpdate(InSeckill)

	SweepPage_UpdateControl(1)
	
	SweepPage_Explain3:SetText("#{FBSD_130127_3}")
	
	--显示Boss图标
	local isInSecKill,fubenIndexId,BossIndex,DoubleExp = GetSecKillData()
	if isInSecKill == 2 or isInSecKill == 3 then
		isInSecKill = 0
		DoubleExp = 0
		BossIndex = 0
	end
	
	local BossIcon = {}
	local BossName = {}
	local FubenName, BossMaxNum, CanDoubleExp
	
	if isInSecKill == 1 and fubenIndexId == SweepPage_open_fubenIndexId then
		if DoubleExp == 1 then
			SweepPage_CheckButton[SweepPage_open_fubenIndexId] = 1
		elseif DoubleExp == 2 then
			SweepPage_CheckButton[SweepPage_open_fubenIndexId] = 2
		end
	end
	
	FubenName,BossMaxNum,BossIcon[1],BossName[1],BossIcon[2],BossName[2],BossIcon[3],BossName[3],BossIcon[4],BossName[4],BossIcon[5],BossName[5],BossIcon[6],BossName[6], CanDoubleExp = Lua_GetSecKillBossIconByFuBenIndexId(SweepPage_open_fubenIndexId)
	
	local strTemp = ScriptGlobal_Format("#{FBSD_150126_26}",FubenName)
	SweepPage_DragTitle:SetText(strTemp)
	
	local b,SBSDYuanBao = LuaFnGetSecKillInfoByFuBenIndexIDEx(SweepPage_open_fubenIndexId, "SBSDYB")
	if nil == SBSDYuanBao then
		return
	end
	for i=1, BossMaxNum do
		SweepPage_BossIcon[i]:Show()
		SweepPage_BossName[i]:Show()
		SweepPage_BossName[i]:SetText("#cfff263"..BossName[i])
		
		if BossIcon[i] ~= nil and BossIcon[i] ~= "" then
			local sPos,_ = string.find(BossIcon[i]," ");
			local IconImageSet = string.sub(BossIcon[i],5,sPos-1);
			local IconIamge = string.sub(BossIcon[i],sPos+7)
			if nil ~= IconImageSet and nil ~= IconIamge then
					SweepPage_BossIcon[i]:SetImage(IconImageSet,IconIamge)
			end
		end
	end
	
	local Msg = ScriptGlobal_Format("#{SDYH_170123_09}",0,0)
	
	if SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][1] ~= 0 then
		Msg = ScriptGlobal_Format("#{SDYH_170123_09}",SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][1], SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][2])
	else
	 	Msg = ScriptGlobal_Format("#{SDYH_170123_09}","#cff0000"..SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][1], SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][2])
	end
	
	SweepPage_Explain_times:SetText(Msg)
	
	if isInSecKill == 0 and InSeckill == 1 then--完成阶段
		SweepPage_GoOn:Enable()
		SweepPage_GoOn_tips:Hide()
		for i=1, 3 do
			SweepPage_BossingAnimate[i]:Hide()
			SweepPage_BossDieIcon[i]:Show()
			SweepPage_BossDieIcon[i]:SetToolTip("#{FBSD_150126_30}")
		end
		
		for i=4,6 do
			SweepPage_BossDieIcon[i]:Hide()
			SweepPage_BossButton[i]:Hide()
			SweepPage_BossIcon[i]:SetToolTip("#{FBSD_130127_9}")
			SweepPage_BossingAnimate[i]:Hide()
		end
		if nil ~= SweepPage_BossingAnimate[SweepPage_curPassIndex] then
			SweepPage_BossingAnimate[SweepPage_curPassIndex]:Show()
			SweepPage_BossingAnimate[SweepPage_curPassIndex]:SetToolTip("#{FBSD_130127_8}")
			SweepPage_BossDieIcon[SweepPage_curPassIndex]:Hide()
			SeeepPage_Timer[SweepPage_curPassIndex]:SetProperty("Timer", "1.8")
		end
	
		SweepPage_Explain3:SetText("#{FBSD_130127_3}")
	
	elseif fubenIndexId ~= SweepPage_open_fubenIndexId or BossIndex < 3 then   --处于扫荡阶段
		local KillBossIndex = 1
		if isInSecKill == 1 and fubenIndexId == SweepPage_open_fubenIndexId then
			KillBossIndex = BossIndex + 1
		end
			
		for i=1, BossMaxNum do
			if i < KillBossIndex then
				if KillBossIndex == i + 1 and InSeckill == 1 and SweepPage_curPassIndex ~= KillBossIndex then
					SweepPage_BossingAnimate[i]:Show()
					SweepPage_BossingAnimate[i]:SetToolTip("#{FBSD_150126_30}")
					SweepPage_BossDieIcon[i]:Hide()
					SeeepPage_Timer[i]:SetProperty("Timer", "1.8");
				else
					SweepPage_BossingAnimate[i]:Hide()
					SweepPage_BossDieIcon[i]:Show()
					SweepPage_BossDieIcon[i]:SetToolTip("#{FBSD_150126_30}")
				end
			
				SweepPage_BossButton[i]:Hide()
			elseif i == KillBossIndex then
				SweepPage_BossDieIcon[i]:Hide()
				SweepPage_BossButton[i]:Show()
				SweepPage_BossButton[i]:Enable()
				SweepPage_BossButton[i]:SetToolTip("#{FBSD_150126_29}")
				SweepPage_BossButton[i]:PlayWarning(1)
				SweepPage_BossingAnimate[i]:Hide()
				local strTemp = ScriptGlobal_Format("#{FBSD_150126_81}",BossName[i])
				SweepPage_Explain1:SetText(strTemp)
			else
				SweepPage_BossDieIcon[i]:Hide()
				SweepPage_BossButton[i]:Hide()
				if i < 4 then
					SweepPage_BossIcon[i]:SetToolTip("#{FBSD_150126_28}")
				else
					SweepPage_BossIcon[i]:SetToolTip("#{FBSD_130127_4}")
				end
				SweepPage_BossingAnimate[i]:Hide()
			end
		end
		
	elseif BossIndex == 3 then  --开宝箱阶段
		for i=1, 2 do
			SweepPage_BossingAnimate[i]:Hide()
			SweepPage_BossDieIcon[i]:Show()
			SweepPage_BossDieIcon[i]:SetToolTip("#{FBSD_150126_30}")
			SweepPage_BossButton[i]:Hide()
		end
		
		if SweepPage_curPassIndex == 3 then
			SweepPage_BossingAnimate[3]:Show()
			SweepPage_BossingAnimate[3]:SetToolTip("#{FBSD_150126_30}")
			SweepPage_BossDieIcon[3]:Hide()
			SeeepPage_Timer[3]:SetProperty("Timer", "1.8")
			SweepPage_BossButton[3]:Hide()
		else
			SweepPage_BossingAnimate[3]:Hide()
			SweepPage_BossDieIcon[3]:Show()
			SweepPage_BossDieIcon[3]:SetToolTip("#{FBSD_150126_30}")
			SweepPage_BossButton[3]:Hide()
		end 
		
		local tips = { [4] = "#{FBSD_130127_5}", [5] = "#{FBSD_130127_6}", [6] = "#{FBSD_130127_7}"}
		
		for i = 4, 6 do
			SweepPage_BossDieIcon[i]:Hide()
			SweepPage_BossButton[i]:Show()
			SweepPage_BossButton[i]:Enable()
			SweepPage_BossButton[i]:SetToolTip(tips[i])
			SweepPage_BossButton[i]:PlayWarning(1)
			SweepPage_BossingAnimate[i]:Hide()
		end
		
		SweepPage_Explain1:SetText("#{FBSD_130127_2}")
	end	
	
	if isInSecKill == 1 then
		SweepPage_SetDoubleBtnState(1)
	else
		SweepPage_SetDoubleBtnState(0)
	end
	
	if SweepPage_GiveUpCheckButton == 1 then
		SweepPage_AbandonCheckButton:SetCheck(1)
	else
		SweepPage_AbandonCheckButton:SetCheck(0)
	end
	
	if DoubleExp == 1 then
		SweepPage_DoubleText2:SetText("#{FBSD_150126_74}")
	elseif DoubleExp == 2 then
		SweepPage_FourText2:SetText("#{GXB_220929_10}")
	else
		if nil ~= m_FubenKillBossStr[SweepPage_open_fubenIndexId] then
			SweepPage_DoubleText2:SetText(m_FubenKillBossStr[SweepPage_open_fubenIndexId].DoubleText2)
			SweepPage_DoubleCheck:SetToolTip(m_FubenKillBossStr[SweepPage_open_fubenIndexId].DoubleCheck)
			SweepPage_FourText2:SetText(ScriptGlobal_Format("#{GXB_220929_3}", SBSDYuanBao))
			SweepPage_FourCheck:SetToolTip(ScriptGlobal_Format("#{GXB_220929_1}", SBSDYuanBao))
		end
	end
	
	SweepPage_DoubleCheck:Show()
	SweepPage_DoubleText1:Show()
	SweepPage_DoubleText2:Show()

	SweepPage_FourCheck:Show()
	SweepPage_FourText1:Show()
	SweepPage_FourText2:Show()
end

function SweepPage_Update(InSeckill)
	SweepPage_Item_Update()
	
	SweepPage_GoOn:Disable()
	SweepPage_GoOn_tips:Show()
	if SweepPage_open_fubenIndexId == 10 then
		SweepPage_SanUpdate(InSeckill)
		return
	end
	SweepPage_UpdateControl(0)
	
	--显示Boss图标
	local isInSecKill,fubenIndexId,BossIndex,DoubleExp = GetSecKillData()
	
	if isInSecKill == 2 or isInSecKill == 3 then
		isInSecKill = 0
		DoubleExp = 0
		BossIndex = 0
	end

	local BossIcon = {}
	local BossName = {}
	local FubenName, BossMaxNum, CanDoubleExp
	
	if isInSecKill == 1 and fubenIndexId == SweepPage_open_fubenIndexId then
		if DoubleExp == 1 then
			SweepPage_CheckButton[SweepPage_open_fubenIndexId] = 1
		elseif DoubleExp == 2 then
			SweepPage_CheckButton[SweepPage_open_fubenIndexId] = 2
		end
	end
	local b,SBSDYuanBao = LuaFnGetSecKillInfoByFuBenIndexIDEx(SweepPage_open_fubenIndexId, "SBSDYB")
	if nil == SBSDYuanBao then
		return
	end
	
	
	if DoubleExp == 1 then
		SweepPage_DoubleText2:SetText("#{FBSD_150126_74}")
	elseif DoubleExp == 2 then
		SweepPage_FourText2:SetText("#{GXB_220929_10}")
	else
		if nil ~= m_FubenKillBossStr[SweepPage_open_fubenIndexId] then
			SweepPage_DoubleText2:SetText(m_FubenKillBossStr[SweepPage_open_fubenIndexId].DoubleText2)
			SweepPage_FourText2:SetText(ScriptGlobal_Format("#{GXB_220929_3}", SBSDYuanBao))
		end
	end
	
	FubenName,BossMaxNum,BossIcon[1],BossName[1],BossIcon[2],BossName[2],BossIcon[3],BossName[3],BossIcon[4],BossName[4],BossIcon[5],BossName[5],BossIcon[6],BossName[6], CanDoubleExp = Lua_GetSecKillBossIconByFuBenIndexId(SweepPage_open_fubenIndexId)
	
	local strTemp = ScriptGlobal_Format("#{FBSD_150126_26}",FubenName)
	SweepPage_DragTitle:SetText(strTemp)
	
	local KillBossIndex = 1
	if isInSecKill == 1 and fubenIndexId == SweepPage_open_fubenIndexId then
		KillBossIndex = BossIndex + 1
	elseif isInSecKill == 0 and InSeckill == 1 then
		KillBossIndex = BossMaxNum + 1
		SweepPage_GoOn:Enable()
		SweepPage_GoOn_tips:Hide()
	end
	local Msg = ScriptGlobal_Format("#{SDYH_170123_09}",0,0)
	if nil ~= SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId] then
		if SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][1] ~= 0 then
			Msg = ScriptGlobal_Format("#{SDYH_170123_09}",SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][1], SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][2])
		else
			Msg = ScriptGlobal_Format("#{SDYH_170123_09}","#cff0000"..SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][1], SweepPage_FuBenSecKillNum[SweepPage_open_fubenIndexId][2])
		end
	end
	
	SweepPage_Explain_times:SetText(Msg)
	
	for i=1, BossMaxNum do
		SweepPage_BossIcon[i]:Show()
		SweepPage_BossName[i]:Show()
		SweepPage_BossName[i]:SetText("#cfff263"..BossName[i])
		
		if BossIcon[i] ~= nil and BossIcon[i] ~= "" then
				local sPos,_ = string.find(BossIcon[i]," ");
				local IconImageSet = string.sub(BossIcon[i],5,sPos-1);
				local IconIamge = string.sub(BossIcon[i],sPos+7)
				if nil ~= IconImageSet and nil ~= IconIamge then
					SweepPage_BossIcon[i]:SetImage(IconImageSet,IconIamge)
				end
		end
		
		if i < KillBossIndex then
			if KillBossIndex == i + 1 and InSeckill == 1 and SweepPage_curPassIndex ~= KillBossIndex then
				SweepPage_BossingAnimate[i]:Show()
				SweepPage_BossingAnimate[i]:SetToolTip("#{FBSD_150126_30}")
				SweepPage_BossDieIcon[i]:Hide()
				SeeepPage_Timer[i]:SetProperty("Timer", "1.8");
			else
				SweepPage_BossingAnimate[i]:Hide()
				SweepPage_BossDieIcon[i]:Show()
				SweepPage_BossDieIcon[i]:SetToolTip("#{FBSD_150126_30}")
			end
			
			SweepPage_BossButton[i]:Hide()
		elseif i == KillBossIndex then
			SweepPage_BossDieIcon[i]:Hide()
			SweepPage_BossButton[i]:Show()
			SweepPage_BossButton[i]:Enable()
			SweepPage_BossButton[i]:SetToolTip("#{FBSD_150126_29}")
			SweepPage_BossButton[i]:PlayWarning(1)
			SweepPage_BossingAnimate[i]:Hide()
			local strTemp = ScriptGlobal_Format("#{FBSD_150126_81}",BossName[i])
			SweepPage_Explain1:SetText(strTemp)
		else
			SweepPage_BossDieIcon[i]:Hide()
			SweepPage_BossButton[i]:Hide()
			SweepPage_BossIcon[i]:SetToolTip("#{FBSD_150126_28}")
			SweepPage_BossingAnimate[i]:Hide()
		end
	end
	
	for i = BossMaxNum + 1, SweepPage_MaxBoss do
		SweepPage_BossIcon[i]:Hide()
		SweepPage_BossName[i]:Hide()
	end
	
	if isInSecKill == 1 then
		SweepPage_SetDoubleBtnState(1)
	else
		SweepPage_SetDoubleBtnState(0)
	end
	
	if SweepPage_GiveUpCheckButton == 1 then
		SweepPage_AbandonCheckButton:SetCheck(1)
	else
		SweepPage_AbandonCheckButton:SetCheck(0)
	end
	
	if CanDoubleExp == 1 then
		SweepPage_DoubleCheck:Show()
		SweepPage_DoubleText1:Show()
		SweepPage_DoubleText2:Show()

		SweepPage_FourCheck:Show()
		SweepPage_FourText1:Show()
		SweepPage_FourText2:Show()
	else
		SweepPage_DoubleCheck:Hide()
		SweepPage_DoubleText1:Hide()
		SweepPage_DoubleText2:Hide()

		SweepPage_FourCheck:Hide()
		SweepPage_FourText1:Hide()
		SweepPage_FourText2:Hide()
	end

end

function SweepPage_OnBossButton(index)
	if SecKillItemListEmpty() ~=1 then
		PushDebugMessage("#{FBSD_150126_47}")
		return
	end
	local IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp, numYuanbao = Lua_GetSecKillInfoByFuBenIndexID(SweepPage_open_fubenIndexId)
	if nil == IconName then
		return
	end
	local itemID, itemNum = LuaFnGetSecKillInfoByFuBenIndexIDEx(SweepPage_open_fubenIndexId, "Item")
	if nil == itemID or nil == itemNum then
		return
	end
	local isInSecKill,fubenIndexId,BossIndex,DoubleExp = GetSecKillData()	
	if isInSecKill == 0 and index == 1 then
		local doubleOp = 3
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientFuBenSecKillCheck")
			Set_XSCRIPT_ScriptID(891062);
			Set_XSCRIPT_Parameter(0,SweepPage_open_fubenIndexId)
			Set_XSCRIPT_Parameter(1,index)
			local doubleType = 0
			if SweepPage_DoubleCheck:GetCheck() == 1 then
				doubleType = 1
			elseif SweepPage_FourCheck:GetCheck() == 1 then
				doubleType = 2
			end
			Set_XSCRIPT_Parameter(2,doubleType)
			Set_XSCRIPT_Parameter(3,doubleOp)
			Set_XSCRIPT_ParamCount(4);
		Send_XSCRIPT();
	else
		SweepPage_OnBossButtonOld(index)
	end
end
function SweepPage_OnBossButtonOld(index)
	if SecKillItemListEmpty() ~=1 then
		PushDebugMessage("#{FBSD_150126_47}")
		return
	end
	local IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp, numYuanbao = Lua_GetSecKillInfoByFuBenIndexID(SweepPage_open_fubenIndexId)
	if nil == IconName then
		return
	end
	local b,SBSDYuanBao = LuaFnGetSecKillInfoByFuBenIndexIDEx(SweepPage_open_fubenIndexId, "SBSDYB")
	if nil == SBSDYuanBao then
		return
	end
	local isInSecKill,fubenIndexId,BossIndex,DoubleExp = GetSecKillData()	
	local isNeedHightAndLowSeckillNum = 0 --是否需要高级和低级扫荡点
	if isInSecKill == 1 then
		if fubenIndexId ~= SweepPage_open_fubenIndexId then
			PushDebugMessage("#{FBSD_150126_70}")
			return
		end
		
	else
		if index ~= 1 then
			PushDebugMessage("#{FBSD_150126_49}")
			return
		end
		if SecKillNeedNumType == 2 then
			if HightSecKillNum < SecKillNeedNum then
				PushDebugMessage("#{SDXG_20210624_17}")
				return
			end
		elseif SecKillNeedNumType == 1 then
			if LowSecKillNum  + HightSecKillNum < SecKillNeedNum then
				PushDebugMessage("#{SDXG_20210624_16}")
				return
			end
			if LowSecKillNum < SecKillNeedNum then
				isNeedHightAndLowSeckillNum = 1
			end
		else
			return
		end
	end
	if fubenIndexId == 10 then    --三神幻境特写
		if index < 4 then
			if SweepPage_DoubleCheck:GetCheck() == 1 and index == 1 and CanDoubleExp == 1 and isInSecKill == 0 then
				if isNeedHightAndLowSeckillNum ~= 1 then
					PushEvent( "DOUBLE_SECKILL_CONFIRM", 1, index, numYuanbao, SweepPage_open_fubenIndexId ) --消耗元宝
				else
					PushEvent( "DOUBLE_SECKILL_CONFIRM", 2, index, numYuanbao, SweepPage_open_fubenIndexId ) --消耗元宝+消耗低级和高级扫荡点
				end
			elseif SweepPage_FourCheck:GetCheck() == 1 and index == 1 and CanDoubleExp == 1 and isInSecKill == 0 then
				if isNeedHightAndLowSeckillNum ~= 1 then
					PushEvent( "DOUBLE_SECKILL_CONFIRM", 4, index, SBSDYuanBao, SweepPage_open_fubenIndexId) --消耗元宝
				else
					PushEvent( "DOUBLE_SECKILL_CONFIRM", 5, index, SBSDYuanBao, SweepPage_open_fubenIndexId ) --消耗元宝+消耗低级和高级扫荡点
				end
			elseif index == 1 and isInSecKill == 0 and isNeedHightAndLowSeckillNum == 1 then
				PushEvent( "DOUBLE_SECKILL_CONFIRM", 3, index, numYuanbao, SweepPage_open_fubenIndexId ) --消耗低级和高级扫荡点
			else
				SweepPage_DoubleOp = 1
				SweepPage_SendSecKill(index)
			end
			
		elseif index > 3 and index < 7 and isInSecKill == 1 then
			PushEvent( "SECKILL_OPENSANSHENITEM",index)
		end
		
	else
		if SweepPage_DoubleCheck:GetCheck() == 1 and index == 1 and CanDoubleExp == 1 and isInSecKill == 0 then
			if isNeedHightAndLowSeckillNum ~= 1 then
				PushEvent( "DOUBLE_SECKILL_CONFIRM", 1, index, numYuanbao, SweepPage_open_fubenIndexId) --消耗元宝
			else
				PushEvent( "DOUBLE_SECKILL_CONFIRM", 2, index, numYuanbao, SweepPage_open_fubenIndexId ) --消耗元宝+消耗低级和高级扫荡点
			end
		elseif SweepPage_FourCheck:GetCheck() == 1 and index == 1 and CanDoubleExp == 1 and isInSecKill == 0 then
			if isNeedHightAndLowSeckillNum ~= 1 then
				PushEvent( "DOUBLE_SECKILL_CONFIRM", 4, index, SBSDYuanBao, SweepPage_open_fubenIndexId) --消耗元宝
			else
				PushEvent( "DOUBLE_SECKILL_CONFIRM", 5, index, SBSDYuanBao, SweepPage_open_fubenIndexId ) --消耗元宝+消耗低级和高级扫荡点
			end
		elseif index == 1 and isInSecKill == 0 and isNeedHightAndLowSeckillNum == 1 then
				PushEvent( "DOUBLE_SECKILL_CONFIRM", 3, index, numYuanbao, SweepPage_open_fubenIndexId ) --消耗低级和高级扫荡点
		else
			SweepPage_DoubleOp = 1
			SweepPage_SendSecKill(index)
		end
	end
	SweepPage_curPassIndex = index
end
function SweepPage_SanShenSendSecKill(index, DoubleOpenBox)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnFuBenSecKill");
		Set_XSCRIPT_ScriptID(891062);
		Set_XSCRIPT_Parameter(0,SweepPage_open_fubenIndexId);
		Set_XSCRIPT_Parameter(1,index);
		Set_XSCRIPT_Parameter(2,DoubleOpenBox);
		Set_XSCRIPT_Parameter(3,1000);
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT();
	
	SweepPage_BossButton[index]:Disable()
end

function SweepPage_SendSecKill(index) 
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnFuBenSecKill");
		Set_XSCRIPT_ScriptID(891062);
		Set_XSCRIPT_Parameter(0,SweepPage_open_fubenIndexId);
		Set_XSCRIPT_Parameter(1,index);
		local doubleType = 0
		if SweepPage_DoubleCheck:GetCheck() == 1 then
			doubleType = 1
		elseif SweepPage_FourCheck:GetCheck() == 1 then
			doubleType = 2
		end
		Set_XSCRIPT_Parameter(2,doubleType);
		Set_XSCRIPT_Parameter(3,SweepPage_DoubleOp);
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT();
	
	SweepPage_BossButton[index]:Disable()
end

function SweepPage_OnOkClicked()
	SecKillRemoveItem()
end
function SweepPage_SetDoubleBtnState(isInSecKill)
	if isInSecKill == 1 then
		SweepPage_FourCheck:Disable()
		SweepPage_DoubleCheck:Disable()
	else
		SweepPage_FourCheck:Enable()
		SweepPage_DoubleCheck:Enable()
	end
	if SweepPage_CheckButton[SweepPage_open_fubenIndexId] == 1 then
		SweepPage_DoubleCheck:SetCheck(1)
		SweepPage_FourCheck:SetCheck(0)
	elseif SweepPage_CheckButton[SweepPage_open_fubenIndexId] == 2 then
		SweepPage_FourCheck:SetCheck(1)
		SweepPage_DoubleCheck:SetCheck(0)
	else
		SweepPage_DoubleCheck:SetCheck(0)
		SweepPage_FourCheck:SetCheck(0)
	end
	-- PushDebugMessage(isInSecKill.." "..SweepPage_CheckButton[SweepPage_open_fubenIndexId].." "..SweepPage_DoubleCheck:GetCheck().." "..SweepPage_FourCheck:GetCheck())
end
function SweepPage_OnCheckClick(doubleType)	
	if SweepPage_CheckButton[SweepPage_open_fubenIndexId] == doubleType then
		SweepPage_CheckButton[SweepPage_open_fubenIndexId] = 0
	else
		SweepPage_CheckButton[SweepPage_open_fubenIndexId] = doubleType
	end
	SweepPage_SetDoubleBtnState(0)
end

function SweepPage_OnGiveUpCheckClick()
	if SweepPage_GiveUpCheckButton == 1 then
		SweepPage_GiveUpCheckButton = 0
	else
		SweepPage_GiveUpCheckButton = 1
	end
end

function SweepPage_OnTimer(index)
	SweepPage_BossingAnimate[index]:Hide()
	SweepPage_BossDieIcon[index]:Show()
	if SweepPage_open_fubenIndexId == 10 and SweepPage_curPassIndex > 3 then
		SweepPage_BossDieIcon[index]:SetToolTip("#{FBSD_130127_8}")
	else
		SweepPage_BossDieIcon[index]:SetToolTip("#{FBSD_150126_30}")
	end
	
	SeeepPage_Timer[index]:SetProperty("Timer", "-1")
end	

function SweepPage_OnGotoSweepAll()
	-- 动态提示
-- 	if IsInTServer() == 1 then
-- --		PushDebugMessage("#{BHKF_140909_327}")
-- 		return
-- 	end
	-- 打开UI
	OpenSecKillList();
end

function SweepPage_OnGiveUp()
	if SecKillItemListEmpty() ==1 then
		return
	end
	
	if SweepPage_GiveUpCheckButton == 1  then
		PushEvent( "SECKILL_GIVEUP_CONFIRM" )
	else
		SecKillGiveUpItem()
	end
end

function SweepPage_OnContinue()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnContinueFuBenSecKill");
		Set_XSCRIPT_ScriptID(891062);
		Set_XSCRIPT_Parameter(0,SweepPage_open_fubenIndexId);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

function SweepPage_UpdateSeckillNum()
	local SecKillFubenCount = GetSecKillFuBenCount()
	for i = 0, SecKillFubenCount - 1 do
		local Id, IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillMaxNum,SecKillNeedNum,CanDoubleExp, numYuanbao, ActionID, fubenIndexID,gaoxiaofdid,Is2606sHide = EnumSecKillTable(i)
		if nil ~= ActionID and ActionID > 0 then
			local Number = GetCampaignTotalNum(ActionID)
			local Micount = Number - GetCampaignCountNum( ActionID )

			SweepPage_FuBenSecKillNum[fubenIndexID] = {Micount, Number};
		end
	end
end
