-- 界面的默认相对位置
local Fuli_FuBenZhaoHui_Frame_UnifiedXPosition;
local Fuli_FuBenZhaoHui_Frame_UnifiedYPosition;

local Fuli_FuBenZhaoHui_open_fubenId = -1
local Fuli_FuBenZhaoHui_DiKeyNum = 0
local Fuli_FuBenZhaoHui_TianKeyNum = 0

--格子及其编号
local Fuli_FuBenZhaoHui_ITEM_NUM = 12;
local Fuli_FuBenZhaoHui_ITEMS = {};

local Fuli_FuBenZhaoHui_BossIcon = {}
local Fuli_FuBenZhaoHui_BossButton = {}
local Fuli_FuBenZhaoHui_BossingAnimate = {}
local Fuli_FuBenZhaoHui_BossDieIcon = {}
local Fuli_FuBenZhaoHui_BossName = {}
local SeeepPage_Timer = {}

local Fuli_FuBenZhaoHui_MaxBoss = 6

local Fuli_FuBenZhaoHui_CheckButton = {}

local Fuli_FuBenZhaoHui_GiveUpCheckButton = 1

local Fuli_FuBenZhaoHui_curPassIndex = 0

local Fuli_FuBenZhaoHui_FuBense = {}

local Fuli_FuBenZhaoHui_Count =0;
local Fuli_FuBenZhaoHui_MaxCount=0;
local Fuli_FuBenZhaoHui_NeedMoney=0;
function Fuli_FuBenZhaoHui_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REFRESH_ZHAOHUI_PAGE")
	this:RegisterEvent("REFRESH_SECKILL_ITEM")
	this:RegisterEvent("SEND_SECKILL_ZHAOHUI")
end

function Fuli_FuBenZhaoHui_OnLoad()
	Fuli_FuBenZhaoHui_Frame_UnifiedXPosition	= Fuli_FuBenZhaoHui_Frame : GetProperty("UnifiedXPosition");
	Fuli_FuBenZhaoHui_Frame_UnifiedYPosition	= Fuli_FuBenZhaoHui_Frame : GetProperty("UnifiedYPosition");
	
	local SecKillFubenCount = GetSecKillFuBenCount()
	for i = 0, SecKillFubenCount do
		Fuli_FuBenZhaoHui_CheckButton[i] = 0
	end
	
	Fuli_FuBenZhaoHui_ITEMS[1] = Fuli_FuBenZhaoHui_Item1
	Fuli_FuBenZhaoHui_ITEMS[2] = Fuli_FuBenZhaoHui_Item2
	Fuli_FuBenZhaoHui_ITEMS[3] = Fuli_FuBenZhaoHui_Item3
	Fuli_FuBenZhaoHui_ITEMS[4] = Fuli_FuBenZhaoHui_Item4
	Fuli_FuBenZhaoHui_ITEMS[5] = Fuli_FuBenZhaoHui_Item5
	Fuli_FuBenZhaoHui_ITEMS[6] = Fuli_FuBenZhaoHui_Item6
	Fuli_FuBenZhaoHui_ITEMS[7] = Fuli_FuBenZhaoHui_Item7
	Fuli_FuBenZhaoHui_ITEMS[8] = Fuli_FuBenZhaoHui_Item8
	Fuli_FuBenZhaoHui_ITEMS[9] = Fuli_FuBenZhaoHui_Item9
	Fuli_FuBenZhaoHui_ITEMS[10] = Fuli_FuBenZhaoHui_Item10
	Fuli_FuBenZhaoHui_ITEMS[11] = Fuli_FuBenZhaoHui_Item11
	Fuli_FuBenZhaoHui_ITEMS[12] = Fuli_FuBenZhaoHui_Item12
	
	Fuli_FuBenZhaoHui_BossIcon[1] = Fuli_FuBenZhaoHui_Boss1
	Fuli_FuBenZhaoHui_BossIcon[2] = Fuli_FuBenZhaoHui_Boss2
	Fuli_FuBenZhaoHui_BossIcon[3] = Fuli_FuBenZhaoHui_Boss3
	Fuli_FuBenZhaoHui_BossIcon[4] = Fuli_FuBenZhaoHui_Boss4
	Fuli_FuBenZhaoHui_BossIcon[5] = Fuli_FuBenZhaoHui_Boss5
	Fuli_FuBenZhaoHui_BossIcon[6] = Fuli_FuBenZhaoHui_Boss6
	
	Fuli_FuBenZhaoHui_BossButton[1] = Fuli_FuBenZhaoHui_Boss1AnimateImage
	Fuli_FuBenZhaoHui_BossButton[2] = Fuli_FuBenZhaoHui_Boss2AnimateImage
	Fuli_FuBenZhaoHui_BossButton[3] = Fuli_FuBenZhaoHui_Boss3AnimateImage
	Fuli_FuBenZhaoHui_BossButton[4] = Fuli_FuBenZhaoHui_Boss4AnimateImage
	Fuli_FuBenZhaoHui_BossButton[5] = Fuli_FuBenZhaoHui_Boss5AnimateImage
	Fuli_FuBenZhaoHui_BossButton[6] = Fuli_FuBenZhaoHui_Boss6AnimateImage
	
	Fuli_FuBenZhaoHui_BossingAnimate[1] = Fuli_FuBenZhaoHui_Boss1doing
	Fuli_FuBenZhaoHui_BossingAnimate[2] = Fuli_FuBenZhaoHui_Boss2doing
	Fuli_FuBenZhaoHui_BossingAnimate[3] = Fuli_FuBenZhaoHui_Boss3doing
	Fuli_FuBenZhaoHui_BossingAnimate[4] = Fuli_FuBenZhaoHui_Boss4doing
	Fuli_FuBenZhaoHui_BossingAnimate[5] = Fuli_FuBenZhaoHui_Boss5doing
	Fuli_FuBenZhaoHui_BossingAnimate[6] = Fuli_FuBenZhaoHui_Boss6doing
	
	Fuli_FuBenZhaoHui_BossDieIcon[1] = Fuli_FuBenZhaoHui_Boss1finish
	Fuli_FuBenZhaoHui_BossDieIcon[2] = Fuli_FuBenZhaoHui_Boss2finish
	Fuli_FuBenZhaoHui_BossDieIcon[3] = Fuli_FuBenZhaoHui_Boss3finish
	Fuli_FuBenZhaoHui_BossDieIcon[4] = Fuli_FuBenZhaoHui_Boss4finish
	Fuli_FuBenZhaoHui_BossDieIcon[5] = Fuli_FuBenZhaoHui_Boss5finish
	Fuli_FuBenZhaoHui_BossDieIcon[6] = Fuli_FuBenZhaoHui_Boss6finish
	
	Fuli_FuBenZhaoHui_BossName[1] = Fuli_FuBenZhaoHui_Boss1Name
	Fuli_FuBenZhaoHui_BossName[2] = Fuli_FuBenZhaoHui_Boss2Name
	Fuli_FuBenZhaoHui_BossName[3] = Fuli_FuBenZhaoHui_Boss3Name
	Fuli_FuBenZhaoHui_BossName[4] = Fuli_FuBenZhaoHui_Boss4Name
	Fuli_FuBenZhaoHui_BossName[5] = Fuli_FuBenZhaoHui_Boss5Name
	Fuli_FuBenZhaoHui_BossName[6] = Fuli_FuBenZhaoHui_Boss6Name
	
	SeeepPage_Timer[1] = Fuli_FuBenZhaoHui_Boss1_StopWatch
	SeeepPage_Timer[2] = Fuli_FuBenZhaoHui_Boss2_StopWatch
	SeeepPage_Timer[3] = Fuli_FuBenZhaoHui_Boss3_StopWatch
	SeeepPage_Timer[4] = Fuli_FuBenZhaoHui_Boss4_StopWatch
	SeeepPage_Timer[5] = Fuli_FuBenZhaoHui_Boss5_StopWatch
	SeeepPage_Timer[6] = Fuli_FuBenZhaoHui_Boss6_StopWatch
	 
end

-- OnEvent
function Fuli_FuBenZhaoHui_OnEvent(event)
	if (event == "UI_COMMAND" ) then
		if tonumber(arg0) == 2017121701 then
			Fuli_FuBenZhaoHui_open_fubenId = Get_XParam_INT(0) 
			Fuli_FuBenZhaoHui_Count 		= Get_XParam_INT(1)
			Fuli_FuBenZhaoHui_MaxCount 	= Get_XParam_INT(2)
			Fuli_FuBenZhaoHui_NeedMoney 	= Get_XParam_INT(3)  
			
			OpenWindow("Packet")
			this:Show()
			Fuli_FuBenZhaoHui_Update(0)
			
		elseif tonumber(arg0) == 2017121901 then
			if this:IsVisible() then		
				Fuli_FuBenZhaoHui_Update(0)
			end
		elseif tonumber(arg0) == 2017122001 then
			if this:IsVisible() then		
				Fuli_FuBenZhaoHui_Count 	= Get_XParam_INT(0) 
				local Msg = ScriptGlobal_Format("#{XTZY_171213_41}",Fuli_FuBenZhaoHui_Count)
				Fuli_FuBenZhaoHui_Explain_times:SetText(Msg)
			end
		end
		
	elseif (event == "REFRESH_ZHAOHUI_PAGE") then
		if this:IsVisible() then
			Fuli_FuBenZhaoHui_Update(1)
		end
		
	elseif (event == "REFRESH_SECKILL_ITEM") then
		if this:IsVisible() then
			Fuli_FuBenZhaoHui_Item_Update()
		end	
	elseif (event == "SEND_SECKILL_ZHAOHUI") then
		if this:IsVisible() then
			if tonumber(arg0) == 0 then
				Fuli_FuBenZhaoHui_SendSecKill(tonumber(arg1))
			end
		end				
		if tonumber(arg0) == 1 then
			Fuli_FuBenZhaoHui_SanShenSendSecKill(tonumber(arg1), tonumber(arg2))		
		end	
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Fuli_FuBenZhaoHui_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Fuli_FuBenZhaoHui_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Fuli_FuBenZhaoHui_OnClosed()
	end
end

function Fuli_FuBenZhaoHui_Frame_On_ResetPos()
	Fuli_FuBenZhaoHui_Frame : SetProperty("UnifiedXPosition", Fuli_FuBenZhaoHui_Frame_UnifiedXPosition);
	Fuli_FuBenZhaoHui_Frame : SetProperty("UnifiedYPosition", Fuli_FuBenZhaoHui_Frame_UnifiedYPosition);
end

function Fuli_FuBenZhaoHui_OnClosed()
	this:Hide();
	
	for i=1, Fuli_FuBenZhaoHui_MaxBoss do
		SeeepPage_Timer[i]:SetProperty("Timer", "-1");
	end
end

function Fuli_FuBenZhaoHui_Item_Update()
	--显示物品栏的物品
	for i=1, Fuli_FuBenZhaoHui_ITEM_NUM do
		Fuli_FuBenZhaoHui_ITEMS[i]:SetActionItem(-1);
		Fuli_FuBenZhaoHui_ITEMS[i]:Enable();
	end
	
	--从数据池中使用数据填入背包内的物品
	local nActIndex = 0
	
	for i=1, Fuli_FuBenZhaoHui_ITEM_NUM  do
		local theAction = SecKillEnumItem(nActIndex);
		nActIndex = nActIndex+1;

		if theAction:GetID() ~= 0 then
			Fuli_FuBenZhaoHui_ITEMS[i]:SetActionItem(theAction:GetID());
		else
			Fuli_FuBenZhaoHui_ITEMS[i]:SetActionItem(-1);
		end
	end
end

function Fuli_FuBenZhaoHui_UpdateControl(isSanShen)
	if isSanShen == 1 then 
	
		Fuli_FuBenZhaoHui_Boss4:Hide()
		Fuli_FuBenZhaoHui_BossIcon[4] = Fuli_FuBenZhaoHui_Boss4_SanShen
		Fuli_FuBenZhaoHui_BossButton[4] = Fuli_FuBenZhaoHui_Boss4AnimateImage_SanShen
		Fuli_FuBenZhaoHui_BossingAnimate[4] = Fuli_FuBenZhaoHui_Boss4doing_SanShen
		Fuli_FuBenZhaoHui_BossDieIcon[4] = Fuli_FuBenZhaoHui_Boss4finish_SanShen
	
		Fuli_FuBenZhaoHui_Boss5:Hide()
		Fuli_FuBenZhaoHui_BossIcon[5] = Fuli_FuBenZhaoHui_Boss5
		Fuli_FuBenZhaoHui_BossButton[5] = Fuli_FuBenZhaoHui_Boss5AnimateImage
		Fuli_FuBenZhaoHui_BossingAnimate[5] = Fuli_FuBenZhaoHui_Boss5doing
		Fuli_FuBenZhaoHui_BossDieIcon[5] = Fuli_FuBenZhaoHui_Boss5finish
	
		Fuli_FuBenZhaoHui_Boss6:Hide()
		Fuli_FuBenZhaoHui_BossIcon[6] = Fuli_FuBenZhaoHui_Boss6
		Fuli_FuBenZhaoHui_BossButton[6] = Fuli_FuBenZhaoHui_Boss6AnimateImage
		Fuli_FuBenZhaoHui_BossingAnimate[6] = Fuli_FuBenZhaoHui_Boss6doing
		Fuli_FuBenZhaoHui_BossDieIcon[6] = Fuli_FuBenZhaoHui_Boss6finish
		
	else
		Fuli_FuBenZhaoHui_Explain:Show() 
	
		Fuli_FuBenZhaoHui_Boss4_SanShen:Hide()
		Fuli_FuBenZhaoHui_BossIcon[4] = Fuli_FuBenZhaoHui_Boss4
		Fuli_FuBenZhaoHui_BossButton[4] = Fuli_FuBenZhaoHui_Boss4AnimateImage
		Fuli_FuBenZhaoHui_BossingAnimate[4] = Fuli_FuBenZhaoHui_Boss4doing
		Fuli_FuBenZhaoHui_BossDieIcon[4] = Fuli_FuBenZhaoHui_Boss4finish
	
		Fuli_FuBenZhaoHui_BossIcon[5] = Fuli_FuBenZhaoHui_Boss5
		Fuli_FuBenZhaoHui_BossButton[5] = Fuli_FuBenZhaoHui_Boss5AnimateImage
		Fuli_FuBenZhaoHui_BossingAnimate[5] = Fuli_FuBenZhaoHui_Boss5doing
		Fuli_FuBenZhaoHui_BossDieIcon[5] = Fuli_FuBenZhaoHui_Boss5finish
	
		Fuli_FuBenZhaoHui_BossIcon[6] = Fuli_FuBenZhaoHui_Boss6
		Fuli_FuBenZhaoHui_BossButton[6] = Fuli_FuBenZhaoHui_Boss6AnimateImage
		Fuli_FuBenZhaoHui_BossingAnimate[6] = Fuli_FuBenZhaoHui_Boss6doing
		Fuli_FuBenZhaoHui_BossDieIcon[6] = Fuli_FuBenZhaoHui_Boss6finish
	end
end

function Fuli_FuBenZhaoHui_SanUpdate(InSeckill)

	Fuli_FuBenZhaoHui_UpdateControl(1)
 	
	--显示Boss图标
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()
	if isInSecKill == 2 or isInSecKill == 1 then
		isInSecKill = 0
		DoubleExp = 0
		BossIndex = 0
	end
	
	local BossIcon = {}
	local BossName = {}
	local BossMaxNum = 0
	
	--if isInSecKill == 1 and FubenID == Fuli_FuBenZhaoHui_open_fubenId and DoubleExp == 1 then
	--	Fuli_FuBenZhaoHui_CheckButton[Fuli_FuBenZhaoHui_open_fubenId] = 1
	--end
	
	FubenName,BossMaxNum,BossIcon[1],BossName[1],BossIcon[2],BossName[2],BossIcon[3],BossName[3],BossIcon[4],BossName[4],BossIcon[5],BossName[5],BossIcon[6],BossName[6], CanDoubleExp = Lua_GetSecKillBossIconByFuBenIndexId(Fuli_FuBenZhaoHui_open_fubenId)
	
	local strTemp = ScriptGlobal_Format("#{XTZY_171213_99}",FubenName)
	Fuli_FuBenZhaoHui_DragTitle:SetText(strTemp)
	
	for i=1, BossMaxNum do
		Fuli_FuBenZhaoHui_BossIcon[i]:Show()
		Fuli_FuBenZhaoHui_BossName[i]:Show()
		Fuli_FuBenZhaoHui_BossName[i]:SetText("#cfff263"..BossName[i])
		
		if BossIcon[i] ~= nil and BossIcon[i] ~= "" then
			local sPos,_ = string.find(BossIcon[i]," ");
			local IconImageSet = string.sub(BossIcon[i],5,sPos-1);
			local IconIamge = string.sub(BossIcon[i],sPos+7)
			if nil ~= IconImageSet and nil ~= IconIamge then
					Fuli_FuBenZhaoHui_BossIcon[i]:SetImage(IconImageSet,IconIamge)
			end
		end
	end
	
	local Msg = ScriptGlobal_Format("#{XTZY_171213_41}",Fuli_FuBenZhaoHui_Count)
	Fuli_FuBenZhaoHui_Explain_times:SetText(Msg)
	Fuli_FuBenZhaoHui_Explain:SetText(ScriptGlobal_Format("#{XTZY_171213_38}",Fuli_FuBenZhaoHui_NeedMoney,FubenName))
	if isInSecKill == 0 and InSeckill == 1 then--完成阶段
		Fuli_FuBenZhaoHui_GoOn:Enable()
		Fuli_FuBenZhaoHui_GoOn_tips:Hide()
		for i=1, 3 do
			Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
			Fuli_FuBenZhaoHui_BossDieIcon[i]:Show()
			Fuli_FuBenZhaoHui_BossDieIcon[i]:SetToolTip("#{XTZY_171213_45}")
		end
		
		for i=4,6 do
			Fuli_FuBenZhaoHui_BossDieIcon[i]:Hide()
			Fuli_FuBenZhaoHui_BossButton[i]:Hide()
			Fuli_FuBenZhaoHui_BossIcon[i]:SetToolTip("#{XTZY_171213_100}")
			Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
		end
		
		Fuli_FuBenZhaoHui_BossingAnimate[Fuli_FuBenZhaoHui_curPassIndex]:Show()
		Fuli_FuBenZhaoHui_BossingAnimate[Fuli_FuBenZhaoHui_curPassIndex]:SetToolTip("#{FBSD_130127_8}")
		Fuli_FuBenZhaoHui_BossDieIcon[Fuli_FuBenZhaoHui_curPassIndex]:Hide()
		SeeepPage_Timer[Fuli_FuBenZhaoHui_curPassIndex]:SetProperty("Timer", "1.8")
		
		
		--if Fuli_FuBenZhaoHui_curPassIndex == 5 then
		--	Fuli_FuBenZhaoHui_DiKeyNum = Fuli_FuBenZhaoHui_DiKeyNum - 1
		--elseif Fuli_FuBenZhaoHui_curPassIndex == 6 then
		--	Fuli_FuBenZhaoHui_TianKeyNum = Fuli_FuBenZhaoHui_TianKeyNum - 1
		--end
	
	 
	elseif FubenID ~= Fuli_FuBenZhaoHui_open_fubenId or BossIndex < 3 then   --处于扫荡阶段
		local KillBossIndex = 1
		if isInSecKill == 3 and FubenID == Fuli_FuBenZhaoHui_open_fubenId then
			KillBossIndex = BossIndex + 1
		end
			
		for i=1, BossMaxNum do
			if i < KillBossIndex then
				if KillBossIndex == i + 1 and InSeckill == 1 and Fuli_FuBenZhaoHui_curPassIndex ~= KillBossIndex then
					Fuli_FuBenZhaoHui_BossingAnimate[i]:Show()
					Fuli_FuBenZhaoHui_BossingAnimate[i]:SetToolTip("#{XTZY_171213_45}")
					Fuli_FuBenZhaoHui_BossDieIcon[i]:Hide()
					SeeepPage_Timer[i]:SetProperty("Timer", "1.8");
				else
					Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
					Fuli_FuBenZhaoHui_BossDieIcon[i]:Show()
					Fuli_FuBenZhaoHui_BossDieIcon[i]:SetToolTip("#{XTZY_171213_45}")
				end
			
				Fuli_FuBenZhaoHui_BossButton[i]:Hide()
			elseif i == KillBossIndex then
				Fuli_FuBenZhaoHui_BossDieIcon[i]:Hide()
				Fuli_FuBenZhaoHui_BossButton[i]:Show()
				Fuli_FuBenZhaoHui_BossButton[i]:Enable()
				Fuli_FuBenZhaoHui_BossButton[i]:SetToolTip("#{XTZY_171213_44}")
				Fuli_FuBenZhaoHui_BossButton[i]:PlayWarning(1)
				Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
				local strTemp = ScriptGlobal_Format("#{XTZY_171213_39}",BossName[i])
				Fuli_FuBenZhaoHui_Explain1:SetText(strTemp)
			else
				Fuli_FuBenZhaoHui_BossDieIcon[i]:Hide()
				Fuli_FuBenZhaoHui_BossButton[i]:Hide()
				if i < 4 then
					Fuli_FuBenZhaoHui_BossIcon[i]:SetToolTip("#{XTZY_171213_43}")
				else
					Fuli_FuBenZhaoHui_BossIcon[i]:SetToolTip("#{FBSD_130127_4}")
				end
				Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
			end
		end
		
	elseif BossIndex == 3 then  --开宝箱阶段
		for i=1, 2 do
			Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
			Fuli_FuBenZhaoHui_BossDieIcon[i]:Show()
			Fuli_FuBenZhaoHui_BossDieIcon[i]:SetToolTip("#{XTZY_171213_45}")
			Fuli_FuBenZhaoHui_BossButton[i]:Hide()
		end
		
		if Fuli_FuBenZhaoHui_curPassIndex == 3 then
			Fuli_FuBenZhaoHui_BossingAnimate[3]:Show()
			Fuli_FuBenZhaoHui_BossingAnimate[3]:SetToolTip("#{XTZY_171213_45}")
			Fuli_FuBenZhaoHui_BossDieIcon[3]:Hide()
			SeeepPage_Timer[3]:SetProperty("Timer", "1.8")
			Fuli_FuBenZhaoHui_BossButton[3]:Hide()
		else
			Fuli_FuBenZhaoHui_BossingAnimate[3]:Hide()
			Fuli_FuBenZhaoHui_BossDieIcon[3]:Show()
			Fuli_FuBenZhaoHui_BossDieIcon[3]:SetToolTip("#{XTZY_171213_45}")
			Fuli_FuBenZhaoHui_BossButton[3]:Hide()
		end 
		
		local tips = { [4] = "#{FBSD_130127_5}", [5] = "#{FBSD_130127_6}", [6] = "#{FBSD_130127_7}"}
		
		for i = 4, 6 do
			Fuli_FuBenZhaoHui_BossDieIcon[i]:Hide()
			Fuli_FuBenZhaoHui_BossButton[i]:Show()
			Fuli_FuBenZhaoHui_BossButton[i]:Enable()
			Fuli_FuBenZhaoHui_BossButton[i]:SetToolTip(tips[i])
			Fuli_FuBenZhaoHui_BossButton[i]:PlayWarning(1)
			Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
		end
		
		Fuli_FuBenZhaoHui_Explain1:SetText("#{FBSD_130127_2}")
	end	
	 
	
	if Fuli_FuBenZhaoHui_GiveUpCheckButton == 1 then
		Fuli_FuBenZhaoHui_AbandonCheckButton:SetCheck(1)
	else
		Fuli_FuBenZhaoHui_AbandonCheckButton:SetCheck(0)
	end
	
end

function Fuli_FuBenZhaoHui_Update(InSeckill)
	Fuli_FuBenZhaoHui_Item_Update()
	
	Fuli_FuBenZhaoHui_GoOn:Disable()
	Fuli_FuBenZhaoHui_GoOn_tips:Show()
	if Fuli_FuBenZhaoHui_open_fubenId == 10 then
		Fuli_FuBenZhaoHui_SanUpdate(InSeckill)
		return
	end
	
	Fuli_FuBenZhaoHui_UpdateControl(0)
	
	--显示Boss图标
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()
	
	if isInSecKill == 2 or isInSecKill == 1 then
		isInSecKill = 0
		DoubleExp = 0
		BossIndex = 0
	end
	
	local BossIcon = {}
	local BossName = {}
	local BossMaxNum = 0
	 
	FubenName,BossMaxNum,BossIcon[1],BossName[1],BossIcon[2],BossName[2],BossIcon[3],BossName[3],BossIcon[4],BossName[4],BossIcon[5],BossName[5],BossIcon[6],BossName[6], CanDoubleExp = Lua_GetSecKillBossIconByFuBenIndexId(Fuli_FuBenZhaoHui_open_fubenId)
	
	local strTemp = ScriptGlobal_Format("#{XTZY_171213_99}",FubenName)
	Fuli_FuBenZhaoHui_DragTitle:SetText(strTemp)
	Fuli_FuBenZhaoHui_Explain:SetText(ScriptGlobal_Format("#{XTZY_171213_38}",Fuli_FuBenZhaoHui_NeedMoney,FubenName))
	
	local KillBossIndex = 1
	if isInSecKill == 3 and FubenID == Fuli_FuBenZhaoHui_open_fubenId then
		KillBossIndex = BossIndex + 1
	elseif isInSecKill == 0 and InSeckill == 1 then
		KillBossIndex = BossMaxNum + 1
		Fuli_FuBenZhaoHui_GoOn:Enable()
		Fuli_FuBenZhaoHui_GoOn_tips:Hide()
	end
		
	local Msg = ScriptGlobal_Format("#{XTZY_171213_41}",Fuli_FuBenZhaoHui_Count)
	
	Fuli_FuBenZhaoHui_Explain_times:SetText(Msg)
	
	for i=1, BossMaxNum do
		Fuli_FuBenZhaoHui_BossIcon[i]:Show()
		Fuli_FuBenZhaoHui_BossName[i]:Show()
		Fuli_FuBenZhaoHui_BossName[i]:SetText("#cfff263"..BossName[i])
		
		if BossIcon[i] ~= nil and BossIcon[i] ~= "" then
				local sPos,_ = string.find(BossIcon[i]," ");
				local IconImageSet = string.sub(BossIcon[i],5,sPos-1);
				local IconIamge = string.sub(BossIcon[i],sPos+7)
				if nil ~= IconImageSet and nil ~= IconIamge then
					Fuli_FuBenZhaoHui_BossIcon[i]:SetImage(IconImageSet,IconIamge)
				end
		end
		
		if i < KillBossIndex then
			if KillBossIndex == i + 1 and InSeckill == 1 and Fuli_FuBenZhaoHui_curPassIndex ~= KillBossIndex then
				Fuli_FuBenZhaoHui_BossingAnimate[i]:Show()
				Fuli_FuBenZhaoHui_BossingAnimate[i]:SetToolTip("#{XTZY_171213_45}")
				Fuli_FuBenZhaoHui_BossDieIcon[i]:Hide()
				SeeepPage_Timer[i]:SetProperty("Timer", "1.8");
			else
				Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
				Fuli_FuBenZhaoHui_BossDieIcon[i]:Show()
				Fuli_FuBenZhaoHui_BossDieIcon[i]:SetToolTip("#{XTZY_171213_45}")
			end
			
			Fuli_FuBenZhaoHui_BossButton[i]:Hide()
		elseif i == KillBossIndex then
			Fuli_FuBenZhaoHui_BossDieIcon[i]:Hide()
			Fuli_FuBenZhaoHui_BossButton[i]:Show()
			Fuli_FuBenZhaoHui_BossButton[i]:Enable()
			Fuli_FuBenZhaoHui_BossButton[i]:SetToolTip("#{XTZY_171213_44}")
			Fuli_FuBenZhaoHui_BossButton[i]:PlayWarning(1)
			Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
			local strTemp = ScriptGlobal_Format("#{XTZY_171213_39}",BossName[i])
			Fuli_FuBenZhaoHui_Explain1:SetText(strTemp)
		else
			Fuli_FuBenZhaoHui_BossDieIcon[i]:Hide()
			Fuli_FuBenZhaoHui_BossButton[i]:Hide()
			Fuli_FuBenZhaoHui_BossIcon[i]:SetToolTip("#{XTZY_171213_43}")
			Fuli_FuBenZhaoHui_BossingAnimate[i]:Hide()
		end
	end
	
	for i = BossMaxNum + 1, Fuli_FuBenZhaoHui_MaxBoss do
		Fuli_FuBenZhaoHui_BossIcon[i]:Hide()
		Fuli_FuBenZhaoHui_BossName[i]:Hide()
	end
	 
	
	if Fuli_FuBenZhaoHui_GiveUpCheckButton == 1 then
		Fuli_FuBenZhaoHui_AbandonCheckButton:SetCheck(1)
	else
		Fuli_FuBenZhaoHui_AbandonCheckButton:SetCheck(0)
	end
	 
	 
end

function Fuli_FuBenZhaoHui_OnBossButton(index)
	if SecKillItemListEmpty() ~=1 then
		PushDebugMessage("#{XTZY_171213_102}")
		return
	end
	
	local IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp, numYuanbao = Lua_GetSecKillInfoByFuBenIndexID(Fuli_FuBenZhaoHui_open_fubenId)
	
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()	
	if isInSecKill == 3 then
		if FubenID ~= Fuli_FuBenZhaoHui_open_fubenId then
			PushDebugMessage("#{XTZY_171213_103}")
			return
		end
		
	else
		if index ~= 1 then
			PushDebugMessage("#{XTZY_171213_73}")
			return
		end
	end
	
	if FubenID == 10 then    --三神幻境特写		
		Fuli_FuBenZhaoHui_DiKeyNum 		= PlayerPackage:CountAvailableItemByIDTable(38001515) 
		Fuli_FuBenZhaoHui_TianKeyNum 	= PlayerPackage:CountAvailableItemByIDTable(38001514)
		if index < 4 then 
				Fuli_FuBenZhaoHui_SendSecKill(index) 
		elseif index > 3 and index < 7 and isInSecKill == 3 then
			Fuli_FuBenZhaoHui_SanShenSendSecKill(index, 0)
		end
		
	else 
			Fuli_FuBenZhaoHui_SendSecKill(index) 
	end
	
	Fuli_FuBenZhaoHui_curPassIndex = index
end

function Fuli_FuBenZhaoHui_SanShenSendSecKill(index, DoubleOpenBox)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnFuBenSecKill");
		Set_XSCRIPT_ScriptID(892659);
		Set_XSCRIPT_Parameter(0,Fuli_FuBenZhaoHui_open_fubenId);
		Set_XSCRIPT_Parameter(1,index);
		Set_XSCRIPT_Parameter(2,DoubleOpenBox);
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
	
	Fuli_FuBenZhaoHui_BossButton[index]:Disable()
end

function Fuli_FuBenZhaoHui_SendSecKill(index) 
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnFuBenSecKill");
		Set_XSCRIPT_ScriptID(892659);
		Set_XSCRIPT_Parameter(0,Fuli_FuBenZhaoHui_open_fubenId);
		Set_XSCRIPT_Parameter(1,index);
		Set_XSCRIPT_Parameter(2,0);--Fuli_FuBenZhaoHui_DoubleCheck:GetCheck()
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
	
	Fuli_FuBenZhaoHui_BossButton[index]:Disable()
end

function Fuli_FuBenZhaoHui_OnOkClicked()
	SecKillRemoveItem()
end

function Fuli_FuBenZhaoHui_OnCheckClick()	
	if Fuli_FuBenZhaoHui_open_fubenId >= 0  and Fuli_FuBenZhaoHui_open_fubenId < table.getn(Fuli_FuBenZhaoHui_CheckButton) then
		if Fuli_FuBenZhaoHui_CheckButton[Fuli_FuBenZhaoHui_open_fubenId] == 1 then
			Fuli_FuBenZhaoHui_CheckButton[Fuli_FuBenZhaoHui_open_fubenId] = 0
		else
			Fuli_FuBenZhaoHui_CheckButton[Fuli_FuBenZhaoHui_open_fubenId] = 1
		end
	end
end

function Fuli_FuBenZhaoHui_OnGiveUpCheckClick()
	if Fuli_FuBenZhaoHui_GiveUpCheckButton == 1 then
		Fuli_FuBenZhaoHui_GiveUpCheckButton = 0
	else
		Fuli_FuBenZhaoHui_GiveUpCheckButton = 1
	end
end

function Fuli_FuBenZhaoHui_OnTimer(index)
	Fuli_FuBenZhaoHui_BossingAnimate[index]:Hide()
	Fuli_FuBenZhaoHui_BossDieIcon[index]:Show()
	if Fuli_FuBenZhaoHui_open_fubenId == 10 and Fuli_FuBenZhaoHui_curPassIndex > 3 then
		Fuli_FuBenZhaoHui_BossDieIcon[index]:SetToolTip("#{FBSD_130127_8}")
	else
		Fuli_FuBenZhaoHui_BossDieIcon[index]:SetToolTip("#{XTZY_171213_45}")
	end
	
	SeeepPage_Timer[index]:SetProperty("Timer", "-1")
end	

function Fuli_FuBenZhaoHui_OnGotoSweepAll()
	-- 动态提示
	if IsInTServer() == 1 then
--		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	-- 打开UI
	OpenSecKillList();
end

function Fuli_FuBenZhaoHui_OnGiveUp()
	if SecKillItemListEmpty() ==1 then
		return
	end
	
	if Fuli_FuBenZhaoHui_GiveUpCheckButton == 1  then
		PushEvent( "SECKILL_GIVEUP_CONFIRM_ZHAOHUI" )
	else
		SecKillGiveUpItem()
	end
end

function Fuli_FuBenZhaoHui_OnContinue() 
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("RequestGetFuBenBack");
		Set_XSCRIPT_ScriptID(892659);
		Set_XSCRIPT_Parameter(0,Fuli_FuBenZhaoHui_open_fubenId);
		Set_XSCRIPT_Parameter(1,1);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

function Fuli_FuBenZhaoHui_ZhaoHuiOther() 
	OpenZhaoHui(1)
	this:Hide()
end

function Fuli_FuBenZhaoHui_UpdateSeckillNum()
	--local SecKillFubenCount = GetSecKillFuBenCount()
	--for i = 0, SecKillFubenCount - 1 do
	--	local Id, IconName,FubenName,needLevel,SecKillNum,SecKillMaxNum,SecKillNeedNum,CanDoubleExp, numYuanbao, ActionID = EnumSecKillTable(i)
	--
	--	local Number = GetCampaignTotalNum(ActionID)
	--	local Micount = Number - GetCampaignCountNum( ActionID )
  --
	--	--四绝庄特写
	--	if ActionID == 119 or ActionID == 118 then
	--		Number = Number - 1
	--		Micount = Micount - 1
	--		if Micount < 0 then
	--			Micount = 0
	--		end
	--	end
	--	
	--	Fuli_FuBenZhaoHui_FuBenSecKillNum[Id-1] = {Micount, Number};
	--end
end

function Fuli_FuBenZhaoHui_Button_Clicked(index)
	PushEvent("OPEN_Fuli_FuBenZhaoHui_QUEST", "Fuli_FuBenZhaoHui")
end