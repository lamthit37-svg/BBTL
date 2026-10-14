----------------------
-- GoldTopList ---百战英杰铸精通
----------------------
local g_GoldTopList_UnifiedPosition =nil

local g_GoldTopList_ExchangeList = 
{
	[1] = {itemid = 39920987, count=100, maxcount = 4, },
	[2] = {itemid = 39920980, count=1, maxcount = 2, },
	[3] = {itemid = 39920981, count=1, maxcount = 2, },
}

local g_GoldTopList_ExchangeBtn = {}
local g_GoldTopList_ExchangeText = {}
local g_GoldTopList_ExchangeBtnOK = {}


--===============================================
-- PreLoad()
--===============================================
function GoldTopList_PreLoad()
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
end

--===============================================
-- OnLoad()
--===============================================
function GoldTopList_OnLoad()
	g_GoldTopList_UnifiedPosition = GoldTopList_Frame:GetProperty("UnifiedPosition")

	g_GoldTopList_ExchangeBtn[1] = GoldTopList_Frame3_Bk0_Icon1
	g_GoldTopList_ExchangeBtn[2] = GoldTopList_Frame3_Bk1_Icon1
	g_GoldTopList_ExchangeBtn[3] = GoldTopList_Frame3_Bk2_Icon1
	g_GoldTopList_ExchangeText[1] = GoldTopList_Frame3_Bk0_Info2_Text
	g_GoldTopList_ExchangeText[2] = GoldTopList_Frame3_Bk1_Info2_Text
	g_GoldTopList_ExchangeText[3] = GoldTopList_Frame3_Bk2_Info2_Text
	g_GoldTopList_ExchangeBtnOK[1] = GoldTopList_Frame3_Bk0_Button
	g_GoldTopList_ExchangeBtnOK[2] = GoldTopList_Frame3_Bk1_Button
	g_GoldTopList_ExchangeBtnOK[3] = GoldTopList_Frame3_Bk2_Button

end

--===============================================
-- OnEvent()
--===============================================
function GoldTopList_OnEvent(event)
	if (event == "ADJEST_UI_POS") then
		GoldTopList_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		GoldTopList_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		GoldTopList_Close()
	elseif (event  == "UI_COMMAND") and (tonumber(arg0) == 2015112402) then
		local index = Get_XParam_INT(0)
		if index == nil or index < 0 or index > 1 then--0:只在当前界面可见时更新界面内容 1：打开兑换界面并更新md和次数
			return
		end
		
		if not this:IsVisible() then
			if index == 0 then
				return
			else
				this:Show()
			end
		end
		
		local curValue = Get_XParam_INT(1)
		local totalValue = Get_XParam_INT(2)
		local data1 = Get_XParam_INT(3)
		local data2 = Get_XParam_INT(4)
		local data3 = Get_XParam_INT(5)
		GoldTopList_Exchange_Update(curValue, totalValue, data1, data2, data3)

	end
end

function GoldTopList_ResetPos()
	GoldTopList_Frame:SetProperty("UnifiedPosition",g_GoldTopList_UnifiedPosition)
end

function GoldTopList_Close()
	return this:Hide()
end

function GoldTopList_CloseClicked()
	GoldTopList_Close()
end

--显示兑换页面
function GoldTopList_Exchange_Update(curValue, totalValue, count1, count2, count3)
	if curValue == nil or totalValue == nil or count1 == nil or count2 == nil or count3 == nil then
		return
	end

	--说明区域
	--GoldTopList_Frame1_Info:SetText("#{BZYJ_151123_29}")

	--消费信息显示
	local totalStr = ScriptGlobal_Format("#{BZYJ_151123_30}", curValue)
	GoldTopList_AmountmText:SetText(totalStr)	

	--显示兑换图标
	for i=1,table.getn(g_GoldTopList_ExchangeList) do
		local theAction = DataPool:CreateActionItemForShow(g_GoldTopList_ExchangeList[i].itemid,g_GoldTopList_ExchangeList[i].count)
		if theAction:GetID() ~= 0 then
			g_GoldTopList_ExchangeBtn[i]:SetActionItem(theAction:GetID())
		end	
	end
	
	--显示精金石兑换内容
	local maxCount = g_GoldTopList_ExchangeList[1].maxcount
	local curCount = count1
	local countStr = ScriptGlobal_Format("#{BZYJ_151123_55}", curCount, maxCount - curCount)
	g_GoldTopList_ExchangeText[1]:SetText(countStr)
	if curCount < maxCount then
		g_GoldTopList_ExchangeBtnOK[1]:Enable()
	else
		g_GoldTopList_ExchangeBtnOK[1]:Disable()
	end
	
	--显示无相石兑换内容
	maxCount = g_GoldTopList_ExchangeList[2].maxcount
	curCount = count2	
	if curCount == 0 then
		countStr = ScriptGlobal_Format("#{BZYJ_151123_56}", "#{BZYJ_151123_64}", "#{BZYJ_151123_64}")
	elseif curCount == 1 then
		countStr = ScriptGlobal_Format("#{BZYJ_151123_56}", "#{BZYJ_151123_63}", "#{BZYJ_151123_64}")
	elseif curCount == 2 then
		countStr = ScriptGlobal_Format("#{BZYJ_151123_56}", "#{BZYJ_151123_63}", "#{BZYJ_151123_63}")
	end
	g_GoldTopList_ExchangeText[2]:SetText(countStr)
	if curCount < maxCount then
		g_GoldTopList_ExchangeBtnOK[2]:Enable()
	else
		g_GoldTopList_ExchangeBtnOK[2]:Disable()
	end
	
	--显示无相石兑换内容
	maxCount = g_GoldTopList_ExchangeList[3].maxcount
	curCount = count3
	if curCount == 0 then
		countStr = ScriptGlobal_Format("#{BZYJ_151123_57}", "#{BZYJ_151123_64}", "#{BZYJ_151123_64}")
	elseif curCount == 1 then
		countStr = ScriptGlobal_Format("#{BZYJ_151123_57}", "#{BZYJ_151123_63}", "#{BZYJ_151123_64}")
	elseif curCount == 2 then
		countStr = ScriptGlobal_Format("#{BZYJ_151123_57}", "#{BZYJ_151123_63}", "#{BZYJ_151123_63}")
	end
	g_GoldTopList_ExchangeText[3]:SetText(countStr)
	if curCount < maxCount then
		g_GoldTopList_ExchangeBtnOK[3]:Enable()
	else
		g_GoldTopList_ExchangeBtnOK[3]:Disable()
	end

end

function GoldTopList_Button_Clicked()
	PushEvent("UI_COMMAND",2015112403)
end

--点击兑换按钮
function GoldTopList_Exchange_Clicked(idx)
	if idx < 1 or idx > 3 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ExchangeYingJiePrize" )
		Set_XSCRIPT_ScriptID(891723)
		Set_XSCRIPT_Parameter(0,idx)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
