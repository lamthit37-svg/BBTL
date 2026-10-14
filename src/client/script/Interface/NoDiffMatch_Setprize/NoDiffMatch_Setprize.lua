local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_ServerTargetId = -1
local g_CaredObjectId = -1
local g_golden_totalnum = 0
local g_silver_totalnum = 0
local g_golden_num = 0
local g_silver_num = 0
local g_last_num1 = "0"
local g_last_num2 = "0"
local g_box_max = 100
local g_box1_cost = 50 --金箱子花费元宝数目 
local g_box2_cost = 500000 --银箱子花费金币数目
local g_block = false


function NoDiffMatch_Setprize_PreLoad()
	this:RegisterEvent("CORPS_SHOW_VOTEPRIZE_2018")
	this:RegisterEvent("MONEY_CHANGE_EX")
	this:RegisterEvent("UPDATE_YUANBAO");
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_Setprize_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_Setprize_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_Setprize_Frame:GetProperty("UnifiedYPosition");
end

function NoDiffMatch_Setprize_BeginCareObject( serverId )
	NoDiffMatch_Setprize_StopCareObject()
	local clientId = DataPool:GetNPCIDByServerID(serverId)
	if clientId == -1 then
		return 0
	end
	this:CareObject( clientId, 1, "NoDiffMatch_Setprize" )
	g_ServerTargetId = serverId
	g_CaredObjectId = clientId
end

function NoDiffMatch_Setprize_StopCareObject()
	if g_CaredObjectId ~= -1 then
		this:CareObject(g_CaredObjectId, 0, "NoDiffMatch_Setprize")
		g_CaredObjectId = -1
	end
	g_ServerTargetId = -1
end							

function NoDiffMatch_Setprize_OnEvent(event)
	if event  == "CORPS_SHOW_VOTEPRIZE_2018" then
		NoDiffMatch_Setprize_Show()
		
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		NoDiffMatch_SetprizeYin_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		NoDiffMatch_SetprizeJin_SelfMoney:SetText(tostring(Player:GetData("YUANBAO")))
		
	elseif( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_Setprize_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_Setprize_ResetPos()
		
	end
end


function NoDiffMatch_Setprize_OnClose()
	NoDiffMatch_Setprize_StopCareObject()
	this:Hide()
end

function NoDiffMatch_Setprize_Show()
	NoDiffMatch_Setprize_BeginCareObject(tonumber(arg0))
	
	g_golden_num = tonumber(arg1)
	g_golden_totalnum = tonumber(arg2)
	NoDiffMatch_SetprizeJin_Desc_Text:SetText(ScriptGlobal_Format("#{WCTP_180211_48}", tostring(g_box_max-g_golden_num)))
	NoDiffMatch_SetprizeJin_Num:SetText("1")
	g_last_num1 = "1"
	NoDiffMatch_SetprizeJin_DemandMoney:SetText(tostring(g_box1_cost))
	NoDiffMatch_SetprizeJin_SelfMoney:SetText(tostring(Player:GetData("YUANBAO")))
	NoDiffMatch_SetprizeJin_OwnNum:SetText(tostring(g_golden_totalnum))
	local jinboxtips = ScriptGlobal_Format("#{WCTP_180211_49}", tostring(g_golden_totalnum))
	NoDiffMatch_SetprizeJin_Item:SetToolTip(jinboxtips)
	
	g_silver_num = tonumber(arg3)
	g_silver_totalnum = tonumber(arg4)
	NoDiffMatch_Setprize_Desc_Text:SetText(ScriptGlobal_Format("#{WCTP_180211_53}", tostring(g_box_max-g_silver_num)))
	NoDiffMatch_SetprizeYin_Num:SetText("1")
	g_last_num2 = "1"
	NoDiffMatch_SetprizeYin_DemandMoney:SetProperty("MoneyNumber", ""..g_box2_cost)
	NoDiffMatch_SetprizeYin_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	NoDiffMatch_SetprizeYin_OwnNum:SetText(tostring(g_silver_totalnum))
	local yinboxtips = ScriptGlobal_Format("#{WCTP_180211_54}", tostring(g_silver_totalnum))
	NoDiffMatch_SetprizeYin_Item:SetToolTip(yinboxtips)
	
	this:Show()
end

function NoDiffMatch_Setprize_OnAdd1()
	local cur = NoDiffMatch_SetprizeJin_Num:GetText()
	local num = tonumber(cur)
	if num == nil then
		num = 1
	end
	
	if num >= g_box_max then
		num = g_box_max
	else
		num = num + 1
	end
	NoDiffMatch_SetprizeJin_Num:SetText(tostring(num))
	local needcost = tostring(num * g_box1_cost)
	NoDiffMatch_SetprizeJin_DemandMoney:SetText(tostring(needcost))
end

function NoDiffMatch_Setprize_OnDec1()
	local cur = NoDiffMatch_SetprizeJin_Num:GetText()
	local num = tonumber(cur)
	if num == nil then
		num = 1
	end
	
	if num <= 1 then
		num = 1
	else
		num = num - 1
	end
	NoDiffMatch_SetprizeJin_Num:SetText(tostring(num))
	local needcost = tostring(num * g_box1_cost)
	NoDiffMatch_SetprizeJin_DemandMoney:SetText(tostring(needcost))
end

function NoDiffMatch_Setprize_OnAdd2()
	local cur = NoDiffMatch_SetprizeYin_Num:GetText()
	local num = tonumber(cur)
	if num == nil then
		num = 1
	end
	
	if num >= g_box_max then
		num = g_box_max
	else
		num = num + 1
	end
	NoDiffMatch_SetprizeYin_Num:SetText(tostring(num))
	local needcost = tostring(num * g_box2_cost)
	NoDiffMatch_SetprizeYin_DemandMoney:SetProperty("MoneyNumber", needcost)
end

function NoDiffMatch_Setprize_OnDec2()
	local cur = NoDiffMatch_SetprizeYin_Num:GetText()
	local num = tonumber(cur)
	if num == nil then
		num = 1
	end
	
	if num <= 1 then
		num = 1
	else
		num = num - 1
	end
	NoDiffMatch_SetprizeYin_Num:SetText(tostring(num))
	local needcost = tostring(num * g_box2_cost)
	NoDiffMatch_SetprizeYin_DemandMoney:SetProperty("MoneyNumber", needcost)
end

function NoDiffMatch_Setprize_OnTimer()
	g_block = false
end

function NoDiffMatch_Setprize_OnOk1()
	if g_block then
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_20}")
		return
	end
	
	local num = NoDiffMatch_SetprizeJin_Num:GetText()
	if tonumber(num) <= 0 then
		return
	end
	
	if tonumber(num) > g_box_max - g_golden_num then
		PushDebugMessage("#{WCTP_180211_57}")
		return
	end
	
	local yuanbao = Player:GetData("YUANBAO")
	if num*g_box1_cost > yuanbao then
		local tips = ScriptGlobal_Format("#{WCTP_180211_58}", tostring(num), tostring(num*g_box1_cost))
		PushDebugMessage(tips)
		return
	end
	
	CorpsUI_2018:VoteSetPrize( 1, g_golden_num, tonumber(num) )
	this:Hide()
	KillTimer("NoDiffMatch_Setprize_OnTimer()")
	SetTimer("NoDiffMatch_Setprize","NoDiffMatch_Setprize_OnTimer()", 2000)
	g_block = true
	NoDiffMatch_Setprize_OnClose()
end

function NoDiffMatch_Setprize_OnOk2()
	if g_block then
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_20}")
		return
	end
	
	local num = NoDiffMatch_SetprizeYin_Num:GetText()
	if tonumber(num) <= 0 then
		return
	end
	
	if tonumber(num) > g_box_max - g_silver_num then
		PushDebugMessage("#{WCTP_180211_60}")
		return
	end
	
	local money = Player:GetData("MONEY")
	if num*g_box2_cost > money then
		local tips = ScriptGlobal_Format("#{WCTP_180211_61}", tostring(num), tostring(num*g_box2_cost))
		PushDebugMessage(tips)
		return
	end
	
	CorpsUI_2018:VoteSetPrize( 2, g_silver_num, tonumber(num) )
	this:Hide()
	KillTimer("NoDiffMatch_Setprize_OnTimer()")
	SetTimer("NoDiffMatch_Setprize","NoDiffMatch_Setprize_OnTimer()", 2000)
	g_block = true
	NoDiffMatch_Setprize_OnClose()
end


function NoDiffMatch_Setprize_OnNumChanged1()
	local num = NoDiffMatch_SetprizeJin_Num:GetText()
	if not num or num == "" then
		NoDiffMatch_SetprizeJin_Num:SetText("1")
	elseif tonumber(num) == 0 then
		NoDiffMatch_SetprizeJin_Num:SetText("1")
	else
		local needcost = tonumber(num) * g_box1_cost
		NoDiffMatch_SetprizeJin_DemandMoney:SetText(tostring(needcost))
	end
end

function NoDiffMatch_Setprize_OnNumChanged2()
	local num = NoDiffMatch_SetprizeYin_Num:GetText()
	if not num or num == "" then
		NoDiffMatch_SetprizeJin_Num:SetText("1")
	elseif tonumber(num) == 0 then
		NoDiffMatch_SetprizeJin_Num:SetText("1")
	else
		NoDiffMatch_SetprizeYin_DemandMoney:SetProperty("MoneyNumber", tostring(g_box2_cost * tonumber(num)) )
		g_last_num2 = num
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_Setprize_ResetPos()
	NoDiffMatch_Setprize_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_Setprize_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
