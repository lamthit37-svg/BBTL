--武意界面

local g_Martial_WuYiJingTong_Frame_UnifiedXPosition
local g_Martial_WuYiJingTong_Frame_UnifiedYPosition
local g_Martial_WuYiJingTong_CurPage = 0
--打造最大条目
local g_Martial_WuYiJingTong_DaZaoMaxIndex = 3
local g_Martial_WuYiJingTong_DaZaoText = {}
local g_Martial_WuYiJingTong_CheckButtons = {}
local g_Martial_WuYiJingTong_ShengJiButtons = {}

local g_Martial_WuYiJingTong_ScriptId = 892480

local g_Martial_WuYiJingTong_CurSelectIndex = 0

local g_Martial_WuYiJingTong_DazaoNeedMoney = 50000
local g_Martial_WuYiJingTong_ShengjiNeedMoney = 20000

local g_Martial_WuYiJingTong_DaZaoNeedItem = 38002087
local g_Martial_WuYiJingTong_DaZaoNeedItem1 = 38002088
local g_Martial_WuYiJingTong_DaZaoNeedItemNum = 1
local g_Martial_WuYiJingTong_bNeedConfirm = 1

local g_CaredNpc = -1

local g_MaxDistance = 15

--属性index对应的名字 以配置表为准
local g_Martial_WuYiJingTong_ShuXing2Name = 
{
	-- [1] = 		   "血上限",
	-- [2] =          "冰攻击",
	-- [3] =          "火攻击",
	-- [4] =          "玄攻击",
	-- [5] =          "毒攻击",
	-- [6] =          "命中",
	-- [7] =          "闪避",
	-- [8] =          "穿刺伤害",
	-- [9] =          "穿刺减免",
	-- [10] =         "所有属性",
	-- [11] =         "外功攻击",
	-- [12] =         "内功攻击",
}

--===============================================
-- OnLoad()
--===============================================
function Martial_WuYiJingTong_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MARTIAL_UPDATE")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("NEW_MISSION")
	

end

function Martial_WuYiJingTong_OnLoad()

	g_Martial_WuYiJingTong_DaZaoText[1] = Martial_WuYiJingTong_AttrFirstText
	g_Martial_WuYiJingTong_DaZaoText[2] = Martial_WuYiJingTong_AttrSecondText
	g_Martial_WuYiJingTong_DaZaoText[3] = Martial_WuYiJingTong_AttrThirdText
	g_Martial_WuYiJingTong_CheckButtons = 
	{
		[1] = Martial_WuYiJingTong_JingTongDaZhao_AttrFirstButton,
		[2] = Martial_WuYiJingTong_JingTongDaZhao_AttrSecondButton,
		[3] = Martial_WuYiJingTong_JingTongDaZhao_AttrThirdButton,
	}
	g_Martial_WuYiJingTong_ShengJiButtons = 
	{
		[1] = Martial_WuYiJingTong_JingTongUpdate_AttrFirst,
		[2] = Martial_WuYiJingTong_JingTongUpdate_AttrSecond,
		[3] = Martial_WuYiJingTong_JingTongUpdate_AttrThird,
	}
	-- 保存界面的默认相对位置
	g_Martial_WuYiJingTong_Frame_UnifiedXPosition	= Martial_WuYiJingTong_Frame : GetProperty("UnifiedXPosition");
	g_Martial_WuYiJingTong_Frame_UnifiedYPosition	= Martial_WuYiJingTong_Frame : GetProperty("UnifiedYPosition");
	Martial_WuYiJingTong_DaZhaoButtonAnimate:Hide()
	Maritial_WuYiJingTong_LoadWuYiAttrInfo()
	Maritial_WuYiJingTong_RefreshShengJiStr()
end

function Maritial_WuYiJingTong_RefreshShengJiStr()
	--
	local nNeedNum = g_Martial_WuYiJingTong_DaZaoNeedItemNum
	for i=1,3 do
		if(g_Martial_WuYiJingTong_CheckButtons[i]:GetCheck() == 1) then
			nNeedNum = nNeedNum + 1
		end
	end
	local str = ScriptGlobal_Format("#{WYXT_20170811_199}",nNeedNum,DataPool:Lua_GetItemNameByIndex(g_Martial_WuYiJingTong_DaZaoNeedItem))
	Martial_WuYiJingTong_InputText:SetText(str)
end
--===============================================
-- OnEvent()
--===============================================
function Martial_WuYiJingTong_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 892480) then	
		local npcid = Get_XParam_INT(0)
		if( npcid ~= -1 ) then
			g_CaredNpc = DataPool:GetNPCIDByServerID(npcid)
		end
		local actid = Get_XParam_INT(1)
		local para1 = Get_XParam_INT(2)
		if(actid == 1) then --打开界面 
			g_Martial_WuYiJingTong_CurPage = 0
			g_Martial_WuYiJingTong_bNeedConfirm = 1
			Martial_JingTongDaZhao_querenbutton:SetCheck(1)
			Maritial_WuYiJingTong_CleanButtonCheck()
			Martial_WuYiJingTong_SiwtchPage(para1)
		end
		Martial_WuYiJingTong_CareObject()
	elseif(event == "MARTIAL_UPDATE") then
		if(this:IsVisible()) then
			if(1 == g_Martial_WuYiJingTong_CurPage) then
				g_Martial_WuYiJingTong_bNeedConfirm = 1
				Martial_WuYiJingTong_RefreshDaZao()
			elseif(2 == g_Martial_WuYiJingTong_CurPage) then
				Maritial_WuYiJingTong_RefreshShengJi()
			end
		end
	elseif(event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") then
		if(this:IsVisible()) then
			Maritial_WuYiJingTong_RefreshMoney()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Martial_WuYiJingTong_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Martial_WuYiJingTong_Frame_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if (tonumber(arg0) ~= g_CaredNpc) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > g_MaxDistance) or arg1=="destroy") then
			Martial_WuYiJingTong_Frame_OnHiden()
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		Martial_WuYiJingTong_Frame_OnHiden()
	elseif (event == "NEW_MISSION") then
		local missname = DataPool:GetPlayerMission_Name(tonumber( arg0 ))
		if(missname == "Mission:1892") then
			local misIndex = DataPool:GetPlayerMissionIndexByID(1892)
			if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
				g_Martial_WuYiJingTong_CurPage = 0
				g_Martial_WuYiJingTong_bNeedConfirm = 1
				Martial_JingTongDaZhao_querenbutton:SetCheck(1)
				Maritial_WuYiJingTong_CleanButtonCheck()
				Martial_WuYiJingTong_SiwtchPage(1)
			end
		end
	end
end

--===============================================
-- OnHiden
--===============================================
function Martial_WuYiJingTong_Frame_OnHiden()
	Martial_WuYiJingTong_StopCareObject()
	if "Martial_WuYiJingTong" == GetFreshManGuideOwner() then 
		CloseFreshManGuide()
	end
	this:Hide()
end


--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function Martial_WuYiJingTong_CareObject()
	this:CareObject(g_CaredNpc, 1, "Martial_WuYiJingTong")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function Martial_WuYiJingTong_StopCareObject()
	this:CareObject(g_CaredNpc, 0, "Martial_WuYiJingTong")
	g_CaredNpc = -1
	return
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Martial_WuYiJingTong_Frame_On_ResetPos()

	Martial_WuYiJingTong_Frame : SetProperty("UnifiedXPosition", g_Martial_WuYiJingTong_Frame_UnifiedXPosition);
	Martial_WuYiJingTong_Frame : SetProperty("UnifiedYPosition", g_Martial_WuYiJingTong_Frame_UnifiedYPosition);

end
function Martial_WuYiJingTong_OnMoved()
	if "Martial_WuYiJingTong" == GetFreshManGuideOwner() then 
        OpenFreshManGuide(2, -1, -1, -1)
    end
	return
end

function Martial_WuYiJingTong_OnHiden()
	Martial_WuYiJingTong_Frame_OnHiden()
end

--加载武意属性配置
function Maritial_WuYiJingTong_LoadWuYiAttrInfo()
	local data = MaritialSys:GetMaritiaAttrInfo()
	if(data ~= nil) then
		g_Martial_WuYiJingTong_ShuXing2Name = {}
	end
	for i,v in ipairs(data) do
		g_Martial_WuYiJingTong_ShuXing2Name[v[1] + 1] = v[2];
	end
end

function Martial_WuYiJingTong_SiwtchPage(nIndex)
	CloseFreshManGuide()
	if(1 == nIndex) then
		g_Martial_WuYiJingTong_CurPage = 1
		Martial_WuYiJingTong_JingTongDaZhao:Show()
		Martial_WuYiJingTong_JingTongUpdate:Hide()
		Martial_WuYiJingTong_FenYe1:SetCheck(1)
		Martial_WuYiJingTong_FenYe2:SetCheck(0)
		Martial_WuYiJingTong_FenYe1:SetText("#{WYXT_20170907_334}")
		Martial_WuYiJingTong_FenYe2:SetText("#{WYXT_20170811_197}")
		Martial_WuYiJingTong_JingTongUpdate_OK:Hide()
		Maritial_WuYiJingTong_CleanButtonCheck()
		Martial_WuYiJingTong_RefreshDaZao()
	elseif(2 == nIndex) then
		g_Martial_WuYiJingTong_CurPage = 2
		Martial_WuYiJingTong_JingTongDaZhao:Hide()
		Martial_WuYiJingTong_JingTongUpdate:Show()
		Martial_WuYiJingTong_FenYe1:SetCheck(0)
		Martial_WuYiJingTong_FenYe2:SetCheck(1)
		Martial_WuYiJingTong_FenYe1:SetText("#{WYXT_20170811_196}")
		Martial_WuYiJingTong_FenYe2:SetText("#{WYXT_20170907_335}")
		Martial_WuYiJingTong_JingTongUpdate_OK:Show()
		Maritial_WuYiJingTong_RefreshShengJi()
		
	end
	this:Show()
end

function Martial_WuYiJingTong_RefreshDaZao()
	for i=1,g_Martial_WuYiJingTong_DaZaoMaxIndex do 
		local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(i - 1)
		if(nLevel == 0) then
			g_Martial_WuYiJingTong_DaZaoText[i]:SetText("#{WYXT_20170811_200}")
		else
			local nPersent = MaritialSys:GetMartialAdvancePersent(nId,nLevel - 1)
			local str = ScriptGlobal_Format("#{WYXT_20170811_201}",g_Martial_WuYiJingTong_ShuXing2Name[nId + 1],nLevel,g_Martial_WuYiJingTong_ShuXing2Name[nId + 1],nPersent)
			g_Martial_WuYiJingTong_DaZaoText[i]:SetText(str)
		end
	end
	--新手指引
	CloseFreshManGuide()
	if DataPool:Lua_IsHaveMission(1892) > 0  then
		local misIndex = DataPool:GetPlayerMissionIndexByID(1892)
		if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
			local fX, fY = this:GetChildOffset("Martial_WuYiJingTong_JingTongDaZhao_OK")
			OpenFreshManGuide(1, 198, fX+10, fY+10,"Martial_WuYiJingTong","northeast")
			Martial_WuYiJingTong_DaZhaoButtonAnimate:Show()
		else
			Martial_WuYiJingTong_DaZhaoButtonAnimate:Hide()
		end
	end
	Maritial_WuYiJingTong_RefreshMoney()
end
function Maritial_WuYiJingTong_RefreshShengJi()
	for i=1,g_Martial_WuYiJingTong_DaZaoMaxIndex do
		local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(i - 1)
		if(nLevel == 0) then
			g_Martial_WuYiJingTong_ShengJiButtons[i]:SetText("#{WYXT_20170811_200}")
		else
			local nPersent = MaritialSys:GetMartialAdvancePersent(nId,nLevel - 1)
			local str = ScriptGlobal_Format("#{WYXT_20170811_225}",g_Martial_WuYiJingTong_ShuXing2Name[nId + 1],nLevel,g_Martial_WuYiJingTong_ShuXing2Name[nId + 1],nPersent)
			g_Martial_WuYiJingTong_ShengJiButtons[i]:SetText(str)
		end
	end
	Maritial_WuYiJingTong_RefreshMoney()
end

function Maritial_WuYiJingTong_CleanButtonCheck()
	for i=1,g_Martial_WuYiJingTong_DaZaoMaxIndex do
		g_Martial_WuYiJingTong_ShengJiButtons[i]:SetCheck(0)
		g_Martial_WuYiJingTong_CheckButtons[i]:SetCheck(0)
	end
	g_Martial_WuYiJingTong_CurSelectIndex = 0
end

function Maritial_WuYiJingTong_RefreshMoney()
	local JiaoziText
	local GoldText
	local NeedText
	local NeedCount = 0
	if(1 == g_Martial_WuYiJingTong_CurPage) then
		JiaoziText = Martial_WuYiJingTong_JingTongDaZhao_HaveNum
		GoldText = Martial_WuYiJingTong_JingTongDaZhao_HaveGoldNum
		NeedText = Martial_WuYiJingTong_JingTongDaZhao_WantNum
		local lockNum = 0
		for i=1,g_Martial_WuYiJingTong_DaZaoMaxIndex do
			lockNum = lockNum + g_Martial_WuYiJingTong_CheckButtons[i]:GetCheck()
		end
		NeedCount = g_Martial_WuYiJingTong_DazaoNeedMoney
		if(lockNum >= 1) then
			NeedCount =  NeedCount + (g_Martial_WuYiJingTong_DazaoNeedMoney)
		end
		if(lockNum>=2) then
			NeedCount = NeedCount + (g_Martial_WuYiJingTong_DazaoNeedMoney*2)
		end
	elseif(2 == g_Martial_WuYiJingTong_CurPage) then
		JiaoziText = Martial_WuYiJingTong_JingTongUpdate_HaveNum1
		GoldText = Martial_WuYiJingTong_JingTongUpdate_HaveGoldNum1
		NeedText = Martial_WuYiJingTong_JingTongUpdate_WantNum
		NeedCount = 0
		local str = ""
		if(g_Martial_WuYiJingTong_CurSelectIndex > 0 and g_Martial_WuYiJingTong_CurSelectIndex <= g_Martial_WuYiJingTong_DaZaoMaxIndex) then
			local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(g_Martial_WuYiJingTong_CurSelectIndex - 1)
			NeedCount = MaritialSys:GetMartialAdvanceCostMoney(nId,nLevel)
			if(NeedCount < 0) then
				NeedCount = 0
			end
			local nItem,nNum = MaritialSys:GetMartialAdvanceCostItem(nId,nLevel)
			if(nLevel >= MaritialSys:GetMartialAdvanceMaxLevel()) then
				str = "#{WYXT_20170811_227}"
			else
				if(nItem > 0) then
					str = ScriptGlobal_Format("#{WYXT_20170811_226}",nNum,DataPool:Lua_GetItemNameByIndex(nItem))
				end
			end
		end
		Martial_WuYiJingTong_JingTongUpdate_InputText1:SetText(str)
	else
		return
	end
	--需要交子
	NeedText:SetProperty("MoneyNumber",""..NeedCount)
	--交子
	local nJiaozi = tostring(Player:GetData("MONEY_JZ"))
	JiaoziText:SetProperty("MoneyNumber",""..nJiaozi)
	--金币
	local nGold = tostring(Player:GetData("MONEY"))
	GoldText:SetProperty("MoneyNumber",""..nGold)

	
end
function Maritial_WuYiJingTong_BaseCheck()
	--安全时间内不能操作
	if(DataPool:GetForeverLock() == true or DataPool:GetLeftProtectTime() > 0 ) then
		PushDebugMessage("#{BYFUR_160531_48}")
		return 0
	end
	--密保 二级密码
	if(CheckPhoneMibaoAndMinorPassword() == 0) then
		return 0
	end
	--是否完成武意突破
	if(MaritialSys:HasFinishWuYiMisson() ~= 1) then
		PushDebugMessage("#{WYXT_20170803_21}")
		return 0
	end
end
--点击打造
function Martial_WuYiJingTong_OK_Clicked()
	if(Maritial_WuYiJingTong_BaseCheck() == 0) then
		return
	end
	--检查锁定
	local lockNum = 0
	for i=1,g_Martial_WuYiJingTong_DaZaoMaxIndex do
		lockNum = lockNum + g_Martial_WuYiJingTong_CheckButtons[i]:GetCheck()
	end
	if(lockNum >= g_Martial_WuYiJingTong_DaZaoMaxIndex) then
		PushDebugMessage("#{WYXT_20170811_217}")
		return
	end
	--检查金钱
	if(Player:GetData("MONEY_JZ") + Player:GetData("MONEY") < g_Martial_WuYiJingTong_DazaoNeedMoney) then
		PushDebugMessage("#{WYXT_20170811_218}")
		return
	end
	--检查道具
	local num = PlayerPackage:Lua_GetUnLockItemCount(g_Martial_WuYiJingTong_DaZaoNeedItem)
	local num1 = PlayerPackage:Lua_GetUnLockItemCount(g_Martial_WuYiJingTong_DaZaoNeedItem1)
	if(num + num1 < g_Martial_WuYiJingTong_DaZaoNeedItemNum + lockNum) then
		local ItemName = DataPool:Lua_GetItemNameByIndex(g_Martial_WuYiJingTong_DaZaoNeedItem)
		PushDebugMessage(ScriptGlobal_Format("#{WYXT_20170811_219}",ItemName,ItemName))
		return
	end
	--是否需要二次确认
	if(g_Martial_WuYiJingTong_bNeedConfirm == 1 and Martial_JingTongDaZhao_querenbutton:GetCheck() == 1) then
		local nIds = {}
		local nCom = 1
		local nComId = 0
		local nComLock = 0
		for i=1,g_Martial_WuYiJingTong_DaZaoMaxIndex do
			local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(i - 1)
			if(nLevel == 0) then
				nIds[i] = -1
			else
				nIds[i] = nId
			end
		end
		for i=1,g_Martial_WuYiJingTong_DaZaoMaxIndex do
			if(nCom == 1) then
				nComLock = 0
				nComLock = nComLock + g_Martial_WuYiJingTong_CheckButtons[i]:GetCheck()
				for j=i+1,g_Martial_WuYiJingTong_DaZaoMaxIndex do 
					if(nIds[i] ~= -1 and nIds[i] == nIds[j]) then
						nCom = nCom + 1
						nComId = nIds[i]
						nComLock = nComLock + g_Martial_WuYiJingTong_CheckButtons[j]:GetCheck()
					end
				end
			end
		end
		if(nCom > 1 and nComLock < nCom) then
			local strTip = ""
			if(nComLock == 0) then
				strTip = ScriptGlobal_Format("#{WYXT_20170907_329}",nCom,g_Martial_WuYiJingTong_ShuXing2Name[nComId + 1])
			else
				strTip = ScriptGlobal_Format("#{WYXT_20170907_327}",nCom,g_Martial_WuYiJingTong_ShuXing2Name[nComId + 1],nCom - nComLock)
			end
			PushEvent("MARTIAL_ADVACEN_CONFIRM",strTip)
			g_Martial_WuYiJingTong_bNeedConfirm = 0
			return
		end
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "MartialAdvacanceRefresh" )
		Set_XSCRIPT_ScriptID( g_Martial_WuYiJingTong_ScriptId )
		Set_XSCRIPT_Parameter(0,g_Martial_WuYiJingTong_CheckButtons[1]:GetCheck())
		Set_XSCRIPT_Parameter(1,g_Martial_WuYiJingTong_CheckButtons[2]:GetCheck())
		Set_XSCRIPT_Parameter(2,g_Martial_WuYiJingTong_CheckButtons[3]:GetCheck())
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end
--点击升级
function Martial_WuYiJingTong_JingTongUpdate_OK_Clicked()
	if(g_Martial_WuYiJingTong_CurSelectIndex < 1 or g_Martial_WuYiJingTong_CurSelectIndex > g_Martial_WuYiJingTong_DaZaoMaxIndex) then
		PushDebugMessage("#{WYXT_20170811_229}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "MartialAdvacanceUpgrade" )
		Set_XSCRIPT_ScriptID( g_Martial_WuYiJingTong_ScriptId )
		Set_XSCRIPT_Parameter(0,g_Martial_WuYiJingTong_CurSelectIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	return
end

--选种一条属性
function Martial_WuYiJingTong_JingTongUpdateSelect(nIndex)
	if(nIndex < 1 and nIndex > g_Martial_WuYiJingTong_DaZaoMaxIndex) then
		return
	end
	if(nIndex ~= g_Martial_WuYiJingTong_CurSelectIndex) then
		local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(nIndex - 1)
		if(nLevel == 0) then
			--PushDebugMessage("#{WYXT_20170811_224}")
			for i=1,g_Martial_WuYiJingTong_DaZaoMaxIndex do
				if(i == g_Martial_WuYiJingTong_CurSelectIndex) then
					g_Martial_WuYiJingTong_ShengJiButtons[i]:SetCheck(1)
				else
					g_Martial_WuYiJingTong_ShengJiButtons[i]:SetCheck(0)
				end
			end
			return 
		end
		g_Martial_WuYiJingTong_CurSelectIndex = nIndex
	end
	Maritial_WuYiJingTong_RefreshMoney()
end

function Martial_WuYiJingTong_Lock_Attr(nIndex)
	if(nIndex < 1 and nIndex > g_Martial_WuYiJingTong_DaZaoMaxIndex) then
		return
	end
	local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(nIndex - 1)
	if(nLevel == 0) then
		PushDebugMessage("#{WYXT_20170811_204}")
		g_Martial_WuYiJingTong_CheckButtons[nIndex]:SetCheck(0)
		return
	end
	local nLockCount = 0
	for i = 1,g_Martial_WuYiJingTong_DaZaoMaxIndex do
		if(g_Martial_WuYiJingTong_CheckButtons[i]:GetCheck() == 1) then
			nLockCount = nLockCount + 1
		end
	end
	if(nLockCount == g_Martial_WuYiJingTong_DaZaoMaxIndex) then
		PushDebugMessage("#{WYXT_20170811_205}")
		g_Martial_WuYiJingTong_CheckButtons[nIndex]:SetCheck(0)
		return
	end
	Maritial_WuYiJingTong_RefreshShengJiStr()
	Maritial_WuYiJingTong_RefreshMoney()
	return
end
