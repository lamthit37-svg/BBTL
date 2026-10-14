--2026砸金蛋 2

local g_Xichunchi_Reward_Frame_UnifiedPosition
local g_Xichunchi_Reward_UIRed = {}
local g_Xichunchi_Critical_Image = {
	[1] = "set:Xuanshang2 image:critical25",
	[2] = "set:Xuanshang2 image:critical30",
	[3] = "set:Xuanshang2 image:critical40",
	[4] = "set:Xuanshang2 image:critical50",
	[5] = "set:Xuanshang2 image:critical60",
	[6] = "set:Xuanshang2 image:critical80",
	[7] = "set:Xuanshang2 image:critical100",
	[8] = "set:Xuanshang2 image:critical120",
	[9] = "set:Xuanshang2 image:critical200",
	[10] = "set:Xuanshang2 image:critica500",
}

--4个文本控件中 分子内容
local g_Xichunchi_value1 = 0
local g_Xichunchi_value2 = 0
local g_Xichunchi_value3 = 0
local g_Xichunchi_value4 = 0

--4个按钮控件中 是否已经奖：0，否；1，已领奖
local g_Xichunchi_GetPrize1 = 0
local g_Xichunchi_GetPrize2 = 0
local g_Xichunchi_GetPrize3 = 0
local g_Xichunchi_GetPrize4 = 0

--周活跃
local g_Xichunchi_WeekPoint1 = 1200
local g_Xichunchi_WeekPoint2 = 2000

--=========
-- PreLoad()
--=========
function Xichunchi_Reward_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("TODAY_ACTIVE_POINT", false)
	
end

--=========
-- OnLoad()
--=========
function Xichunchi_Reward_OnLoad()
	g_Xichunchi_Reward_Frame_UnifiedPosition = Xichunchi_Reward_Frame:GetProperty("UnifiedPosition")
	g_Xichunchi_Reward_UIRed[1] = Xichunchi_Reward_Reward_Button1_tips

	g_Xichunchi_value1 = 0
	g_Xichunchi_value2 = 0
	g_Xichunchi_value3 = 0
	g_Xichunchi_value4 = 0

	g_Xichunchi_GetPrize1 = 0
	g_Xichunchi_GetPrize2 = 0
	g_Xichunchi_GetPrize3 = 0
	g_Xichunchi_GetPrize4 = 0
	
end

--=========
-- Event
--=========
function Xichunchi_Reward_OnEvent(event)
	if event == "UI_COMMAND" then
		local commandIndex = tonumber(arg0)
 		if commandIndex == 8855772 then
			local operInd = Get_XParam_INT(0)
			--关闭
			if operInd == 0 then
				Xichunchi_Reward_OnHidden()
			--打开
			elseif operInd == 1 then
				g_Xichunchi_value1 = Get_XParam_INT(1) 
				g_Xichunchi_value2 = Get_XParam_INT(2) 
				g_Xichunchi_value3 = Get_XParam_INT(3) 
				g_Xichunchi_value4 = Get_XParam_INT(4) 
				g_Xichunchi_GetPrize1 = Get_XParam_INT(5) 
				g_Xichunchi_GetPrize2 = Get_XParam_INT(6) 
				g_Xichunchi_GetPrize3 = Get_XParam_INT(7) 
				g_Xichunchi_GetPrize4 = Get_XParam_INT(8) 
				Xichunchi_Reward_Update_Data()
				this:Show()
			--刷新
			elseif operInd == 2 then
				if this:IsVisible() then
					g_Xichunchi_value1 = Get_XParam_INT(1) 
					g_Xichunchi_value2 = Get_XParam_INT(2) 
					g_Xichunchi_value3 = Get_XParam_INT(3) 
					g_Xichunchi_value4 = Get_XParam_INT(4) 
					g_Xichunchi_GetPrize1 = Get_XParam_INT(5) 
					g_Xichunchi_GetPrize2 = Get_XParam_INT(6) 
					g_Xichunchi_GetPrize3 = Get_XParam_INT(7) 
					g_Xichunchi_GetPrize4 = Get_XParam_INT(8) 
					Xichunchi_Reward_Update_Data()
					this:Show()				
				end
			end
		end
	elseif ( event == "TODAY_ACTIVE_POINT" ) then
		if this:IsVisible() then
			--local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
			g_Xichunchi_value1 = Player:GetData("WEEKACTIVEPOINT")
			g_Xichunchi_value2 = Player:GetData("WEEKACTIVEPOINT")
			Xichunchi_Reward_Update_Data()
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Xichunchi_Reward_OnHidden()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Xichunchi_Reward_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Xichunchi_Reward_On_ResetPos()
	end

end


--=========
-- 重置
--=========
function Xichunchi_Reward_On_ResetPos()

	Xichunchi_Reward_Frame:SetProperty("UnifiedPosition", g_Xichunchi_Reward_Frame_UnifiedPosition)

end

function Xichunchi_Reward_OnHidden()
	this:Hide()
end

--=============
-- 刷新界面数据
--=============
function Xichunchi_Reward_Update_Data()

--1
	--文本
	Xichunchi_Reward_ItemText1:SetText(ScriptGlobal_Format("#{DKZJ_260521_23}", g_Xichunchi_value1))
	--展示道具
	local theAction = DataPool:CreateActionItemForShow(39925368, 1)
	if theAction:GetID() ~= 0 then
		Xichunchi_Reward_Item1:SetActionItem(theAction:GetID())
		Xichunchi_Reward_Item1:Show()
		Xichunchi_Reward_ItemNum1:SetText(ScriptGlobal_Format("#{DKZJ_260521_52}",300))
    end
	--小红点 及 按钮
	Xichunchi_Reward_Item_GetButtonTips1:Hide()	
	Xichunchi_Reward_Item_GetButton1:Hide()
	Xichunchi_Reward_ItemReceved1:Hide()
	Xichunchi_Reward_ItemUnfinished1:Hide()	
	if g_Xichunchi_GetPrize1==1 then
		Xichunchi_Reward_Item_GetButtonTips1:Hide()
		Xichunchi_Reward_Item_GetButton1:Hide()
		Xichunchi_Reward_ItemReceved1:Show() --已领奖
		Xichunchi_Reward_ItemUnfinished1:Hide()
	else
		if g_Xichunchi_value1>=g_Xichunchi_WeekPoint1 then
			Xichunchi_Reward_Item_GetButtonTips1:Show()	
			Xichunchi_Reward_Item_GetButton1:Show() --可领奖
			Xichunchi_Reward_ItemReceved1:Hide()
			Xichunchi_Reward_ItemUnfinished1:Hide()
		else
			Xichunchi_Reward_Item_GetButtonTips1:Hide()	
			Xichunchi_Reward_Item_GetButton1:Hide()
			Xichunchi_Reward_ItemReceved1:Hide()
			Xichunchi_Reward_ItemUnfinished1:Show() --未达到领奖条件
		end		
	end

--2
	--文本
	Xichunchi_Reward_ItemText2:SetText(ScriptGlobal_Format("#{DKZJ_260521_24}", g_Xichunchi_value2))
	--展示道具
	theAction = DataPool:CreateActionItemForShow(39925368, 1)
	if theAction:GetID() ~= 0 then
		Xichunchi_Reward_Item2:SetActionItem(theAction:GetID())
		Xichunchi_Reward_Item2:Show()
		Xichunchi_Reward_ItemNum2:SetText(ScriptGlobal_Format("#{DKZJ_260521_52}",300))
    end
	--小红点 及 按钮
	Xichunchi_Reward_Item_GetButtonTips2:Hide()
	Xichunchi_Reward_Item_GetButton2:Hide()
	Xichunchi_Reward_ItemReceved2:Hide()
	Xichunchi_Reward_ItemUnfinished2:Hide()	
	if g_Xichunchi_GetPrize2==1 then
		Xichunchi_Reward_Item_GetButtonTips2:Hide()
		Xichunchi_Reward_Item_GetButton2:Hide()
		Xichunchi_Reward_ItemReceved2:Show() --已领奖
		Xichunchi_Reward_ItemUnfinished2:Hide()
	else
		if g_Xichunchi_value2>=g_Xichunchi_WeekPoint2 then
			Xichunchi_Reward_Item_GetButtonTips2:Show()	
			Xichunchi_Reward_Item_GetButton2:Show() --可领奖
			Xichunchi_Reward_ItemReceved2:Hide()
			Xichunchi_Reward_ItemUnfinished2:Hide()
		else
			Xichunchi_Reward_Item_GetButtonTips2:Hide()	
			Xichunchi_Reward_Item_GetButton2:Hide()
			Xichunchi_Reward_ItemReceved2:Hide()
			Xichunchi_Reward_ItemUnfinished2:Show() --未达到领奖条件
		end		
	end
	
--3
	--文本
	Xichunchi_Reward_ItemText3:SetText(ScriptGlobal_Format("#{DKZJ_260521_25}", g_Xichunchi_value3))
	--展示道具
	theAction = DataPool:CreateActionItemForShow(39925368, 1)
	if theAction:GetID() ~= 0 then
		Xichunchi_Reward_Item3:SetActionItem(theAction:GetID())
		Xichunchi_Reward_Item3:Show()
		Xichunchi_Reward_ItemNum3:SetText(ScriptGlobal_Format("#{DKZJ_260521_52}",500))
    end
	--小红点 及 按钮
	Xichunchi_Reward_Item_GetButtonTips3:Hide()
	Xichunchi_Reward_Item_GetButton3:Hide()
	Xichunchi_Reward_ItemReceved3:Hide()
	Xichunchi_Reward_ItemUnfinished3:Hide()	
	if g_Xichunchi_GetPrize3==1 then
		Xichunchi_Reward_Item_GetButtonTips3:Hide()
		Xichunchi_Reward_Item_GetButton3:Hide()
		Xichunchi_Reward_ItemReceved3:Show() --已领奖
		Xichunchi_Reward_ItemUnfinished3:Hide()
	else
		if g_Xichunchi_value3>=1 then
			Xichunchi_Reward_Item_GetButtonTips3:Show()	
			Xichunchi_Reward_Item_GetButton3:Show() --可领奖
			Xichunchi_Reward_ItemReceved3:Hide()
			Xichunchi_Reward_ItemUnfinished3:Hide()
		else
			Xichunchi_Reward_Item_GetButtonTips3:Hide()	
			Xichunchi_Reward_Item_GetButton3:Hide()
			Xichunchi_Reward_ItemReceved3:Hide()
			Xichunchi_Reward_ItemUnfinished3:Show() --未达到领奖条件
		end		
	end
	
--4
	--文本
	Xichunchi_Reward_ItemText4:SetText(ScriptGlobal_Format("#{DKZJ_260521_26}", g_Xichunchi_value4))
	--展示道具
	theAction = DataPool:CreateActionItemForShow(39925368, 1)
	if theAction:GetID() ~= 0 then
		Xichunchi_Reward_Item4:SetActionItem(theAction:GetID())
		Xichunchi_Reward_Item4:Show()
		Xichunchi_Reward_ItemNum4:SetText(ScriptGlobal_Format("#{DKZJ_260521_52}",500))
    end
	--小红点 及 按钮
	Xichunchi_Reward_Item_GetButtonTips4:Hide()
	Xichunchi_Reward_Item_GetButton4:Hide()
	Xichunchi_Reward_ItemReceved4:Hide()
	Xichunchi_Reward_ItemUnfinished4:Hide()	
	if g_Xichunchi_GetPrize4==1 then
		Xichunchi_Reward_Item_GetButtonTips4:Hide()
		Xichunchi_Reward_Item_GetButton4:Hide()
		Xichunchi_Reward_ItemReceved4:Show() --已领奖
		Xichunchi_Reward_ItemUnfinished4:Hide()
	else
		if g_Xichunchi_value4>=1 then
			Xichunchi_Reward_Item_GetButtonTips4:Show()	
			Xichunchi_Reward_Item_GetButton4:Show() --可领奖
			Xichunchi_Reward_ItemReceved4:Hide()
			Xichunchi_Reward_ItemUnfinished4:Hide()
		else
			Xichunchi_Reward_Item_GetButtonTips4:Hide()	
			Xichunchi_Reward_Item_GetButton4:Hide()
			Xichunchi_Reward_ItemReceved4:Hide()
			Xichunchi_Reward_ItemUnfinished4:Show() --未达到领奖条件
		end		
	end
	
end

function Xichunchi_Reward_Item_Get_Clicked(nIndex)
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel();
	local nIsOpen = DataPool:Lua_2026ZaJinDanIsOpen() --DataPool:Lua_XinFuZhengHeIsOpen()
	local BeginDay,EndDay = DataPool:Lua_2026ZaJinDanTime() --DataPool:Lua_XinFuZhengHeTime()
	--总开关
	if nIsOpen ~= 1 then
		PushDebugMessage("#{DKZJ_260521_04}")
		return
	end
	--时间判断
	if BeginDay < 0 or EndDay < 0 or curDay < BeginDay or curDay > EndDay then
		PushDebugMessage("#{DKZJ_260521_04}")
		return
	end
	--等级判断
	if nLevel < 30 then
		PushDebugMessage("#{DKZJ_260521_03}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetPrize")
		Set_XSCRIPT_ScriptID(885577)
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end