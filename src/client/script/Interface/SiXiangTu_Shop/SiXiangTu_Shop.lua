-- SiXiangTu_Shop 四象图商店 2021-5-12 lishilong
-- !!!reloadscript =SiXiangTu_Shop
--

local g_SiXiangTu_Shop_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 1
local bCaredMoney 			= 0
local bCaredYuanBao			= 0

-- UICommand_AddInt(sceneId, targetId)	
-- UICommand_AddInt(sceneId, nSelectIndex)
-- UICommand_AddInt(sceneId, nBuyNum)
local g_nComfirmParam1		= 0
local g_nComfirmParam2		= 0
local g_nComfirmParam3		= 0

local g_nUICommandID		= 79005003
local g_nMbuyUICommandID	= 79005004
local g_nHaveDaibiPoint		= 0

local g_controlActionButton = {}
local g_controlItemName 	= {}
local g_controlItemCost 	= {}
local g_nMaxItemInShop		= 15
local g_tabShopInfo = 
{
	[1] = {nItemID = 38005316, nItemNum = 1, 	nLayoutNum = 250,	nBagSpace = 1, nMatSpace = 0, nItemCost = 30, }, 
	[2] = {nItemID = 38005317, nItemNum = 1, 	nLayoutNum = 250,	nBagSpace = 1, nMatSpace = 0, nItemCost = 10, }, 
	[3] = {nItemID = 38005314, nItemNum = 1, 	nLayoutNum = 250,	nBagSpace = 1, nMatSpace = 0, nItemCost = 30, }, 
	[4] = {nItemID = 38005315, nItemNum = 1, 	nLayoutNum = 250,	nBagSpace = 1, nMatSpace = 0, nItemCost = 10, }, 
	[5] = {nItemID = 38004806, nItemNum = 10, 	nLayoutNum = 250, 	nBagSpace = 1, nMatSpace = 0, nItemCost = 25, }, 
	[6] = {nItemID = 38004734, nItemNum = 10, 	nLayoutNum = 250, 	nBagSpace = 1, nMatSpace = 0, nItemCost = 10, }, 
	[7] = {nItemID = 38004359, nItemNum = 1, 	nLayoutNum = 250,	nBagSpace = 1, nMatSpace = 0, nItemCost = 15, }, 
	[8] = {nItemID = 38004358, nItemNum = 1, 	nLayoutNum = 250,	nBagSpace = 1, nMatSpace = 0, nItemCost = 5,  }, 
}

--=========================================================
-- PreLoad
--=========================================================
function SiXiangTu_Shop_PreLoad()
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
function SiXiangTu_Shop_OnLoad()
	g_SiXiangTu_Shop_Frame_UnifiedPosition = SiXiangTu_Shop_Frame:GetProperty("UnifiedPosition")

	g_controlActionButton[1]	= SiXiangTu_Shop_Item1
	g_controlActionButton[2]	= SiXiangTu_Shop_Item2
	g_controlActionButton[3]	= SiXiangTu_Shop_Item3
	g_controlActionButton[4]	= SiXiangTu_Shop_Item4
	g_controlActionButton[5]	= SiXiangTu_Shop_Item5
	g_controlActionButton[6]	= SiXiangTu_Shop_Item6
	g_controlActionButton[7]	= SiXiangTu_Shop_Item7
	g_controlActionButton[8]	= SiXiangTu_Shop_Item8
	g_controlActionButton[9]	= SiXiangTu_Shop_Item9
	g_controlActionButton[10]	= SiXiangTu_Shop_Item10
	g_controlActionButton[11]	= SiXiangTu_Shop_Item11
	g_controlActionButton[12]	= SiXiangTu_Shop_Item12
	g_controlActionButton[13]	= SiXiangTu_Shop_Item13
	g_controlActionButton[14]	= SiXiangTu_Shop_Item14
	g_controlActionButton[15]	= SiXiangTu_Shop_Item15

	g_controlItemName[1]		= SiXiangTu_Shop_ItemInfo1_Name
	g_controlItemName[2]		= SiXiangTu_Shop_ItemInfo2_Name
	g_controlItemName[3]		= SiXiangTu_Shop_ItemInfo3_Name
	g_controlItemName[4]		= SiXiangTu_Shop_ItemInfo4_Name
	g_controlItemName[5]		= SiXiangTu_Shop_ItemInfo5_Name
	g_controlItemName[6]		= SiXiangTu_Shop_ItemInfo6_Name
	g_controlItemName[7]		= SiXiangTu_Shop_ItemInfo7_Name
	g_controlItemName[8]		= SiXiangTu_Shop_ItemInfo8_Name
	g_controlItemName[9]		= SiXiangTu_Shop_ItemInfo9_Name
	g_controlItemName[10]		= SiXiangTu_Shop_ItemInfo10_Name
	g_controlItemName[11]		= SiXiangTu_Shop_ItemInfo11_Name
	g_controlItemName[12]		= SiXiangTu_Shop_ItemInfo12_Name
	g_controlItemName[13]		= SiXiangTu_Shop_ItemInfo13_Name
	g_controlItemName[14]		= SiXiangTu_Shop_ItemInfo14_Name
	g_controlItemName[15]		= SiXiangTu_Shop_ItemInfo15_Name

	g_controlItemCost[1]		= SiXiangTu_Shop_ItemInfo1_Text
	g_controlItemCost[2]		= SiXiangTu_Shop_ItemInfo2_Text
	g_controlItemCost[3]		= SiXiangTu_Shop_ItemInfo3_Text
	g_controlItemCost[4]		= SiXiangTu_Shop_ItemInfo4_Text
	g_controlItemCost[5]		= SiXiangTu_Shop_ItemInfo5_Text
	g_controlItemCost[6]		= SiXiangTu_Shop_ItemInfo6_Text
	g_controlItemCost[7]		= SiXiangTu_Shop_ItemInfo7_Text
	g_controlItemCost[8]		= SiXiangTu_Shop_ItemInfo8_Text
	g_controlItemCost[9]		= SiXiangTu_Shop_ItemInfo9_Text
	g_controlItemCost[10]		= SiXiangTu_Shop_ItemInfo10_Text
	g_controlItemCost[11]		= SiXiangTu_Shop_ItemInfo11_Text
	g_controlItemCost[12]		= SiXiangTu_Shop_ItemInfo12_Text
	g_controlItemCost[13]		= SiXiangTu_Shop_ItemInfo13_Text
	g_controlItemCost[14]		= SiXiangTu_Shop_ItemInfo14_Text
	g_controlItemCost[15]		= SiXiangTu_Shop_ItemInfo15_Text
	-- SiXiangTu_Shop_OK_Button : SetEvent("Clicked", "SiXiangTu_Shop_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function SiXiangTu_Shop_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				SiXiangTu_Shop_CloseClicked()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SiXiangTu_Shop_CloseClicked()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_SiXiangTu_Shop()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	SiXiangTu_Shop_CloseClicked()
			-- end
			SiXiangTu_Shop_Reset()
			SiXiangTu_Shop_Frame_On_ResetPos()
			this:Show()
			SiXiangTu_Shop_ParamInit()
			SiXiangTu_Shop_MoneyUpdate()
			SiXiangTu_Shop_YuanBaoUpdate()
			SiXiangTu_Shop_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SiXiangTu_Shop_CloseClicked()
					end
				end
			end
			if this:IsVisible() then
				SiXiangTu_Shop_ParamInit()
				SiXiangTu_Shop_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- UICommand_AddInt(sceneId, targetId)	
			-- UICommand_AddInt(sceneId, nSelectIndex)
			-- UICommand_AddInt(sceneId, nBuyNum)
			g_nComfirmParam1 = Get_XParam_INT(1)
			g_nComfirmParam2 = Get_XParam_INT(2)
			g_nComfirmParam3 = Get_XParam_INT(3)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("SiXiangTu_Shop_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
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
			SiXiangTu_Shop_CloseClicked()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			SiXiangTu_Shop_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		SiXiangTu_Shop_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		SiXiangTu_Shop_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		SiXiangTu_Shop_CloseClicked()
	
	elseif (event == "ADJEST_UI_POS" ) then
		SiXiangTu_Shop_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SiXiangTu_Shop_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function SiXiangTu_Shop_ParamInit()
	g_nHaveDaibiPoint = Get_XParam_INT(2)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function SiXiangTu_Shop_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then

		-- UICommand_AddInt(sceneId, targetId)	
		-- UICommand_AddInt(sceneId, nSelectIndex)
		-- UICommand_AddInt(sceneId, nBuyNum)
		-- local g_nComfirmParam1		= 0
		-- local g_nComfirmParam2		= 0
		-- local g_nComfirmParam3		= 0

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnBuyFromShop")
			Set_XSCRIPT_ScriptID( 790050 )
			Set_XSCRIPT_Parameter(0, g_nComfirmParam1)		-- targetId
			Set_XSCRIPT_Parameter(1, 1)						-- bConfirmed
			Set_XSCRIPT_Parameter(2, g_nComfirmParam2)		-- nSelectIndex
			Set_XSCRIPT_Parameter(3, g_nComfirmParam3)		-- nBuyNum
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =SiXiangTu_Shop
function SiXiangTu_Shop_Update(bOpen)
	
	for	i = 1, g_nMaxItemInShop do
		g_controlActionButton[i] 	: SetActionItem(-1)
		g_controlItemName[i] 		: SetText("")
		g_controlItemCost[i] 		: SetText("")
	end

	for	i = 1, table.getn(g_tabShopInfo) do
		local itemInfo 	= g_tabShopInfo[i]
		local nItemID 	= itemInfo.nItemID
		local nItemNum 	= itemInfo.nItemNum
		local nItemCost	= itemInfo.nItemCost

		-- local theAction = DataPool:CreateActionItemForShow(nItemID, nItemNum)
		local theAction = DataPool:CreateBindActionItemForShow(nItemID, nItemNum)
		g_controlActionButton[i] : SetActionItem(theAction:GetID())

		local strItemName = DataPool:Lua_GetItemNameByIndex(nItemID)
		g_controlItemName[i] : SetText(ScriptGlobal_Format("#{SXTZ_210510_07}", strItemName))

		g_controlItemCost[i] : SetText(ScriptGlobal_Format("#{SXTZ_210510_08}", nItemCost))
	end

	SiXiangTu_Shop_Text1  : SetText(ScriptGlobal_Format("#{SXTZ_210510_09}", g_nHaveDaibiPoint))
end

--=========================================================
-- 点击物品
--=========================================================
function SiXiangTu_Shop_GoodButton_Clicked(nItemIndex)
	if nItemIndex <= 0 or nItemIndex > table.getn(g_tabShopInfo) then
		return
	end

	local itemInfo 	= g_tabShopInfo[nItemIndex]
	local nItemID 	= itemInfo.nItemID
	local nItemNum 	= itemInfo.nItemNum
	local nItemCost	= itemInfo.nItemCost

	-- 关闭批量购买界面
	PushEvent("UI_COMMAND", g_nMbuyUICommandID, 0 )

	if CheckBuyMult() == 1 then
		PushEvent("UI_COMMAND", g_nMbuyUICommandID, 1, g_nServerObjID, g_nHaveDaibiPoint, nItemIndex, nItemID, nItemNum, nItemCost )
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnBuyFromShop")
			Set_XSCRIPT_ScriptID( 790050 )
			Set_XSCRIPT_Parameter(0, g_nServerObjID)		-- targetId
			Set_XSCRIPT_Parameter(1, 0)						-- bConfirmed
			Set_XSCRIPT_Parameter(2, nItemIndex)			-- nSelectIndex
			Set_XSCRIPT_Parameter(3, 1)						-- nBuyNum
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end
end

--=========================================================
-- 点击批量购买
--=========================================================
function SiXiangTu_Shop_MBuy(nItemIndex)

	-- 关闭批量购买界面
	PushEvent("UI_COMMAND", g_nMbuyUICommandID, 0 )
	PrepearBuyMult()
end


--=========================================================
-- 帮助按钮
--=========================================================
function SiXiangTu_Shop_HelpClicked()
end

--=========================================================
-- 切换页面
--=========================================================
function SiXiangTu_Shop_ChangeShowTab(nPage)
end

--=========================================================
-- 翻页
--=========================================================
function SiXiangTu_Shop_PageUp()
end
function SiXiangTu_Shop_DownPage()
end

--=========================================================
-- 重置界面
--=========================================================
function SiXiangTu_Shop_Reset()
	g_nHaveDaibiPoint = 0

	-- 关闭批量购买界面
	PushEvent("UI_COMMAND", g_nMbuyUICommandID, 0 )
end

--=========================================================
-- 界面确认按钮
--=========================================================
function SiXiangTu_Shop_ConfirmClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIEvent" )
		Set_XSCRIPT_ScriptID(060225)
		Set_XSCRIPT_Parameter(0, 2)					
		Set_XSCRIPT_Parameter(1, 1)				
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function SiXiangTu_Shop_CloseClicked()	
	this:Hide()
	StopCareObject_SiXiangTu_Shop()
	-- 重置
	SiXiangTu_Shop_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="SiXiangTu_Shop_OnHidden();" />
--=========================================================
function SiXiangTu_Shop_OnHidden()
	StopCareObject_SiXiangTu_Shop()
	-- 重置
	SiXiangTu_Shop_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_SiXiangTu_Shop()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "SiXiangTu_Shop")
end

function StopCareObject_SiXiangTu_Shop()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "SiXiangTu_Shop")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function SiXiangTu_Shop_MoneyUpdate()
	-- SiXiangTu_Shop_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- SiXiangTu_Shop_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function SiXiangTu_Shop_YuanBaoUpdate()
	-- SiXiangTu_Shop_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function SiXiangTu_Shop_Frame_On_ResetPos()
	SiXiangTu_Shop_Frame:SetProperty("UnifiedPosition", g_SiXiangTu_Shop_Frame_UnifiedPosition)
end