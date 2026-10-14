--T3WarmUp_Introduct.lua
--2020 新天外预热-汴京八景
local g_Frame_UnifiedPosition

local g_Bajing_Info = {}
local g_Bajing_Num = 8

local g_Bajing_Index = 0
local g_Bajing_FromType = 0
local g_Bajing_HuiZhiIndex = 0
local g_Bajing_AwardFlag = 0
local g_Bajing_CanAward = 0
local g_Bajing_HuiZhiCount = 0

local g_Bajing_RewardInfo = {
	{ nItemId1 = 39921549, nItemNum1=1, nItemId2 = 39923116, nItemNum2 = 1},
	{ nItemId1 = 39920162, nItemNum1=20, nItemId2 = 39923116, nItemNum2 = 2},
	{ nItemId1 = 39920999, nItemNum1=1, nItemId2 = 39923116, nItemNum2 = 3},
	{ nItemId1 = 39920181, nItemNum1=1, nItemId2 = 39923116, nItemNum2 = 4},
	{ nItemId1 = 39922685, nItemNum1=10, nItemId2 = 39923116, nItemNum2 = 5},
	{ nItemId1 = 39920329, nItemNum1=5, nItemId2 = 39923116, nItemNum2 = 6},
	{ nItemId1 = 39921547, nItemNum1=1, nItemId2 = 39923116, nItemNum2 = 7},
	{ nItemId1 = 39920959, nItemNum1=8, nItemId2 = 39923116, nItemNum2 = 8},
}
--===============================================
-- OnLoad()
--===============================================
function T3WarmUp_Introduct_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
end
function T3WarmUp_Introduct_OnLoad()
	g_Frame_UnifiedPosition = T3WarmUp_Introduct_Frame:GetProperty("UnifiedPosition")
	g_Bajing_Info = {
		{uiName=T3WarmUp_Introduct_Pic1, nAllNum = 1, szName="#{TWYR_200908_154}", szTime="11月5日", szTips="#{TWYR_200908_200}"},
		{uiName=T3WarmUp_Introduct_Pic2, nAllNum = 2, szName="#{TWYR_200908_155}", szTime="11月6日", szTips="#{TWYR_200908_201}"},
		{uiName=T3WarmUp_Introduct_Pic3, nAllNum = 3, szName="#{TWYR_200908_156}", szTime="11月7日", szTips="#{TWYR_200908_202}"},
		{uiName=T3WarmUp_Introduct_Pic4, nAllNum = 5, szName="#{TWYR_200908_157}", szTime="11月8日", szTips="#{TWYR_200908_203}"},	
		{uiName=T3WarmUp_Introduct_Pic5, nAllNum = 7, szName="#{TWYR_200908_158}", szTime="11月10日", szTips="#{TWYR_200908_204}"},	
		{uiName=T3WarmUp_Introduct_Pic6, nAllNum = 9, szName="#{TWYR_200908_159}", szTime="11月12日", szTips="#{TWYR_200908_205}"},	
		{uiName=T3WarmUp_Introduct_Pic7, nAllNum = 12, szName="#{TWYR_200908_160}", szTime="11月14日", szTips="#{TWYR_200908_206}"},	
		{uiName=T3WarmUp_Introduct_Pic8, nAllNum = 16, szName="#{TWYR_200908_161}", szTime="11月17日", szTips="#{TWYR_200908_207}"},	
	}
end

--===============================================
-- OnEvent()
--===============================================
function T3WarmUp_Introduct_OnEvent(event)
if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		T3WarmUp_Introduct_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		T3WarmUp_Introduct_Close()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15520001 ) then
		if Get_XParam_INT( 0 ) == 0 then 
			T3WarmUp_Introduct_Close()
			return
		end
		g_Bajing_Index = Get_XParam_INT( 1 )
		g_Bajing_FromType = Get_XParam_INT( 2 )
		g_Bajing_HuiZhiIndex = Get_XParam_INT( 3 )
		g_Bajing_AwardFlag = Get_XParam_INT( 4 )
		g_Bajing_CanAward = Get_XParam_INT( 5 )
		g_Bajing_HuiZhiCount = Get_XParam_INT( 6 )
		T3WarmUp_Introduct_UpdateInfo(g_Bajing_Index)
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15520002 ) then
		local nIndex = Get_XParam_INT( 0 )
		if g_Bajing_Index ~= nIndex then return end
		local nOpera = Get_XParam_INT( 1 )
		if nOpera == 1 then 
			g_Bajing_AwardFlag = 1
			T3WarmUp_Introduct_UpdateInfo(g_Bajing_Index)
		elseif nOpera == 2 then 
			g_Bajing_AwardFlag = 0
			g_Bajing_CanAward = 1
			T3WarmUp_Introduct_UpdateInfo(g_Bajing_Index)
		end
	end
end
function T3WarmUp_Introduct_Close()
	this:Hide()
end
--===============================================
--===============================================
function T3WarmUp_Introduct_ClickItemBtn()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("T300BaJingAward")
		Set_XSCRIPT_ScriptID(888228)
		Set_XSCRIPT_Parameter( 0, g_Bajing_Index )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function T3WarmUp_Introduct_CheckBtnClick()
end
function T3WarmUp_Introduct_PreClick()
	g_Bajing_Index = g_Bajing_Index - 1
	if g_Bajing_Index < 1 then g_Bajing_Index = g_Bajing_Num end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenT300BaJing")
		Set_XSCRIPT_ScriptID(888228)
		Set_XSCRIPT_Parameter( 0, g_Bajing_Index )
		Set_XSCRIPT_Parameter( 1, g_Bajing_FromType )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
function T3WarmUp_Introduct_NextClick()
	g_Bajing_Index = g_Bajing_Index + 1
	if g_Bajing_Index > g_Bajing_Num then g_Bajing_Index = 1 end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenT300BaJing")
		Set_XSCRIPT_ScriptID(888228)
		Set_XSCRIPT_Parameter( 0, g_Bajing_Index )
		Set_XSCRIPT_Parameter( 1, g_Bajing_FromType )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function T3WarmUp_Introduct_UpdateInfo(nIndex)
	for i, v in ipairs(g_Bajing_Info) do 
		if i==nIndex then 
			v.uiName:Show()
		else
			v.uiName:Hide()
		end
	end
	if g_Bajing_FromType == 1 then 
		T3WarmUp_Introduct_InfoText:Show()
		T3WarmUp_Introduct_Gift:Show()
		local info = g_Bajing_Info[nIndex]
		if g_Bajing_HuiZhiCount >= info.nAllNum then
			T3WarmUp_Introduct_InfoText:SetText( ScriptGlobal_Format("#{TWYR_200908_34}", info.nAllNum, info.szName, info.nAllNum, info.nAllNum ) )
		else
			T3WarmUp_Introduct_InfoText:SetText( ScriptGlobal_Format("#{TWYR_200908_34}", info.nAllNum, info.szName, g_Bajing_HuiZhiCount, info.nAllNum ) )
		end
		if g_Bajing_AwardFlag == 1 then 
			T3WarmUp_Introduct_ItemBtnFinish:Show()
			T3WarmUp_Introduct_ItemBtn:Hide()
			T3WarmUp_Introduct_ItemBtnTips:Hide()
		else
			T3WarmUp_Introduct_ItemBtnFinish:Hide()
			T3WarmUp_Introduct_ItemBtn:Show()
			if g_Bajing_CanAward == 1 then 
				T3WarmUp_Introduct_ItemBtnTips:Show()
			else
				T3WarmUp_Introduct_ItemBtnTips:Hide()
			end
		end
		if g_Bajing_RewardInfo[nIndex] ~= nil then
			local theAction = DataPool:CreateActionItemForShow(g_Bajing_RewardInfo[nIndex].nItemId1, g_Bajing_RewardInfo[nIndex].nItemNum1)
			if theAction:GetID() ~= 0 then
				T3WarmUp_Introduct_Item1:SetActionItem(theAction:GetID());
			end	
			theAction = DataPool:CreateActionItemForShow(g_Bajing_RewardInfo[nIndex].nItemId2, g_Bajing_RewardInfo[nIndex].nItemNum2)
			if theAction:GetID() ~= 0 then
				T3WarmUp_Introduct_Item2:SetActionItem(theAction:GetID());
			end			
		end
		
		if g_Bajing_HuiZhiIndex >= g_Bajing_Index then
			T3WarmUp_Introduct_PicLocked:Hide()
		else			
			T3WarmUp_Introduct_PicLocked:Show()
		end
	else
		T3WarmUp_Introduct_InfoText:Hide()
		T3WarmUp_Introduct_Gift:Hide()
	end
end

