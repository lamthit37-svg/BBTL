--******************************************************************************
-- 青梅煮酒活动划拳界面 by 李梦月
--******************************************************************************
local g_Qingmeihuaquan_Frame_UnifiedXPosition;
local g_Qingmeihuaquan_Frame_UnifiedYPosition;

local g_Qingmeihuaquan_BeginTime = 20220328
local g_Qingmeihuaquan_EndTime = 20220424
local g_Qingmeihuaquan_LimitLevel = 30
local g_Qingmeihuaquan_QiaoFengID = 48160
local g_Qingmeihuaquan_XuZhuID = 48161
local g_Qingmeihuaquan_DuanYuId = 48159
local g_Qingmeihuaquan_ButtonCDTime = 3 	--按钮冷却时间
local g_Qingmeihuaquan_ButtonLastTime = 0
local g_Qingmeihuaquan_CurPNCIndex = 0
local g_Qingmeihuaquan_CurPNCID = 0
local g_Qingmeihuaquan_CurSelect = 0 --3石头 2剪刀 1布
--缓存数据
local g_Qingmeihuaquan_IsShowLastResult = false
local g_Qingmeihuaquan_Result = 0 --1 默认显示 2赢 3平  4输
local g_Qingmeihuaquan_RewardId1 = 0 --奖励物品1的ID
local g_Qingmeihuaquan_RewardNum1 = 0 --奖励物品1的num
local g_Qingmeihuaquan_RewardId2 = 0 --奖励物品2的ID

--关心NPc
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1

--控件
local g_Qingmeihuaquan_NPCName
local g_Qingmeihuaquan_NPCPic
local g_Qingmeihuaquan_NPCPicAnime
local g_Qingmeihuaquan_NPCBK

local g_Qingmeihuaquan_PlayName
local g_Qingmeihuaquan_PlayPic
local g_Qingmeihuaquan_PlayPicAnime
local g_Qingmeihuaquan_PlayBK
local g_Qingmeihuaquan_ResultAnime
local g_Qingmeihuaquan_Button = {}
local Qingmeihuaquan_Result = {}


--===============================================
-- OnLoad()
--===============================================
function Qingmeihuaquan_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function Qingmeihuaquan_OnLoad()
	-- 保存界面的默认相对位置
	g_Qingmeihuaquan_Frame_UnifiedXPosition = Qingmeihuaquan_Frame:GetProperty("UnifiedXPosition");
	g_Qingmeihuaquan_Frame_UnifiedYPosition = Qingmeihuaquan_Frame:GetProperty("UnifiedYPosition");
	g_Qingmeihuaquan_CurPNCID = 0
	g_Qingmeihuaquan_CurPNCIndex = 0
	
	--青梅划拳
	g_Qingmeihuaquan_NPCName = Qingmeihuaquan_NPC_Name
	g_Qingmeihuaquan_NPCPic = Qingmeihuaquan_NPC_Pic
	g_Qingmeihuaquan_NPCPicAnime = Qingmeihuaquan_NPC_Pic_Animate
	g_Qingmeihuaquan_NPCBK = Qingmeihuaquan_NPC_BK

	g_Qingmeihuaquan_PlayName = Qingmeihuaquan_Player_Name
	g_Qingmeihuaquan_PlayPic = Qingmeihuaquan_Player_Pic
	g_Qingmeihuaquan_PlayPicAnime = Qingmeihuaquan_Player_Pic_Animate
	g_Qingmeihuaquan_PlayBK = Qingmeihuaquan_Player_BK
	
	g_Qingmeihuaquan_ResultAnime = Qingmeihuaquan_Result_Animate

	g_Qingmeihuaquan_Button[1] = Qingmeihuaquan_Player_Pick1
	g_Qingmeihuaquan_Button[2] = Qingmeihuaquan_Player_Pick2
	g_Qingmeihuaquan_Button[3] = Qingmeihuaquan_Player_Pick3
	
	--猜拳结果
	Qingmeihuaquan_Result[1] = Qingmeihuaquan_Result_Begin
	Qingmeihuaquan_Result[2] = Qingmeihuaquan_Result_Win
	Qingmeihuaquan_Result[3] = Qingmeihuaquan_Result_Draw
	Qingmeihuaquan_Result[4] = Qingmeihuaquan_Result_Lose
	
	--kill timer
	--KillTimer("QingmeihuaquanResult()")
end


--===============================================
-- OnEvent()
--===============================================

function Qingmeihuaquan_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 89272001) then
		if(IsWindowShow("Qingmeizhujiu")) then
			CloseWindow("Qingmeizhujiu", true)
		end

		local curDay = tonumber(DataPool:GetServerDayTime());
		local nLevel = Player:GetLevel();
		if curDay < g_Qingmeihuaquan_BeginTime or curDay > g_Qingmeihuaquan_EndTime or nLevel < g_Qingmeihuaquan_LimitLevel then
			return
		end		
		--添加NPC关心
		objCared = DataPool : GetNPCIDByServerID(Get_XParam_INT(0));
		Qingmeihuaquan_BeginCareObject(objCared)
		this:Show()
		
		--判断是都需要显示上次结果
		--如果这次打开npc和上次一样 并且有上次结果数据需要显示上次结果
		if g_Qingmeihuaquan_CurPNCID == Get_XParam_INT(1) and g_Qingmeihuaquan_Result > 1 then
			g_Qingmeihuaquan_IsShowLastResult = true
		else
			g_Qingmeihuaquan_CurPNCIndex = 0
			g_Qingmeihuaquan_CurPNCID = 0
			g_Qingmeihuaquan_CurSelect = 0
			g_Qingmeihuaquan_IsShowLastResult = false
			g_Qingmeihuaquan_Result = 0
			g_Qingmeihuaquan_RewardId1 = 0 --奖励物品1的ID
			g_Qingmeihuaquan_RewardNum1 = 0 --奖励物品1的num
			g_Qingmeihuaquan_RewardId2 = 0 --奖励物品2的ID
		end
		
		Open_Qingmeihuaquan(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2))
	end
	
	if(event == "UI_COMMAND" and tonumber(arg0) == 89272002) then
	
		--先播放动画 再显示结果和弹出tips
		g_Qingmeihuaquan_IsShowLastResult = false
		g_Qingmeihuaquan_Result = Get_XParam_INT(0) + 1 
		g_Qingmeihuaquan_RewardId1 = Get_XParam_INT(1) --奖励物品1的ID
		g_Qingmeihuaquan_RewardNum1 = Get_XParam_INT(2) --奖励物品1的num
		g_Qingmeihuaquan_RewardId2 = Get_XParam_INT(3) --奖励物品2的ID
		QingmeihuaquanResultAnime(g_Qingmeihuaquan_Result, Get_XParam_INT(4))
	end
	
	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Qingmeihuaquan_OnHide()
		end
	end
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Qingmeihuaquan_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Qingmeihuaquan_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		g_Qingmeihuaquan_CurPNCIndex = 0
		g_Qingmeihuaquan_CurPNCID = 0
		g_Qingmeihuaquan_CurSelect = 0
		g_Qingmeihuaquan_IsShowLastResult = false
		g_Qingmeihuaquan_Result = 0
		g_Qingmeihuaquan_RewardId1 = 0 --奖励物品1的ID
		g_Qingmeihuaquan_RewardNum1 = 0 --奖励物品1的num
		g_Qingmeihuaquan_RewardId2 = 0 --奖励物品2的ID
		this:Hide();
	end
end
	
	
--===============================================
-- OnHiden
--===============================================
function Qingmeihuaquan_OnHide()

	Qingmeihuaquan_StopCareObject()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Qingmeihuaquan_Frame_On_ResetPos()
	Qingmeihuaquan_Frame : SetProperty("UnifiedXPosition", g_Qingmeihuaquan_Frame_UnifiedXPosition);
	Qingmeihuaquan_Frame : SetProperty("UnifiedYPosition", g_Qingmeihuaquan_Frame_UnifiedYPosition);
end


--**********************************************
--初始化界面
--**********************************************
function Open_Qingmeihuaquan(nNPCIndex,nNpcTypeId, nJiuNum)
	g_Qingmeihuaquan_CurPNCIndex = nNPCIndex
	g_Qingmeihuaquan_CurPNCID = nNpcTypeId
	--初始化界面
	local nNPCName= ScriptGlobal_Format("#{QMZJ_180308_88}", TServerUI:GetMonsterNamebyDataID(g_Qingmeihuaquan_CurPNCID))
	g_Qingmeihuaquan_NPCName:SetText(nNPCName)

	local strJiuNum = ScriptGlobal_Format("#{QMZJ_200217_31}", tostring(nJiuNum))
	Qingmeihuaquan_Player_CoverIconNum:SetText(strJiuNum)
	
	if g_Qingmeihuaquan_IsShowLastResult == false then
		--npc默认显示
		g_Qingmeihuaquan_NPCBK:Show()
		g_Qingmeihuaquan_NPCPic:Hide()
		g_Qingmeihuaquan_NPCPicAnime:Play(false)
		g_Qingmeihuaquan_NPCPicAnime:Hide()

		--玩家默认显示
		local nName = ScriptGlobal_Format("#{QMZJ_180308_89}", Player:GetName())
		--g_Qingmeihuaquan_PlayName:SetText(nName)
		g_Qingmeihuaquan_PlayBK:Show()
		g_Qingmeihuaquan_PlayPic:Hide()
		g_Qingmeihuaquan_PlayPicAnime:Play(false)
		g_Qingmeihuaquan_PlayPicAnime:Hide()
	
		g_Qingmeihuaquan_ResultAnime:Hide()
		g_Qingmeihuaquan_ResultAnime:Play(false)
		--猜拳结果默认显示
		QingmeihuaquanPic(1)
	else 
		QingmeihuaquanResult()
	end

end

--**********************************************
--玩家猜拳结果显示
--1 默认显示 2赢 3平  4输
--g_Qingmeihuaquan_CurSelect--3石头 2剪刀 1布
--**********************************************
function QingmeihuaquanResultAnime(nIndex, nJiuNum)
	if nIndex < 2 or nIndex > 4 then
		return
	end
	
	--替换PK
	QingmeihuaquanPic(1)
	
	--隐藏pic和bk
	g_Qingmeihuaquan_PlayBK:Hide()
	g_Qingmeihuaquan_NPCBK:Hide()
	g_Qingmeihuaquan_PlayPic:Hide()
	g_Qingmeihuaquan_NPCPic:Hide()
	
	--根据结果播放对应动画
	if nIndex== 2 then	--赢
		if g_Qingmeihuaquan_CurSelect == 3 then --3石头
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRS")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLJ")
		elseif g_Qingmeihuaquan_CurSelect == 2 then --2剪刀
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRJ")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLB")
		elseif g_Qingmeihuaquan_CurSelect == 1 then  --1布
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRB")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLS")
		end
	elseif nIndex== 3 then	--平
		if g_Qingmeihuaquan_CurSelect == 3 then --3石头
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRS")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLS")
		elseif g_Qingmeihuaquan_CurSelect == 2 then --2剪刀
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRJ")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLJ")
		elseif g_Qingmeihuaquan_CurSelect == 1 then  --1布
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRB")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLB")
		end
	elseif nIndex== 4 then	--输
		if g_Qingmeihuaquan_CurSelect == 3 then --3石头
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRS")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLB")
		elseif g_Qingmeihuaquan_CurSelect == 2 then --2剪刀
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRJ")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLS")
		elseif g_Qingmeihuaquan_CurSelect == 1 then  --1布
			g_Qingmeihuaquan_PlayPicAnime:SetProperty("Animate", "HuaquanRB")
			g_Qingmeihuaquan_NPCPicAnime:SetProperty("Animate", "HuaquanLBJ")
		end
	end
	
	g_Qingmeihuaquan_NPCPicAnime:Show()
	g_Qingmeihuaquan_NPCPicAnime:Play(true)
	g_Qingmeihuaquan_PlayPicAnime:Show()
	g_Qingmeihuaquan_PlayPicAnime:Play(true)
	
	SetTimer("Qingmeihuaquan","QingmeihuaquanResult()", 1000)
	
	local strJiuNum = ScriptGlobal_Format("#{QMZJ_200217_31}", tostring(nJiuNum))
	Qingmeihuaquan_Player_CoverIconNum:SetText(strJiuNum)
end

--**********************************************
--玩家猜拳结果显示
--1 默认显示 2赢 3平  4输
--**********************************************
function QingmeihuaquanPic(nIndex)

	if nIndex < 1 or nIndex > 4 then
		return
	end
	--猜拳结果显示
	for index=1,table.getn(Qingmeihuaquan_Result)  do	
		if index == nIndex then
			Qingmeihuaquan_Result[index]:Show()
		else
			Qingmeihuaquan_Result[index]:Hide()
		end 
	end
end


--**********************************************
--玩家猜拳结果显示
--1 默认显示 2赢 3平  4输
--g_Qingmeihuaquan_CurSelect--3石头 2剪刀 1布
--**********************************************
function QingmeihuaquanResult()
	--kill timer
	KillTimer("QingmeihuaquanResult()")
	
	if g_Qingmeihuaquan_Result < 1 or g_Qingmeihuaquan_Result > 4 then
		return
	end
	
	--显示胜负
	QingmeihuaquanPic(g_Qingmeihuaquan_Result)

	--设置各自图片显示
	if g_Qingmeihuaquan_Result== 2 then	--赢
		if g_Qingmeihuaquan_CurSelect == 3 then --3石头
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_SHI")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_JIAN")
		elseif g_Qingmeihuaquan_CurSelect == 2 then --2剪刀
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_JIAN")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_BU")
		elseif g_Qingmeihuaquan_CurSelect == 1 then  --1布
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_BU")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_SHI")
		end
	elseif g_Qingmeihuaquan_Result== 3 then	--平
		if g_Qingmeihuaquan_CurSelect == 3 then --3石头
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_SHI")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_SHI")
		elseif g_Qingmeihuaquan_CurSelect == 2 then --2剪刀
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_JIAN")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_JIAN")
		elseif g_Qingmeihuaquan_CurSelect == 1 then  --1布
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_BU")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_BU")
		end
	elseif g_Qingmeihuaquan_Result== 4 then	--输
		if g_Qingmeihuaquan_CurSelect == 3 then --3石头
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_SHI")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_BU")
		elseif g_Qingmeihuaquan_CurSelect == 2 then --2剪刀
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_JIAN")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_SHI")
		elseif g_Qingmeihuaquan_CurSelect == 1 then  --1布
			g_Qingmeihuaquan_PlayPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiR_BU")
			g_Qingmeihuaquan_NPCPic:SetProperty("Image", "set:Qingmeizhujiu2 image:QingmeiL_JIAN")
		end
	end
	
	--停止动画
	g_Qingmeihuaquan_NPCPicAnime:Hide()
	g_Qingmeihuaquan_NPCPicAnime:Play(false)
	g_Qingmeihuaquan_PlayPicAnime:Hide()
	g_Qingmeihuaquan_PlayPicAnime:Play(false)
	
	--pic和bk设置
	g_Qingmeihuaquan_PlayBK:Hide()
	g_Qingmeihuaquan_NPCBK:Hide()
	g_Qingmeihuaquan_PlayPic:Show()
	g_Qingmeihuaquan_NPCPic:Show()
	
	if  g_Qingmeihuaquan_IsShowLastResult == false then	
	
		g_Qingmeihuaquan_ResultAnime:Show()
		g_Qingmeihuaquan_ResultAnime:Play(true)
		--2赢 3平  4输
		local nNPCName= ""
		if g_Qingmeihuaquan_CurPNCID == g_Qingmeihuaquan_DuanYuId then	--段誉
			nNPCName = "段誉"
		elseif g_Qingmeihuaquan_CurPNCID == g_Qingmeihuaquan_QiaoFengID then --乔峰
			nNPCName = "乔峰"
		elseif g_Qingmeihuaquan_CurPNCID == g_Qingmeihuaquan_XuZhuID then --虚竹
			nNPCName = "虚竹"
		end
		if g_Qingmeihuaquan_Result == 2 then
			PushDebugMessage( ScriptGlobal_Format("#{QMZJ_180308_116}", nNPCName))
		elseif g_Qingmeihuaquan_Result == 3 then
			PushDebugMessage( ScriptGlobal_Format("#{QMZJ_180308_117}", nNPCName))
		elseif g_Qingmeihuaquan_Result == 4 then
			PushDebugMessage( ScriptGlobal_Format("#{QMZJ_180308_115}", nNPCName))
		end
		
		--弹出tips
		if g_Qingmeihuaquan_RewardId2 > 0 then
			local itemname2 = PlayerPackage:GetItemName(g_Qingmeihuaquan_RewardId2)
			PushDebugMessage( ScriptGlobal_Format("#{QMZJ_180308_69}", 1,itemname2))
		end
		if g_Qingmeihuaquan_RewardId1 > 0 and g_Qingmeihuaquan_RewardNum1 > 0 then
			local itemname = DataPool:Lua_GetItemNameByIndex(g_Qingmeihuaquan_RewardId1)
			PushDebugMessage( ScriptGlobal_Format("#{QMZJ_180308_69}", g_Qingmeihuaquan_RewardNum1,itemname))
		end
	end
end


--**********************************************
--玩家猜拳选择
--**********************************************
function QingmeihuaquanSelect(nIndex)
	
	--玩家点击猜拳
	if nIndex < 1 or nIndex > 3  or g_Qingmeihuaquan_CurPNCID == 0 then
		return
	end
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel();
	if curDay < g_Qingmeihuaquan_BeginTime or curDay > g_Qingmeihuaquan_EndTime then
		PushDebugMessage("#{QMZJ_180308_92}"); --当前不是活动时间，无法与英雄猜拳。
		return
	end		
	
	if nLevel < g_Qingmeihuaquan_LimitLevel then
		PushDebugMessage("#{QMZJ_180308_93}"); --您没有达到30级，无法与英雄猜拳
		return
	end
	
	--猜拳按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Qingmeihuaquan_ButtonLastTime < g_Qingmeihuaquan_ButtonCDTime * 1000) then
		PushDebugMessage("#{SZRSYH_180115_01}"); --当前操作过快，请稍后点击
		return
	end
	g_Qingmeihuaquan_ButtonLastTime = curTime;
	
	g_Qingmeihuaquan_CurSelect = nIndex
	--请求结果
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetHuaquanResult")
		Set_XSCRIPT_ScriptID( 892720)
		Set_XSCRIPT_Parameter( 0, g_Qingmeihuaquan_CurPNCIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
	
end


--=========================================================
--开始关心NPC
--=========================================================
function Qingmeihuaquan_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "Qingmeihuaquan");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "Qingmeihuaquan")
end


--=========================================================
--停止对某NPC的关心
--=========================================================
function Qingmeihuaquan_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "Qingmeihuaquan");
		g_Object = -1;
	end
end

--================================================
-- help tips
--================================================
function Qingmeihuaquan_Help_Clicked()
	--弹出说明
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NPCTalk")
		Set_XSCRIPT_ScriptID(892720)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end