-- WinterShopCoin_BatchBuy

local g_WinterShopCoin_BatchBuy_Frame_UnifiedPosition

local g_nUICommandID		= 99896804
local g_curpage				= 0
local g_nBuyItemNum			= 0
local g_nWeekDaibi			= 0

local g_nItemID				= 39924581
local g_nItemNum			= 1
local g_nItemCost			= 10

--周限量上限
local g_Max_WeekDaibiCount  = 200

--=========================================================
-- PreLoad
--=========================================================
function WinterShopCoin_BatchBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)

	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function WinterShopCoin_BatchBuy_OnLoad()
	g_WinterShopCoin_BatchBuy_Frame_UnifiedPosition = WinterShopCoin_BatchBuy_Frame:GetProperty("UnifiedPosition")

end

--=========================================================
-- OnEvent
--=========================================================
function WinterShopCoin_BatchBuy_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then

		-- 0 关闭, 1 打开, 2 刷新
		local nOpType 	= Get_XParam_INT(0)
		
		if nil == nOpType then
			nOpType = 0
		end
	
		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				WinterShopCoin_BatchBuy_Close_Clicked()
			end
		end

		-- 打开界面
		if 1 == nOpType then

			WinterShopCoin_BatchBuy_Reset()
			WinterShopCoin_BatchBuy_Frame_On_ResetPos()
			WinterShopCoin_BatchBuy_ParamInit()
			WinterShopCoin_BatchBuy_Update(1)
			this:Show()
		end
			
		-- 刷新界面
		if 2 == nOpType then

			if this:IsVisible() then
				WinterShopCoin_BatchBuy_ParamInit()
				WinterShopCoin_BatchBuy_Update(0)
			end
		end

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" then
		WinterShopCoin_BatchBuy_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		WinterShopCoin_BatchBuy_Close_Clicked()
	
	elseif (event == "ADJEST_UI_POS" ) then
		WinterShopCoin_BatchBuy_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WinterShopCoin_BatchBuy_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function WinterShopCoin_BatchBuy_ParamInit()
	g_nWeekDaibi 	= Get_XParam_INT(1)
	g_curpage		= Get_XParam_INT(2)
end

--=========================================================
-- 界面更新
--=========================================================
function WinterShopCoin_BatchBuy_Update(bOpen)

	-- 首次打开的默认值设置
	if 1 == bOpen then
		WinterShopCoin_BatchBuy_NumberInput : SetProperty("DefaultEditBox", "True")
		WinterShopCoin_BatchBuy_NumberInput : SetText(tostring(1))
		WinterShopCoin_BatchBuy_NumberInput : SetSelected( 0, -1 )
	end

	-- 购买物品信息
	local theAction = DataPool:CreateActionItemForShow(g_nItemID, g_nItemNum)
	WinterShopCoin_BatchBuy_Item:SetActionItem(theAction:GetID())

	local strItemName = DataPool:Lua_GetItemNameByIndex(g_nItemID)
	WinterShopCoin_BatchBuy_ItemName:SetText(ScriptGlobal_Format("#{DJWH_231201_46}", strItemName))
	WinterShopCoin_BatchBuy_ItemPrice:SetText(ScriptGlobal_Format("#{DJWH_231201_202}", g_nItemCost))

	-- 元宝信息
	WinterShopCoin_BatchBuy_YuanBaoUpdate()
	
end

--=========================================================
-- 改变购买数量
--=========================================================
function WinterShopCoin_BatchBuy_TextChanged()
	local nStringInput = WinterShopCoin_BatchBuy_NumberInput:GetText()
	
	local nInputNum = 1
	
	if nStringInput == nil or nStringInput == "" then
		g_nBuyItemNum = 0
		WinterShopCoin_BatchBuy_Update(0)
		return
	else
		nInputNum = tonumber(nStringInput)
	end

	local nHaveYB = Player:GetData("YUANBAO")
	local nCanBuyNum = math.floor(nHaveYB / g_nItemCost)

	--剩余可购买数量
	local restcount = g_Max_WeekDaibiCount-g_nWeekDaibi
	if restcount < nCanBuyNum then
		nCanBuyNum = restcount
	end
	
	if(nInputNum > nCanBuyNum) then
		nInputNum = nCanBuyNum
	end
	if nInputNum <= 0 then
		nInputNum = 1
	end

	if g_nBuyItemNum ~= tonumber(nStringInput) then
		g_nBuyItemNum = nInputNum
		WinterShopCoin_BatchBuy_NumberInput:SetText(tostring(g_nBuyItemNum))
		WinterShopCoin_BatchBuy_Update(0)
	end
end

--=========================================================
-- 最大购买数量
--=========================================================
function WinterShopCoin_BatchBuy_OnMax()
	local nHaveYB = Player:GetData("YUANBAO")
	
	local nCanBuyNum = math.floor(nHaveYB / g_nItemCost)
	if nCanBuyNum < 1 then
		nCanBuyNum = 1
	end
	
	--剩余可购买数量
	local restcount = g_Max_WeekDaibiCount-g_nWeekDaibi
	if restcount < nCanBuyNum then
		nCanBuyNum = restcount
	end
	
	g_nBuyItemNum = nCanBuyNum
	WinterShopCoin_BatchBuy_NumberInput : SetText(tostring(g_nBuyItemNum))
	WinterShopCoin_BatchBuy_Update(0)
end

--=========================================================
-- 重置界面
--=========================================================
function WinterShopCoin_BatchBuy_Reset()
	g_nBuyItemNum 	= 0
	g_nWeekDaibi	= 0

	WinterShopCoin_BatchBuy_NumberInput : SetProperty("DefaultEditBox", "False");
end

--=========================================================
-- 界面确认按钮
--=========================================================
function WinterShopCoin_BatchBuy_OnOK()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("BuyConfirm")
		Set_XSCRIPT_ScriptID( 998968 )
		Set_XSCRIPT_Parameter(0, g_nBuyItemNum)			-- nBuyNum
		Set_XSCRIPT_Parameter(1, g_curpage)
		Set_XSCRIPT_Parameter(2, 1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

--=========================================================
-- 关闭界面
--=========================================================
function WinterShopCoin_BatchBuy_Close_Clicked()	
	this:Hide()
	-- 重置
	WinterShopCoin_BatchBuy_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="WinterShopCoin_BatchBuy_OnHidden();" />
--=========================================================
function WinterShopCoin_BatchBuy_OnHidden()
	-- 重置
	WinterShopCoin_BatchBuy_Reset()
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function WinterShopCoin_BatchBuy_YuanBaoUpdate()
	-- 需要元宝数
	local nTotalNeedYB = g_nBuyItemNum * g_nItemCost
	WinterShopCoin_BatchBuy_TextNeedNum:SetText(ScriptGlobal_Format("#{DJWH_231201_47}", nTotalNeedYB))
	
	local nHaveYB = Player:GetData("YUANBAO")
	if nTotalNeedYB > nHaveYB then
		--不够
		WinterShopCoin_BatchBuy_TextHaveNum:SetText(ScriptGlobal_Format("#{DJWH_231201_52}", nHaveYB))
	else
		--足够
		WinterShopCoin_BatchBuy_TextHaveNum:SetText(ScriptGlobal_Format("#{DJWH_231201_53}", nHaveYB))
	end
	
end

--=========================================================
-- 界面位置
--=========================================================
function WinterShopCoin_BatchBuy_Frame_On_ResetPos()
	WinterShopCoin_BatchBuy_Frame:SetProperty("UnifiedPosition", g_WinterShopCoin_BatchBuy_Frame_UnifiedPosition)
end