-- SiXiangTu_Shop_Mbuy 四象图商店批量购买 2021-5-12 lishilong
-- !!!reloadscript =SiXiangTu_Shop_Mbuy
--

local g_SiXiangTu_Shop_Mbuy_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 1
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nUICommandID		= 79005004

-- local g_nMaxBuyItemNum	= 255
local g_nBuyItemNum			= 0

local g_nHaveDaibiPoint		= 0
local g_nItemIndex			= 0
local g_nItemID				= 0
local g_nItemNum			= 0
local g_nItemCost			= 0

--=========================================================
-- PreLoad
--=========================================================
function SiXiangTu_Shop_Mbuy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	if 1 == bCaredItem then
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	end
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	if 1 == bCaredYuanBao then
		this:RegisterEvent("UPDATE_YUANBAO", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function SiXiangTu_Shop_Mbuy_OnLoad()
	g_SiXiangTu_Shop_Mbuy_Frame_UnifiedPosition = SiXiangTu_Shop_Mbuy_Frame:GetProperty("UnifiedPosition")
	-- SiXiangTu_Shop_Mbuy_OK_Button : SetEvent("Clicked", "SiXiangTu_Shop_Mbuy_ConfirmClick()")

	-- SiXiangTu_Shop_Mbuy_Price_Lilianzhi : SetText("999")
end

--=========================================================
-- OnEvent
--=========================================================
function SiXiangTu_Shop_Mbuy_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= tonumber(arg1)
		if nil == nOpType then
			nOpType = 0
		end

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				SiXiangTu_Shop_Mbuy_Close_Clicked()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= tonumber(arg2)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SiXiangTu_Shop_Mbuy_Close_Clicked()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_SiXiangTu_Shop_Mbuy()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	SiXiangTu_Shop_Mbuy_Close_Clicked()
			-- end
			SiXiangTu_Shop_Mbuy_Reset()
			SiXiangTu_Shop_Mbuy_Frame_On_ResetPos()
			this:Show()
			SiXiangTu_Shop_Mbuy_ParamInit()
			SiXiangTu_Shop_Mbuy_MoneyUpdate()
			SiXiangTu_Shop_Mbuy_YuanBaoUpdate()
			SiXiangTu_Shop_Mbuy_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SiXiangTu_Shop_Mbuy_Close_Clicked()
					end
				end
			end
			if this:IsVisible() then
				SiXiangTu_Shop_Mbuy_ParamInit()
				SiXiangTu_Shop_Mbuy_Update(0)
			end
		end

		-- 二次确认框
		-- if 3 == nOpType then
		-- 	local strMsg = Get_XParam_STR(0)
		-- 	-- g_nComfirmParam1 = Get_XParam_INT(1)
		-- 	-- ["Type"] "Ok" "YesNo"
		-- 	MessageBoxSelf3("SiXiangTu_Shop_Mbuy_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		-- end

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			SiXiangTu_Shop_Mbuy_Close_Clicked()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			SiXiangTu_Shop_Mbuy_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		SiXiangTu_Shop_Mbuy_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		SiXiangTu_Shop_Mbuy_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		SiXiangTu_Shop_Mbuy_Close_Clicked()
	
	elseif (event == "ADJEST_UI_POS" ) then
		SiXiangTu_Shop_Mbuy_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SiXiangTu_Shop_Mbuy_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function SiXiangTu_Shop_Mbuy_ParamInit()
	g_nHaveDaibiPoint 	= tonumber(arg3)
	g_nItemIndex 		= tonumber(arg4)
	g_nItemID 			= tonumber(arg5)
	g_nItemNum 			= tonumber(arg6)
	g_nItemCost 		= tonumber(arg7)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
-- function SiXiangTu_Shop_Mbuy_OnComfirmedBack(strRet)
-- 	if nil == strRet then
-- 		return
-- 	end

-- 	if "Yes" == strRet or "Ok" == strRet then

-- 	end

-- 	if "No" == strRet then
		
-- 	end
-- end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =SiXiangTu_Shop_Mbuy
function SiXiangTu_Shop_Mbuy_Update(bOpen)

	-- 首次打开的默认值设置
	if 1 == bOpen then
		SiXiangTu_Shop_Mbuy_InputNum : SetProperty("DefaultEditBox", "True")
		SiXiangTu_Shop_Mbuy_InputNum : SetText(tostring(1))
		SiXiangTu_Shop_Mbuy_InputNum : SetSelected( 0, -1 )
	end

	-- 购买物品信息
	-- local theAction = DataPool:CreateActionItemForShow(g_nItemID, g_nItemNum)
	local theAction = DataPool:CreateBindActionItemForShow(g_nItemID, g_nItemNum)
	SiXiangTu_Shop_Mbuy_But : SetActionItem(theAction:GetID())

	local strItemName = DataPool:Lua_GetItemNameByIndex(g_nItemID)
	SiXiangTu_Shop_Mbuy_ItemInfo_Text : SetText(ScriptGlobal_Format("#{SXTZ_210510_07}", strItemName))
	SiXiangTu_Shop_Mbuy_ItemInfo_Lilianzhi : SetText(ScriptGlobal_Format("#{SXTZ_210510_08}", g_nItemCost))

	-- 一共需要的点数
	local nTotalNeedPoint = g_nBuyItemNum * g_nItemCost
	SiXiangTu_Shop_Mbuy_Price_Lilianzhi : SetText(ScriptGlobal_Format("#{SXTZ_210510_24}", nTotalNeedPoint))

	-- 拥有的点数
	if nTotalNeedPoint > g_nHaveDaibiPoint then
		-- 点数不够
		SiXiangTu_Shop_Mbuy_Cash_Lilianzhi : SetText(ScriptGlobal_Format("#{SXTZ_210510_26}", g_nHaveDaibiPoint))
	else
		-- 点数足够
		SiXiangTu_Shop_Mbuy_Cash_Lilianzhi : SetText(ScriptGlobal_Format("#{SXTZ_210510_27}", g_nHaveDaibiPoint))
	end
end

--=========================================================
-- 改变购买数量
--=========================================================
function SiXiangTu_Shop_Mbuy_TextChanged()
	local nStringInput = SiXiangTu_Shop_Mbuy_InputNum : GetText()
	
	local nInputNum = 1
	
	if nStringInput == nil or nStringInput == "" then
		g_nBuyItemNum = 0
		SiXiangTu_Shop_Mbuy_Update(0)
		return
	else
		nInputNum = tonumber(nStringInput)
	end

	local nCanBuyNum = math.floor(g_nHaveDaibiPoint / g_nItemCost)
	-- if nCanBuyNum > g_nMaxBuyItemNum then
	-- 	nCanBuyNum = g_nMaxBuyItemNum
	-- end
	if(nInputNum > nCanBuyNum) then
		nInputNum = nCanBuyNum
	end
	if nInputNum <= 0 then
		nInputNum = 1
	end

	if g_nBuyItemNum ~= tonumber(nStringInput) then
		g_nBuyItemNum = nInputNum
		SiXiangTu_Shop_Mbuy_InputNum : SetText(tostring(g_nBuyItemNum))
		SiXiangTu_Shop_Mbuy_Update(0)
	end
end

--=========================================================
-- 最大购买数量
--=========================================================
function SiXiangTu_Shop_Mbuy_CalMax()

	local nInputNum = tonumber(SiXiangTu_Shop_Mbuy_InputNum : GetText())
	local nCanBuyNum = math.floor(g_nHaveDaibiPoint / g_nItemCost)

	-- if nCanBuyNum > g_nMaxBuyItemNum then
	-- 	nCanBuyNum = g_nMaxBuyItemNum
	-- end

	if nCanBuyNum < 1 then
		nCanBuyNum = 1
	end

	g_nBuyItemNum = nCanBuyNum
	SiXiangTu_Shop_Mbuy_InputNum : SetText(tostring(g_nBuyItemNum))
	SiXiangTu_Shop_Mbuy_Update(0)
end

--=========================================================
-- 重置界面
--=========================================================
function SiXiangTu_Shop_Mbuy_Reset()
	g_nBuyItemNum 		= 0
	g_nHaveDaibiPoint 	= 0
	g_nItemIndex 		= 0
	g_nItemID 			= 0
	g_nItemNum 			= 0
	g_nItemCost 		= 0

	SiXiangTu_Shop_Mbuy_InputNum : SetProperty("DefaultEditBox", "False");
end

--=========================================================
-- 界面确认按钮
--=========================================================
function SiXiangTu_Shop_Mbuy_OK_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnBuyFromShop")
		Set_XSCRIPT_ScriptID( 790050 )
		Set_XSCRIPT_Parameter(0, g_nServerObjID)		-- targetId
		Set_XSCRIPT_Parameter(1, 1)						-- bConfirmed
		Set_XSCRIPT_Parameter(2, g_nItemIndex)			-- nSelectIndex
		Set_XSCRIPT_Parameter(3, g_nBuyItemNum)			-- nBuyNum
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()

	SiXiangTu_Shop_Mbuy_Close_Clicked()
end

--=========================================================
-- 关闭界面
--=========================================================
function SiXiangTu_Shop_Mbuy_Close_Clicked()	
	this:Hide()
	StopCareObject_SiXiangTu_Shop_Mbuy()
	-- 重置
	SiXiangTu_Shop_Mbuy_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="SiXiangTu_Shop_Mbuy_OnHidden();" />
--=========================================================
function SiXiangTu_Shop_Mbuy_OnHidden()
	StopCareObject_SiXiangTu_Shop_Mbuy()
	-- 重置
	SiXiangTu_Shop_Mbuy_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_SiXiangTu_Shop_Mbuy()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "SiXiangTu_Shop_Mbuy")
end

function StopCareObject_SiXiangTu_Shop_Mbuy()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "SiXiangTu_Shop_Mbuy")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function SiXiangTu_Shop_Mbuy_MoneyUpdate()
	-- SiXiangTu_Shop_Mbuy_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- SiXiangTu_Shop_Mbuy_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function SiXiangTu_Shop_Mbuy_YuanBaoUpdate()
	-- SiXiangTu_Shop_Mbuy_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function SiXiangTu_Shop_Mbuy_Frame_On_ResetPos()
	SiXiangTu_Shop_Mbuy_Frame:SetProperty("UnifiedPosition", g_SiXiangTu_Shop_Mbuy_Frame_UnifiedPosition)
end