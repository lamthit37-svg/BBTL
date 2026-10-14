--!!!reloadscript =ErTongJieDaiBi_MBuy
local g_Frame_UnifiedPosition = ""
local g_ItemIdx = -1
local g_ItemPrice = -1
local g_ItemBind = -1
local g_ItemNum = -1
local g_ItemAllNum = -1
local g_CurNum = 1
local g_MaxCount = 0
local g_DuiHuanMax = -1

--=========
-- PreLoad()
--=========
function ErTongJieDaiBi_MBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
  this:RegisterEvent("UPDATE_YUANBAO",false)--元宝变化
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ErTongJieDaiBi_MBuy_OnLoad()
	g_Frame_UnifiedPosition = ErTongJieDaiBi_MBuy_Frame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function ErTongJieDaiBi_MBuy_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 99802506 then
		g_CurNum = 1
		g_ItemIdx = tonumber(Get_XParam_INT(0))
		g_ItemPrice = tonumber(Get_XParam_INT(1))
		g_ItemBind = tonumber(Get_XParam_INT(2))
		g_ItemNum = tonumber(Get_XParam_INT(3))
		g_ItemAllNum = tonumber(Get_XParam_INT(4))
		ErTongJieDaiBi_MBuy_Open()
		this:Activate()
  elseif event == "UPDATE_YUANBAO" then
    ErTongJieDaiBi_MBuy_UpdateCurMoneyInfo()
	elseif event == "HIDE_ON_SCENE_TRANSED" then	
		ErTongJieDaiBi_MBuy_Close_Clicked()
	elseif event == "VIEW_RESOLUTION_CHANGED" then		
		ErTongJieDaiBi_MBuy_On_ResetPos()	
	elseif event == "ADJEST_UI_POS" then	
		ErTongJieDaiBi_MBuy_On_ResetPos()
	end
end

--=========
-- 重置
--=========
function ErTongJieDaiBi_MBuy_On_ResetPos()
	ErTongJieDaiBi_MBuy_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 打开界面
--=========
function ErTongJieDaiBi_MBuy_Open()
	if g_ItemIdx == nil or g_ItemIdx <= 0 then
		return
	end
	if g_ItemPrice == nil or g_ItemPrice <= 0 then
		return
	end
	if g_ItemBind == nil or g_ItemBind < 0 then
		return
	end
	if g_ItemNum == nil or g_ItemNum < 0 then
		return
	end
	
	local theAction = nil
	if g_ItemBind == 1 then
		theAction = DataPool:CreateBindActionItemForShow(g_ItemIdx, 1)
	else
		theAction = DataPool:CreateActionItemForShow(g_ItemIdx, 1)
	end
	
	if theAction:GetID() ~= 0 then
		ErTongJieDaiBi_MBuy_But:SetActionItem(theAction:GetID())
		
		local strTemp = ScriptGlobal_Format("#{DBZH_250520_03}", theAction:GetName())
		ErTongJieDaiBi_MBuy_ItemInfo_Text:SetText(strTemp)
		
		local strNum = ScriptGlobal_Format("#{DBZH_250520_06}", tostring(g_ItemNum))
		ErTongJieDaiBi_MBuy_ItemInfo_Text2:SetText(strNum)
		
		local strPrice = ScriptGlobal_Format("#{DBZH_250520_04}", tostring(g_ItemPrice))		
		ErTongJieDaiBi_MBuy_ItemInfo_Lilianzhi:SetText(strPrice)
	else
		ErTongJieDaiBi_MBuy_But:SetActionItem(-1)
		ErTongJieDaiBi_MBuy_ItemInfo_Text:SetText("")
		ErTongJieDaiBi_MBuy_ItemInfo_Text2:SetText("")
		ErTongJieDaiBi_MBuy_ItemInfo_Lilianzhi:SetText("")
	end
	
	ErTongJieDaiBi_MBuy_InputNum:SetProperty("DefaultEditBox", "True")
	ErTongJieDaiBi_MBuy_InputNum:SetText(tostring(g_CurNum))
	ErTongJieDaiBi_MBuy_InputNum:SetSelected(0, -1)
	ErTongJieDaiBi_MBuy_UpdateMaxCount()
	ErTongJieDaiBi_MBuy_UpdateCurMoneyInfo()
	
	this:Show()
end

--=========
-- 更新元宝数量
--=========
function ErTongJieDaiBi_MBuy_UpdateCurMoneyInfo()
	if g_ItemPrice == nil or g_ItemPrice <= 0 then
		return
	end
	
	local nPrice = g_ItemPrice
	local needTokens = nPrice * g_CurNum
	local haveTokens = Player:GetData("YUANBAO")
	
	local strTemp = ScriptGlobal_Format("#{DBZH_250520_09}", tostring(needTokens))
	ErTongJieDaiBi_MBuy_Price_Lilianzhi:SetText(strTemp)
		
	if needTokens > haveTokens then	
		strTemp = ScriptGlobal_Format("#{DBZH_250520_11}", tostring(haveTokens))
		ErTongJieDaiBi_MBuy_Cash_Lilianzhi:SetText(strTemp)
	else
		strTemp = ScriptGlobal_Format("#{DBZH_250520_12}", tostring(haveTokens))
		ErTongJieDaiBi_MBuy_Cash_Lilianzhi:SetText(strTemp)
	end
end

--=========
-- 更新数量
--=========
function ErTongJieDaiBi_MBuy_UpdateMaxCount()	
	g_MaxCount = 0
	if g_ItemPrice == nil or g_ItemPrice <= 0 then
		return
	end
	if g_ItemNum == nil or g_ItemNum < 0 then
		return
	end
	if g_ItemAllNum == nil or g_ItemAllNum <= 0 then
		return
	end
	
	local limit_count = g_ItemAllNum - g_ItemNum
	
	local nPrice = g_ItemPrice
	local haveTokens = Player:GetData("YUANBAO")
	local nMaxCanBuyByMoney = math.floor(haveTokens/nPrice)
	
	if limit_count < nMaxCanBuyByMoney then
		g_MaxCount = limit_count
	else
		g_MaxCount = nMaxCanBuyByMoney
	end
end

--=========
-- 最大
--=========
function ErTongJieDaiBi_MBuy_CalMax()
	ErTongJieDaiBi_MBuy_UpdateMaxCount()
	ErTongJieDaiBi_MBuy_InputNum:SetText(tostring(g_MaxCount))
end

--=========
-- 文本变化
--=========
function ErTongJieDaiBi_MBuy_TextChanged()
	
	local nString = ErTongJieDaiBi_MBuy_InputNum:GetText()
	
	local nChangNum = 1
	
	if nString == nil or nString == "" then
		g_CurNum = 0
		ErTongJieDaiBi_MBuy_UpdateCurMoneyInfo()
		return
	else
		nChangNum = tonumber(nString)
	end
	
	if nChangNum >= g_MaxCount then
		nChangNum = g_MaxCount
	end
	
	if nChangNum <= 0 then
		nChangNum = 1
	end
	
	if g_CurNum ~= tonumber(nString) then
		g_CurNum = nChangNum
		ErTongJieDaiBi_MBuy_InputNum:SetText(tostring(g_CurNum))		
		ErTongJieDaiBi_MBuy_UpdateCurMoneyInfo()
	end
end

--=========
-- 关闭界面
--=========
function ErTongJieDaiBi_MBuy_Close_Clicked()
	this:Hide()
end

--=========
-- 隐藏清数据
--=========
function ErTongJieDaiBi_MBuy_OnHidden()
	g_CurNum = 1
	g_ItemIdx = -1
	g_ItemPrice = -1
	g_ItemBind = -1
	g_ItemNum = -1
	g_ItemAllNum = -1
end

--=========
-- 确定
--=========
function ErTongJieDaiBi_MBuy_OK_Clicked()
	
	if g_ItemIdx == nil or g_ItemIdx <= 0 then
		return
	end
	if g_ItemNum == nil or g_ItemNum < 0 then
		return
	end
	if g_ItemAllNum == nil or g_ItemAllNum <= 0 then
		return
	end

	--输入为0			
	local nString = ErTongJieDaiBi_MBuy_InputNum:GetText()
	if nString == nil or nString == "" then
		PushDebugMessage("#{DBZH_250520_16}")
		return
	end	
	if g_CurNum <= 0 then
		PushDebugMessage("#{DBZH_250520_16}")
		return
	end
	
	--安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	--密保
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
		return
	end	
	
	--输入超上限		
	local limit_count = g_ItemAllNum - g_ItemNum
	if limit_count < g_CurNum then
		PushDebugMessage("#{DBZH_250520_18}")
		return
	end

	--购买
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnDuiHuan" )
		Set_XSCRIPT_ScriptID( 998025 )
		Set_XSCRIPT_Parameter( 0, g_ItemIdx )
		Set_XSCRIPT_Parameter( 1, g_CurNum )
		Set_XSCRIPT_Parameter( 2, 0 )
		Set_XSCRIPT_ParamCount( 3 )
	Send_XSCRIPT()
	
	--关闭
	ErTongJieDaiBi_MBuy_Close_Clicked()
end
