--霜影抽奖界面
local g_ShuangYing_Gacha_Frame_UnifiedPosition
local g_rewardIndex = 0
local g_RewardItemId = -1
local g_RewardNum = 0

local g_cjCount_Max = 1
local g_RewardIndex_Max = 7
local g_RewardItemUITalbe = {}

local g_AnimateStep = 1
local g_AnimateCircleCount = 1
local g_AnimateCirCleMax = 3
local g_IsAnimateCircleEnd = 0
local g_AnimateSpeed = {80,50,85,60,78,50,60}


local g_RewardItem = 
{
	[1] = {itemId = 39920109, num = 1},
	[2] = {itemId = 39920110, num = 1},
	[3] = {itemId = 39920111, num = 1},
	[4] = {itemId = 39920590, num = 1},
	[5] = {itemId = 39920939, num = 1},
	[6] = {itemId = 39920589, num = 1},
	[7] = {itemId = 39920938, num = 1},
}

local objCared = -1
local MAX_OBJ_DISTANCE = 3.0
local g_Object = -1
local g_nNpcId = -1
function ShuangYing_Gacha_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

function ShuangYing_Gacha_OnLoad()
	g_ShuangYing_Gacha_Frame_UnifiedPosition = ShuangYing_Gacha_Frame:GetProperty("UnifiedPosition")
	g_RewardItemUITalbe = 
	{
		[1]=
		{
			ItemAction = ShuangYing_Gacha_Icon1,
			ItemAnimate = ShuangYing_Gacha1_Light,
		
		},
		[2]=
		{
			ItemAction = ShuangYing_Gacha_Icon2,
			ItemAnimate = ShuangYing_Gacha2_Light,
		},
		[3]=
		{
			ItemAction = ShuangYing_Gacha_Icon3,
			ItemAnimate = ShuangYing_Gacha3_Light,
		},
		[4]=
		{
			ItemAction = ShuangYing_Gacha_Icon4,
			ItemAnimate = ShuangYing_Gacha4_Light,
		},
		[5]=
		{
			ItemAction = ShuangYing_Gacha_Icon5,
			ItemAnimate = ShuangYing_Gacha5_Light,
		},
		[6]=
		{
			ItemAction = ShuangYing_Gacha_Icon6,
			ItemAnimate = ShuangYing_Gacha6_Light,
		},
		[7]=
		{
			ItemAction = ShuangYing_Gacha_Icon7,
			ItemAnimate = ShuangYing_Gacha7_Light,
		},
	}
end

function ShuangYing_Gacha_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2024072601) then
		g_rewardIndex = Get_XParam_INT(0)
		local g_cjCount = Get_XParam_INT(1)
		if g_cjCount<=0 then
			ShuangYing_Gacha_Button_Chance:SetText(ScriptGlobal_Format("#{SYXG_240715_73}", g_cjCount_Max))
		else
			ShuangYing_Gacha_Button_Chance:SetText(ScriptGlobal_Format("#{SYXG_240715_72}", g_cjCount, g_cjCount_Max))
		end
		if g_rewardIndex == 0 then
			if this:IsVisible() then
				ShuangYing_Gacha_Close()
				return
			end
			g_nNpcId = Get_XParam_INT(2)
			objCared = DataPool : GetNPCIDByServerID(g_nNpcId)
			if objCared == -1 then
				PushDebugMessage("Server数据问题，谁改Server脚本啦！")
				return
			end
			ShuangYing_Gacha_BeginCareObject(objCared)
			this:Show()
			ShuangYing_Gacha_Open()
		else
			ShuangYing_Gacha_ChouJiangAnimate()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ShuangYing_Gacha_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ShuangYing_Gacha_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ShuangYing_Gacha_Close()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			ShuangYing_Gacha_Close()
		end
	end
end

function ShuangYing_Gacha_Button_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ChouJiang")
		Set_XSCRIPT_ScriptID(999362)
		Set_XSCRIPT_Parameter(0, g_nNpcId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function ShuangYing_Gacha_Open()
	for  i = 1, g_RewardIndex_Max do
		local ItemID = g_RewardItem[i].itemId
		local theAction = DataPool:CreateActionItemForShow(ItemID, g_RewardItem[i].num)
   		if theAction:GetID() ~= 0 then
			g_RewardItemUITalbe[i].ItemAction:SetActionItem(theAction:GetID())
			g_RewardItemUITalbe[i].ItemAction:Show()
		end
		g_RewardItemUITalbe[i].ItemAnimate:Hide()
	end

end

function ShuangYing_Gacha_OnHide()
	ShuangYing_Gacha_StopCareObject(objCared)
	KillTimer("ShuangYing_Gacha_Tick()") 
	g_AnimateStep = 1
	g_AnimateCircleCount = 1
	g_IsAnimateCircleEnd = 0
	g_RewardItemId = -1
	g_RewardNum = 0
	g_nNpcId = -1
end

function ShuangYing_Gacha_ChouJiangAnimate()

	if g_rewardIndex>0 then 
		g_RewardItemId = g_RewardItem[g_rewardIndex].itemId
		g_RewardNum = g_RewardItem[g_rewardIndex].num
		g_RewardItemUITalbe[g_AnimateStep].ItemAnimate:Show()
		SetTimer("ShuangYing_Gacha","ShuangYing_Gacha_Tick()", g_AnimateSpeed[g_AnimateStep])
	end
end

function ShuangYing_Gacha_Tick()
	g_RewardItemUITalbe[g_AnimateStep].ItemAnimate:Hide()
	if g_AnimateStep >= g_RewardIndex_Max then
		g_AnimateStep = 1
		if g_AnimateCircleCount < g_AnimateCirCleMax and g_IsAnimateCircleEnd == 0 then
			g_AnimateCircleCount = g_AnimateCircleCount + 1 
		else
			g_IsAnimateCircleEnd = 1
		end
	else
		g_AnimateStep = g_AnimateStep + 1 
	end
	g_RewardItemUITalbe[g_AnimateStep].ItemAnimate:Show()
	KillTimer("ShuangYing_Gacha_Tick()") 
	if g_AnimateStep == g_rewardIndex and g_IsAnimateCircleEnd == 1 then
		PushDebugMessage( ScriptGlobal_Format("#{SYXG_240715_19}", g_RewardNum, DataPool:Lua_GetItemNameByIndex(g_RewardItemId)) )
	else
		SetTimer("ShuangYing_Gacha","ShuangYing_Gacha_Tick()", g_AnimateSpeed[g_AnimateStep])
	end

end

function ShuangYing_Gacha_On_ResetPos()
	ShuangYing_Gacha_Frame:SetProperty("UnifiedPosition", g_ShuangYing_Gacha_Frame_UnifiedPosition)
end

function ShuangYing_Gacha_Close()
	this:Hide()
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function ShuangYing_Gacha_BeginCareObject(objCaredId)
	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "ShuangYing_Gacha");
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ShuangYing_Gacha_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "ShuangYing_Gacha");
	g_Object = -1;

end