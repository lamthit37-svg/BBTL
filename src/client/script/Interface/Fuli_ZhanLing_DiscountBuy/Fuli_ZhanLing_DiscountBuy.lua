-- Fuli_ZhanLing_DiscountBuy 战令打折券 2020-7-2 lishilong
-- !!!reloadscript =Fuli_ZhanLing_DiscountBuy
--

local g_Fuli_ZhanLing_DiscountBuy_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nMainUICommandID	= 79003501

-- 参数
local g_nUsedItemBagIndex	= -1
local g_nOriginalYuanBao	= -1
local g_nDisCountRate		= -1
local g_nLifeYear			= -1
local g_nLifeMonth			= -1
local g_nLifeDaysofMonth	= -1

local g_tShowInfo			= 
{
	[38004812] = { strTitle = "#{TLZL_190802_123}", 	nGetItemID = 38004834, },
	[38006610] = { strTitle = "#{TLZL_231107_43}", 		nGetItemID = 38006607, },
	[38006611] = { strTitle = "#{TLZL_231107_48}", 		nGetItemID = 38006609, },
}

--=========================================================
-- PreLoad
--=========================================================
function Fuli_ZhanLing_DiscountBuy_PreLoad()
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
function Fuli_ZhanLing_DiscountBuy_OnLoad()
	g_Fuli_ZhanLing_DiscountBuy_Frame_UnifiedPosition = Fuli_ZhanLing_DiscountBuy_Frame : GetProperty("UnifiedPosition")

	-- Fuli_ZhanLing_DiscountBuy_OK_Button : SetEvent("Clicked", "Fuli_ZhanLing_DiscountBuy_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function Fuli_ZhanLing_DiscountBuy_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nMainUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				Fuli_ZhanLing_DiscountBuy_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Fuli_ZhanLing_DiscountBuy_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_Fuli_ZhanLing_DiscountBuy()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	Fuli_ZhanLing_DiscountBuy_OnClose()
			-- end
			Fuli_ZhanLing_DiscountBuy_Reset()
			Fuli_ZhanLing_DiscountBuy_Frame_On_ResetPos()
			this:Show()
			Fuli_ZhanLing_DiscountBuy_ParamInit()
			Fuli_ZhanLing_DiscountBuy_MoneyUpdate()
			Fuli_ZhanLing_DiscountBuy_YuanBaoUpdate()
			Fuli_ZhanLing_DiscountBuy_Update(1)
		
		end

		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Fuli_ZhanLing_DiscountBuy_OnClose()
					end
				end
			end
			if this:IsVisible() then
				Fuli_ZhanLing_DiscountBuy_ParamInit()
				Fuli_ZhanLing_DiscountBuy_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("Fuli_ZhanLing_DiscountBuy_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		end

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			Fuli_ZhanLing_DiscountBuy_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			Fuli_ZhanLing_DiscountBuy_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		Fuli_ZhanLing_DiscountBuy_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		Fuli_ZhanLing_DiscountBuy_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Fuli_ZhanLing_DiscountBuy_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		Fuli_ZhanLing_DiscountBuy_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Fuli_ZhanLing_DiscountBuy_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Fuli_ZhanLing_DiscountBuy_ParamInit()

	g_nUsedItemBagIndex = Get_XParam_INT(1)
	g_nOriginalYuanBao 	= Get_XParam_INT(2)
	g_nDisCountRate 	= Get_XParam_INT(3)
	g_nLifeYear 		= Get_XParam_INT(4)
	g_nLifeMonth 		= Get_XParam_INT(5)
	g_nLifeDaysofMonth 	= Get_XParam_INT(6)
	
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function Fuli_ZhanLing_DiscountBuy_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuy" )
			Set_XSCRIPT_ScriptID(790035)
			Set_XSCRIPT_Parameter(0, g_nUsedItemBagIndex)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =Fuli_ZhanLing_DiscountBuy
function Fuli_ZhanLing_DiscountBuy_Update(bOpen)
	
	local nUseItemTableId = PlayerPackage:GetItemTableIndex(g_nUsedItemBagIndex)
	local tSubInfo = g_tShowInfo[nUseItemTableId]
	if nil ~= tSubInfo then

		-- 设置标题
		Fuli_ZhanLing_DiscountBuy_DragTitle : SetText(tSubInfo.strTitle)

		-- 设置ActionButton
		local theAction = DataPool:CreateActionItemForShow(tSubInfo.nGetItemID, 1)
		if 0 ~= theAction:GetID() then
			Fuli_ZhanLing_DiscountBuy_Page_Lace1Item : SetActionItem(theAction:GetID())
		end
	end
	
	-- 原始价格
	Fuli_ZhanLing_DiscountBuy_Original 	: SetText(ScriptGlobal_Format("#{TLZL_190802_126}", g_nOriginalYuanBao))

	-- 折扣价格
	local nCurYB = math.ceil(g_nOriginalYuanBao * g_nDisCountRate / 100)

	-- PushDebugMessage("g_nOriginalYuanBao"..g_nOriginalYuanBao.."nCurYB"..nCurYB.."g_nDisCountRate"..g_nDisCountRate)

	Fuli_ZhanLing_DiscountBuy_Current 	: SetText(ScriptGlobal_Format("#{TLZL_190802_127}", nCurYB))

	-- 有效期说明
	Fuli_ZhanLing_DiscountBuy_ItemTips 	: SetText(ScriptGlobal_Format("#{TLZL_190802_125}", g_nLifeYear, g_nLifeMonth, g_nLifeDaysofMonth))

	-- 背包格子蒙红锁定
	LifeAbility : Lock_Packet_Item( g_nUsedItemBagIndex, 1 )



end

--=========================================================
-- 重置界面
--=========================================================
function Fuli_ZhanLing_DiscountBuy_Reset()

	-- 解除背包格子蒙红锁定
	if g_nUsedItemBagIndex >= 0 then
		LifeAbility : Lock_Packet_Item( g_nUsedItemBagIndex, 0 )
	end
	
	g_nUsedItemBagIndex = -1
	g_nOriginalYuanBao 	= -1
	g_nDisCountRate 	= -1
	g_nLifeYear 		= -1
	g_nLifeMonth 		= -1
	g_nLifeDaysofMonth 	= -1
end

--=========================================================
-- 界面确认按钮
--=========================================================
function Fuli_ZhanLing_DiscountBuy_OK_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnBuy" )
		Set_XSCRIPT_ScriptID(790035)
		Set_XSCRIPT_Parameter(0, g_nUsedItemBagIndex)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function Fuli_ZhanLing_DiscountBuy_OnClose()	
	this:Hide()
	StopCareObject_Fuli_ZhanLing_DiscountBuy()
	-- 重置
	Fuli_ZhanLing_DiscountBuy_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function Fuli_ZhanLing_DiscountBuy_OnHiden()
	StopCareObject_Fuli_ZhanLing_DiscountBuy()
	-- 重置
	Fuli_ZhanLing_DiscountBuy_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_Fuli_ZhanLing_DiscountBuy()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "Fuli_ZhanLing_DiscountBuy")
end

function StopCareObject_Fuli_ZhanLing_DiscountBuy()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "Fuli_ZhanLing_DiscountBuy")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function Fuli_ZhanLing_DiscountBuy_MoneyUpdate()
	-- Fuli_ZhanLing_DiscountBuy_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- Fuli_ZhanLing_DiscountBuy_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function Fuli_ZhanLing_DiscountBuy_YuanBaoUpdate()
	-- Fuli_ZhanLing_DiscountBuy_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function Fuli_ZhanLing_DiscountBuy_Frame_On_ResetPos()
	Fuli_ZhanLing_DiscountBuy_Frame:SetProperty("UnifiedPosition", g_Fuli_ZhanLing_DiscountBuy_Frame_UnifiedPosition)
end