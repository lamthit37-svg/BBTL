--家具批量制作
local g_NumberText = 0
local g_Title = 0
local g_Desc = 0
local g_Tips = 0
local g_InterfaceType = 0
local g_MaxCount = 99
local g_MinCount = 1
--timer回调间隔为100ms
local g_TickInterval = 100
--按下按钮类型 1 加 2 减
local g_ButtonDonwType = 0
--按钮按下tick数量
local g_ButtonDonwTick = 0
local g_LastTickTime = 0
local g_FurName = ""
local g_CostShiCai = 0
local g_CostMuCai = 0
local g_CostJinBi = 0
local g_NeedCaiLiao = 0
local g_SelfCaiLiao = 0
local g_NeedJiaoZi = 0
local g_SelfJiaoZi = 0
local g_SelfMoney = 0
--现在资源能制造的最大数量
local g_CanMaxCount = -1
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function BieYeFurnitureCreate_MBuy_PreLoad()
	this:RegisterEvent("OPEN_BIEYEFURCREATE_MBUY")
	this:RegisterEvent("CLOSE_BIEYEFURCREATE_MBUY")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--=========================================================
-- 载入初始化
--=========================================================
function BieYeFurnitureCreate_MBuy_OnLoad()
	g_Title = BieYeFurnitureCreate_MBuy_DragTitle
	g_Desc = BieYeFurnitureCreate_MBuy_Explain
	--g_Tips = BieYeFurnitureCreate_MBuy_Text2
	g_NumberText = BieYeFurnitureCreate_MBuy_Number
	--g_NumberText:SetText(tostring(g_MinCount))
	g_NeedCaiLiao = BieYeFurnitureCreate_MBuy_NeedList_Cailiao
	g_SelfCaiLiao = BieYeFurnitureCreate_MBuy_NeedList_SelfCailiao
	g_NeedJiaoZi = BieYeFurnitureCreate_MBuy_NeedList_DemandMoney
	g_SelfJiaoZi = BieYeFurnitureCreate_MBuy_NeedList_SelfJiaozi
	g_SelfMoney = BieYeFurnitureCreate_MBuy_NeedList_SelfMoney
end


function BieYeFurnitureCreate_MBuy_OnHiden()
	BieYeFurnitureCreate_MBuy_Close()
end


--=========================================================
-- 事件处理
--=========================================================
function BieYeFurnitureCreate_MBuy_OnEvent(event)
	if (event == "OPEN_BIEYEFURCREATE_MBUY") then
		--1表示打开 2表示刷新
		local bOpen = tonumber(arg0)
		g_InterfaceType = tonumber(arg1)
		g_FurName = tostring(arg2)
		g_CostShiCai = tonumber(arg3)
		g_CostMuCai = tonumber(arg4)
		g_CostJinBi = tonumber(arg5)
		if(bOpen == 1) then
			BieYeFurnitureCreate_MBuy_Open()
		elseif(bOpen == 2) then
			if(this:IsVisible()) then
			--	BieYeFurnitureCreate_MBuy_FreshWindow()
				this:Hide()
				BieYeFurnitureCreate_MBuy_Open()
			end
		end
	elseif (event == "CLOSE_BIEYEFURCREATE_MBUY") then
		BieYeFurnitureCreate_MBuy_Close()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BieYeFurnitureCreate_MBuy_Close()
	end
end

function BieYeFurnitureCreate_MBuy_Open()
	if(this:IsVisible()) then
		return
	end
	BieYeFurnitureCreate_MBuy_FreshWindow()
	this:Show()
end
function BieYeFurnitureCreate_MBuy_FreshWindow()
	--刷新文字信息
	local desc = ""
	if(g_InterfaceType == 1) then
		g_Title:SetText("#{BYFUR_160531_221}")
		desc = ScriptGlobal_Format("#{BYFUR_160531_222}",g_FurName)
		g_Desc:SetText(desc)
		BieYeFurnitureCreate_MBuy_NeedList_Cailiao_Text:SetText("#{BYFUR_170315_311}")
		BieYeFurnitureCreate_MBuy_NeedList_SelfCailiao_Text:SetText("#{BYFUR_170315_312}")
	elseif( g_InterfaceType == 2) then
		g_Title:SetText("#{BYFUR_160531_227}")
		desc = ScriptGlobal_Format("#{BYFUR_160531_228}",g_FurName)
		g_Desc:SetText(desc)
		BieYeFurnitureCreate_MBuy_NeedList_Cailiao_Text:SetText("#{BYFUR_170315_305}")
		BieYeFurnitureCreate_MBuy_NeedList_SelfCailiao_Text:SetText("#{BYFUR_170315_306}")
	end
	BieYeFurnitureCreate_MBuy_CalculateMaxCount()
	local num = g_CanMaxCount
	if(g_CanMaxCount < g_MinCount) then
		num = g_MinCount
	elseif(g_CanMaxCount > g_MaxCount) then
		num = g_MaxCount
	end
	g_NumberText:SetText(num)
	BieYeFurnitureCreate_MBuy_FreshTips(tonumber(num))
end
function BieYeFurnitureCreate_MBuy_CalculateMaxCount()
	local JinBi = Player:GetData("MONEY_JZ") + Player:GetData("MONEY")
	local JinMax = math.floor(JinBi / g_CostJinBi)
	local MuCaiMax = g_MaxCount + 1
	local ShiCaiMax = g_MaxCount + 1
	if( g_CostShiCai > 0) then
		local shicai = BieYeUI:GetBieYeBaseInfo("ResStones")
		ShiCaiMax = math.floor(shicai / g_CostShiCai)
	end
	if( g_CostMuCai > 0) then
		local mucai = BieYeUI:GetBieYeBaseInfo("ResWoods")
		MuCaiMax = math.floor(mucai / g_CostMuCai)
	end
	--从三个里面取最小,最小值受金币限制返回1 受石材限制返回2 受木材限制返回3
	if(JinMax <= MuCaiMax and JinMax <= ShiCaiMax) then
		g_CanMaxCount = JinMax
		return 1
	elseif(ShiCaiMax < JinMax and ShiCaiMax <= MuCaiMax) then
		g_CanMaxCount = ShiCaiMax
		return 2
	elseif(MuCaiMax < JinMax and MuCaiMax < ShiCaiMax) then
		g_CanMaxCount = MuCaiMax
		return 3
	end
	return 0
end
function BieYeFurnitureCreate_MBuy_FreshTips(num)
	--local nMaxCount = BieYeFurnitureCreate_MBuy_CalCulateMaxCount()
	--g_Tips:SetText("")
	if(num == nil or g_SelfJiaoZi == 0 or g_SelfMoney == 0 or 
	g_SelfCaiLiao == 0 or g_NeedJiaoZi == 0 or g_NeedCaiLiao == 0) then
		return
	end
	local szTips = ""
	local nRet = BieYeFurnitureCreate_MBuy_CalculateMaxCount()
	-- if(nRet == 0) then
		-- return
	-- end
	local NeedCaiLiao = g_CostShiCai * num
	local MyCaiLiao = BieYeUI:GetBieYeBaseInfo("ResStones")
	local NeedJiaoZi = g_CostJinBi * num
	local MyJiaoZi = Player:GetData("MONEY_JZ")
	local MyMoney = Player:GetData("MONEY")
	if(NeedCaiLiao <= 0) then
		NeedCaiLiao = g_CostMuCai * num
		MyCaiLiao = BieYeUI:GetBieYeBaseInfo("ResWoods")
	end
	if(MyMoney + MyJiaoZi < NeedJiaoZi) then
		local Str = "#cFF0000"..NeedJiaoZi
	else
		g_NeedJiaoZi:SetProperty("MoneyNumber",tostring(NeedJiaoZi))
	end
	if(MyCaiLiao < NeedCaiLiao) then
		local Str = "#cFF0000"..NeedCaiLiao
		g_NeedCaiLiao:SetText(Str)
	else
		g_NeedCaiLiao:SetText(tostring(NeedCaiLiao))
	end
	g_SelfCaiLiao:SetText(tostring(MyCaiLiao))
	g_SelfJiaoZi:SetProperty("MoneyNumber",tostring(MyJiaoZi))
	g_SelfMoney:SetProperty("MoneyNumber",tostring(MyMoney))
	
	if(g_CanMaxCount < num) then
		BieYeFurnitureCreate_MBuy_Ok:Disable()
	else
		BieYeFurnitureCreate_MBuy_Ok:Enable()
	end

	-- if(nRet == 1 ) then
		-- szTips = ScriptGlobal_Format("#{BYFUR_160531_256}",g_CanMaxCount,g_FurName,g_CanMaxCount,g_FurName)
	-- elseif (nRet == 2) then
		-- szTips = ScriptGlobal_Format("#{BYFUR_160531_255}",BieYeUI:GetBieYeBaseInfo("ResStones"),g_CanMaxCount,g_FurName,g_CanMaxCount,g_FurName)
	-- elseif(nRet == 3) then
		-- szTips = ScriptGlobal_Format("#{BYFUR_160531_259}",BieYeUI:GetBieYeBaseInfo("ResWoods"),g_CanMaxCount,g_FurName,g_CanMaxCount,g_FurName)
	-- end
	--g_Tips:SetText(szTips)
end
function BieYeFurnitureCreate_MBuy_ButtonUp()
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		BieYeFurnitureCreate_MBuy_ClearClick()
	end
end
function BieYeFurnitureCreate_MBuy_ClearClick()
	g_ButtonDonwType = 0
	g_ButtonDonwTick = 0
	g_LastTickTime = 0
	KillTimer("BieYeFurnitureCreate_MBuy_OnTimer()")
end
function BieYeFurnitureCreate_MBuy_ButtonDown(nButtonType)
	if(g_ButtonDonwType ~= 0) then
		return
	end
	g_ButtonDonwType = nButtonType
	g_ButtonDonwTick = 1
	SetTimer("BieYeFurnitureCreate_MBuy","BieYeFurnitureCreate_MBuy_OnTimer()",20)
end
function BieYeFurnitureCreate_MBuy_OnTimer()
	if(g_ButtonDonwTick ~= 0) then
		local CurTime = OSAPI:GetTickCount()
		if(CurTime - g_LastTickTime >= g_TickInterval - g_ButtonDonwTick) then
			g_LastTickTime = CurTime
			g_ButtonDonwTick = g_ButtonDonwTick + 1
			if(g_ButtonDonwTick < 5) then
				return
			end
			if(g_ButtonDonwType == 1) then
				BieYeFurnitureCreate_MBuy_Add_Clicked()
			elseif(g_ButtonDonwType == 2) then
				BieYeFurnitureCreate_MBuy_Mini_Clicked()
			end
		end
	end	
end
function BieYeFurnitureCreate_MBuy_Close()
	if(this:IsVisible()) then
		g_NumberText:SetText(tostring(g_MinCount))
		BieYeFurnitureCreate_MBuy_ClearClick()
		g_FurName = ""
		g_CostShiCai = 0
		g_CostMuCai = 0
		g_CostJinBi = 0
		g_CanMaxCount = -1
		this:Hide()
	end
end

function BieYeFurnitureCreate_MBuy_Add_Clicked(nCount)
	if(nCount == nil) then
		nCount = 1
	end
	local num = tonumber(g_NumberText:GetText())
	if(num == nil or num < g_MinCount ) then
		num = g_MinCount
	end
	if(num < g_MaxCount) then
		num = num + nCount
		if(num > g_MaxCount) then
			num = g_MaxCount
		end
	end
	BieYeFurnitureCreate_MBuy_FreshTips(num)
	g_NumberText:SetText(tostring(num))
end
function BieYeFurnitureCreate_MBuy_Mini_Clicked(nCount)
	if(nCount == nil) then
		nCount = 1
	end
	local num = tonumber(g_NumberText:GetText())
	if(num == nil ) then
		num = g_MinCount
	end
	if(num > g_MinCount) then
		num = num - nCount
	end
	if(num < g_MinCount) then
		num = g_MinCount
	end
	BieYeFurnitureCreate_MBuy_FreshTips(num)
	g_NumberText:SetText(tostring(num))
end
--这个界面相当于只是获取数据的界面,真正的制作逻辑还是有BieYeFurnitureCreate这个界面控制
function BieYeFurnitureCreate_MBuy_OK_Click()
	local num = tonumber(g_NumberText:GetText())
	if(num ~= nil and num > 0 and num < 100) then
		if(num > g_CanMaxCount and g_CanMaxCount ~= 0) then
			num = g_CanMaxCount
		end
		if(g_CanMaxCount == 0) then
			local nRet = BieYeFurnitureCreate_MBuy_CalculateMaxCount()
			local szTip = ""
			if(nRet == 1) then
				szTip = ScriptGlobal_Format("#{BYFUR_160531_226}",num,g_FurName,g_CostJinBi*num)
			elseif(nRet == 2) then
				szTip = ScriptGlobal_Format("#{BYFUR_160531_225}",num,g_FurName,g_CostShiCai*num)
			elseif(nRet == 3) then
				szTip = ScriptGlobal_Format("#{BYFUR_160531_229}",num,g_FurName,g_CostMuCai*num)
			else
				return
			end
			PushDebugMessage(szTip)
			return
		end
		PushEvent("MBUY2BIEYEFURCREATE",num)
		return
	end
	if(num == nil or num < g_MinCount) then
		num = g_MinCount
	end
	if(num > g_MaxCount) then
		num = g_MaxCount
	end
	g_NumberText:SetText(tostring(num))
end
function BieYeFurnitureCreate_MBuy_TextCheck()
	local num = tonumber(g_NumberText:GetText())
	if(num == nil or num < g_MinCount) then
		g_NumberText:SetText(tostring(g_MinCount))
		num = g_MinCount
	end
	if(num > g_MaxCount) then
		g_NumberText:SetText(tostring(g_MaxCount))
		num = g_MaxCount
	end
	BieYeFurnitureCreate_MBuy_FreshTips(num)
end

function BieYeFurnitureCreate_MBuy_MaxClick()
	BieYeFurnitureCreate_MBuy_FreshWindow()
end