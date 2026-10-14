-- WinterShop_BatchBuy

local g_WinterShop_BatchBuy_Frame_UnifiedPosition

local g_nUICommandID		= 99896806

local g_nBuyItemNum			= 0

local g_nIndex	=0
local g_nItemCost			= 0
local g_daibicount			= 0
local g_limitcount			= 0
local g_Max_PageItem 		= 10
--=========================================================
-- PreLoad
--=========================================================
function WinterShop_BatchBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)

	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function WinterShop_BatchBuy_OnLoad()
	g_WinterShop_BatchBuy_Frame_UnifiedPosition = WinterShop_BatchBuy_Frame:GetProperty("UnifiedPosition")

end

--=========================================================
-- OnEvent
--=========================================================
function WinterShop_BatchBuy_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新
		local nOpType 	= Get_XParam_INT(0)
		if nil == nOpType then
			nOpType = 0
		end
	
		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				WinterShop_BatchBuy_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then

			WinterShop_BatchBuy_Reset()
			WinterShop_BatchBuy_Frame_On_ResetPos()
			WinterShop_BatchBuy_ParamInit()
			WinterShop_BatchBuy_Update(1)
			this:Show()
		end
			
		-- 刷新界面
		if 2 == nOpType then

			if this:IsVisible() then
				WinterShop_BatchBuy_ParamInit()
				WinterShop_BatchBuy_Update(0)
			end
		end

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" then
		WinterShop_BatchBuy_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		WinterShop_BatchBuy_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		WinterShop_BatchBuy_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WinterShop_BatchBuy_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function WinterShop_BatchBuy_ParamInit()
	g_nIndex 	= Get_XParam_INT(1)
	g_daibicount = Get_XParam_INT(2)
	g_limitcount = Get_XParam_INT(3)
end

--=========================================================
-- 界面更新
--=========================================================
function WinterShop_BatchBuy_Update(bOpen)

	-- 首次打开的默认值设置
	if 1 == bOpen then
		WinterShop_BatchBuy_NumberInput : SetProperty("DefaultEditBox", "True")
		WinterShop_BatchBuy_NumberInput : SetText(tostring(1))
		WinterShop_BatchBuy_NumberInput : SetSelected( 0, -1 )
	end
	
	-- 购买物品信息
	local nNeedDaibi, nItemID, nNum, nLimit, nLimitType = DataPool:LuaFnGetWinterShopInfo(g_nIndex)
	if nNeedDaibi == nil or nNeedDaibi < 0 then
		return
	end
	g_nItemCost = nNeedDaibi
	
	local theAction = DataPool:CreateBindActionItemForShow(nItemID, nNum)
	WinterShop_BatchBuy_Item:SetActionItem(theAction:GetID())

	local strItemName = DataPool:Lua_GetItemNameByIndex(nItemID)
	WinterShop_BatchBuy_ItemName:SetText(ScriptGlobal_Format("#{DJWH_231201_46}", strItemName))
	WinterShop_BatchBuy_ItemPrice:SetText(ScriptGlobal_Format("#{DJWH_231201_203}", nNeedDaibi))


	local nTotalNeedDB = g_nBuyItemNum * nNeedDaibi
	WinterShop_BatchBuy_TextNeedNum:SetText(ScriptGlobal_Format("#{DJWH_231201_47}", nTotalNeedDB))
	
	local nHaveDB = g_daibicount
	if nTotalNeedDB > nHaveDB then
		--不够
		WinterShop_BatchBuy_TextHaveNum:SetText(ScriptGlobal_Format("#{DJWH_231201_52}", nHaveDB))
	else
		--足够
		WinterShop_BatchBuy_TextHaveNum:SetText(ScriptGlobal_Format("#{DJWH_231201_53}", nHaveDB))
	end
	
	if nLimit > 0 and nLimitType > 0 then
		WinterShop_BatchBuyBtnNumber:Show()
		WinterShop_BatchBuyBtnNumber:SetText(nLimit-g_limitcount)
	else
		WinterShop_BatchBuyBtnNumber:Hide()
	end
	
		
end

--=========================================================
-- 改变购买数量
--=========================================================
function WinterShop_BatchBuy_TextChanged()
	local nStringInput = WinterShop_BatchBuy_NumberInput:GetText()
	
	local nInputNum = 1
	
	if nStringInput == nil or nStringInput == "" then
		g_nBuyItemNum = 0
		WinterShop_BatchBuy_Update(0)
		return
	else
		nInputNum = tonumber(nStringInput)
	end

	local nHaveDB = g_daibicount
	local nCanBuyNum = math.floor(nHaveDB / g_nItemCost)

	local nNeedDaibi, nItemID, nNum, nLimit, nLimitType = DataPool:LuaFnGetWinterShopInfo(g_nIndex)
	if nLimit > 0 and nLimitType > 0 then
		if nCanBuyNum > nLimit-g_limitcount then
			nCanBuyNum = nLimit-g_limitcount
		end
	end
	
	if(nInputNum > nCanBuyNum) then
		nInputNum = nCanBuyNum
	end
	if nInputNum <= 0 then
		nInputNum = 1
	end

	if g_nBuyItemNum ~= tonumber(nStringInput) then
		g_nBuyItemNum = nInputNum
		WinterShop_BatchBuy_NumberInput:SetText(tostring(g_nBuyItemNum))
		WinterShop_BatchBuy_Update(0)
	end
end

--=========================================================
-- 最大购买数量
--=========================================================
function WinterShop_BatchBuy_OnMax()
	local nHaveDB = g_daibicount
	
	local nCanBuyNum = math.floor(nHaveDB / g_nItemCost)

	local nNeedDaibi, nItemID, nNum, nLimit, nLimitType = DataPool:LuaFnGetWinterShopInfo(g_nIndex)
	if nLimit > 0 and nLimitType > 0 then
		if nCanBuyNum > nLimit-g_limitcount then
			nCanBuyNum = nLimit-g_limitcount
		end
	end
		
	if nCanBuyNum < 1 then
		nCanBuyNum = 1
	end
	
	g_nBuyItemNum = nCanBuyNum
	WinterShop_BatchBuy_NumberInput : SetText(tostring(g_nBuyItemNum))
	WinterShop_BatchBuy_Update(0)
end

--=========================================================
-- 重置界面
--=========================================================
function WinterShop_BatchBuy_Reset()
	g_nIndex = 0
	g_nBuyItemNum 	= 0
	g_nItemCost		= 0
	g_daibicount	= 0
	g_limitcount	= 0
	WinterShop_BatchBuy_NumberInput : SetProperty("DefaultEditBox", "False");
end

--=========================================================
-- 界面确认按钮
--=========================================================
function WinterShop_BatchBuy_OnOK()
	if g_nIndex < 1 or g_nIndex > g_Max_PageItem then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoExchange" )
		Set_XSCRIPT_ScriptID( 998968 )
		Set_XSCRIPT_Parameter(0,g_nIndex)
		Set_XSCRIPT_Parameter(1,g_nBuyItemNum)		
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
	
	WinterShop_BatchBuy_OnClose()
end

--=========================================================
-- 关闭界面
--=========================================================
function WinterShop_BatchBuy_OnClose()	
	this:Hide()
	-- 重置
	WinterShop_BatchBuy_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="WinterShop_BatchBuy_OnHidden();" />
--=========================================================
function WinterShop_BatchBuy_OnHidden()
	-- 重置
	WinterShop_BatchBuy_Reset()
end


--=========================================================
-- 界面位置
--=========================================================
function WinterShop_BatchBuy_Frame_On_ResetPos()
	WinterShop_BatchBuy_Frame:SetProperty("UnifiedPosition", g_WinterShop_BatchBuy_Frame_UnifiedPosition)
end