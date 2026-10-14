--焦骨时装活动UI逻辑

local g_DressPurchase_JiaoGu_Frame_UnifiedPosition
local g_DressPurchase_JiaoGu_UIRed = {}				--各活动小红点

local g_DressPurchas_Limit_StartDay = {
	20210422,
	20210512,
}
local g_DressPurchas_Limit_EndDay = 20210423
local g_DressPurchas_CurrentMaxDiscount = 0

--临时激活商店等级
local g_ZNQ_ShopUIInd = 4

--=========
-- PreLoad
--=========
function DressPurchase_JiaoGu_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	
end

--=========
-- OnLoad()
--=========
function DressPurchase_JiaoGu_OnLoad()
	g_DressPurchase_JiaoGu_Frame_UnifiedPosition = DressPurchase_JiaoGu_Frame:GetProperty("UnifiedPosition")
	g_DressPurchase_JiaoGu_UIRed[1] = DressPurchase_JiaoGu_Tips1
	g_DressPurchase_JiaoGu_UIRed[2] = DressPurchase_JiaoGu_Tips2
 
 
	for i =1, table.getn(g_DressPurchase_JiaoGu_UIRed) do
		g_DressPurchase_JiaoGu_UIRed[i]:Hide()
	end
end

--=========
-- Event
--=========
function DressPurchase_JiaoGu_OnEvent(event)
	if event == "UI_COMMAND" then
		local commandIndex = tonumber(arg0)
 		if commandIndex == 88839501 then
			 local nType = Get_XParam_INT(0)
			 g_DressPurchas_CurrentMaxDiscount = Get_XParam_INT(3)
			 DressPurchase_JiaoGu_FlashUIRedPoint()
			if nType == 1 then
				this:Show()
				DressPurchase_Initlogic()
			end
		elseif commandIndex == 88839502 then
			--DressPurchase_JiaoGu_AutoRun(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2))
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DressPurchase_JiaoGu_Close()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DressPurchase_JiaoGu_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		DressPurchase_JiaoGu_On_ResetPos()
	end

end

function DressPurchase_Initlogic()
	DressPurchase_JiaoGu_DragTitle:SetText("#{ZNFCSZ_210316_07}")
	DressPurchase_JiaoGu_Instruction:SetText("#{ZNFCSZ_210316_08}")

	-----------------LIFT---------------------------
	local curData = WGAch:GetCJMaxCur()
	if curData.param0 == 1 or curData.cur_level >= g_ZNQ_ShopUIInd then  --临时激活或者已经解锁
		DressPurchase_JiaoGu_Text3:SetText("#{ZNFCSZ_210316_12}")
	else
		DressPurchase_JiaoGu_Text3:SetText("#{ZNFCSZ_210316_09}")
	end

	-- local cur = WGAch:GetCJMaxCur()
	-- if cur.cur_level >=3 then 
	-- 	DressPurchase_JiaoGu_Text3:SetText("#{ZNFCSZ_210316_12}")
	-- else
	-- 	DressPurchase_JiaoGu_Text3:SetText("#{ZNFCSZ_210316_09}")
	-- end
	
	-- DressPurchase_JiaoGu_BtnJion1:SetText("#{ZNFCSZ_210316_14}")



	-----------------RIGHT---------------------------"

	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day >= g_DressPurchas_Limit_EndDay then
		DressPurchase_JiaoGu_Text4:SetText("#{ZNFCSZ_210316_16}")  
	else
		DressPurchase_JiaoGu_Text4:SetText("#{ZNFCSZ_210316_13}")
	end
	local str = ScriptGlobal_Format("#{ZNFCSZ_210316_62}",string.format("%.1f",g_DressPurchas_CurrentMaxDiscount/10))
	DressPurchase_JiaoGu_Text5:SetText(str)
 
	
end

--=========
-- 重置
--=========
function DressPurchase_JiaoGu_On_ResetPos()

	DressPurchase_JiaoGu_Frame:SetProperty("UnifiedPosition", g_DressPurchase_JiaoGu_Frame_UnifiedPosition)

end

--=========
-- 问号帮助
--=========
function DressPurchase_JiaoGu_Description_Clicked()
	--PushEvent("CCSHOP_HELP", 130)
end

--=========
-- 打开界面
--=========
function DressPurchase_JiaoGu_Clicked( ind )
	--if IsInTServer() == 1 then
	--	PushDebugMessage("#{GQKJ_190722_22}")
	--	return
	--end
	--PushDebugMessage("=" .. ind)
	if ind == 1 then
		--活动1
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnClientAskOp")
		Set_XSCRIPT_ScriptID(888395)
		Set_XSCRIPT_Parameter(0,ind) 	
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif ind == 2 then
		--活动2
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnClientAskOp")
		Set_XSCRIPT_ScriptID(888395)
		Set_XSCRIPT_Parameter(0,ind) 	
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

		g_DressPurchase_JiaoGu_UIRed[2]:Hide()
	-- elseif ind == 3 then
	-- 	--活动3
	-- 	Clear_XSCRIPT()
	-- 	Set_XSCRIPT_Function_Name("OnClientAskOp")
	-- 	Set_XSCRIPT_ScriptID(888395)
	-- 	Set_XSCRIPT_Parameter(0,ind) 	
	-- 	Set_XSCRIPT_ParamCount(1)
	-- 	Send_XSCRIPT()
	-- elseif ind == 4 then
	-- 	--活动4
	-- 	Clear_XSCRIPT()
	-- 	Set_XSCRIPT_Function_Name("OnClientAskOp")
	-- 	Set_XSCRIPT_ScriptID(888395)
	-- 	Set_XSCRIPT_Parameter(0,ind) 	
	-- 	Set_XSCRIPT_ParamCount(1)
	-- 	Send_XSCRIPT()
	-- elseif ind == 5 then
	-- 	--活动5
	-- 	Clear_XSCRIPT()
	-- 	Set_XSCRIPT_Function_Name("OnClientAskOp")
	-- 	Set_XSCRIPT_ScriptID(888395)
	-- 	Set_XSCRIPT_Parameter(0,ind) 	
	-- 	Set_XSCRIPT_ParamCount(1)
	-- 	Send_XSCRIPT()
	-- elseif ind == 6 then
	-- 	--活动6
	-- 	Clear_XSCRIPT()
	-- 	Set_XSCRIPT_Function_Name("OnClientAskOp")
	-- 	Set_XSCRIPT_ScriptID(888395)
	-- 	Set_XSCRIPT_Parameter(0,ind) 	
	-- 	Set_XSCRIPT_ParamCount(1)
	-- 	Send_XSCRIPT()
	elseif ind == 7 then

		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		if curTime2Day >= g_DressPurchas_Limit_StartDay[1] and curTime2Day <= g_DressPurchas_Limit_StartDay[2] then
			--活动6
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnClientAskOp")
			Set_XSCRIPT_ScriptID(888395)
			Set_XSCRIPT_Parameter(0,3) 	
			Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		else
			PushDebugMessage("#{ZNFCSZ_210316_05}")
		end
 
	elseif ind == 8 then
		--购买2
	end
end

--====================
-- 关闭界面
--====================
function DressPurchase_JiaoGu_Close()
	this:Hide()
end

--===========
-- 刷新UI红点
--===========
function DressPurchase_JiaoGu_FlashUIRedPoint()
 
	for i =1, table.getn(g_DressPurchase_JiaoGu_UIRed) do
		g_DressPurchase_JiaoGu_UIRed[i]:Hide()
	end
	
 
	--玩家激活龙征途第10档奖励但没领取 显示红点
	for i = 1, table.getn(g_DressPurchase_JiaoGu_UIRed) do
		local nRet = Get_XParam_INT(i)
		if nRet == 0 then
			g_DressPurchase_JiaoGu_UIRed[i]:Show()
		end
	end
end

--====================
-- 寻路
--====================
function DressPurchase_JiaoGu_AutoRun(clientSceneId,posX,posZ)
	AutoRunToTargetEx(posX,posZ,clientSceneId)
end
