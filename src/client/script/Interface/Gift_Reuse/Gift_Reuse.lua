-- Gift_Reuse 礼物拆解 2023-8-2 lishilong
-- !!!reloadscript =Gift_Reuse
--

local g_Gift_Reuse_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 1
local bCaredObj 			= 1
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0
local g_nComfirmParam2		= 0
local g_nComfirmParam3		= 0

local g_nUICommandID		= 79006001

-- ?	良品礼物：猴儿酿（38004167），佛跳墙（38004166），金丝冠（38004165）
-- ?	精品礼物：宝斋刻刀（38004164），竹蜻蜓（38004163），妙法拂尘（38004162）
-- ?	珍品礼物：竹雅香炉（38004619），青瓷梅子盏（38004618），太湖银鱼（38004161），大红袍（38004160），多宝塔碑帖（38004159），焦尾琴（38004158），冰素针（38004157），山水图（38004156），十样花罗（38004155），上等马驹（38004154），天青汝窑瓷（38004153），菩提木佛珠（38004152）
-- ?	神品礼物：朱砂印泥（38004617），酸角糕（38004616），澄心纸（38004615），湖州笔（38004150），玄铁矿石（38004149），青玉佩（38004148），剑谱（38004147），徐夫人匕（38004146），胭脂盒（38004145），满日弓（38004144），琴箫曲谱（38004143），义山诗集（38004142），桃花泉奕谱（38004141），女儿红（38004140）

-- 一个礼物拆解出来的碎片数量
local g_nGiftToPieceNum		= 10

-- 礼物信息
local g_tGiftReuseInfo		=
{
	[1] = { strKindName = "#{LWHS_230525_55}", tCostItemID = { 38004167, 38004166, 38004165, }, }, 
	[2] = { strKindName = "#{LWHS_230525_56}", tCostItemID = { 38004164, 38004163, 38004162, }, }, 
	[3] = { strKindName = "#{LWHS_230525_57}", tCostItemID = { 38004619, 38004618, 38004161, 38004160, 38004159, 38004158, 38004157, 38004156, 38004155, 38004154, 38004153, 38004152, }, }, 
	[4] = { strKindName = "#{LWHS_230525_58}", tCostItemID = { 38004617, 38004616, 38004615, 38004150, 38004149, 38004148, 38004147, 38004146, 38004145, 38004144, 38004143, 38004142, 38004141, 38004140, 38004151,}, }, 
}

-- 放入物品背包位置
local g_nInputItemBagPos 	= -1
local g_strInputKindName 	= ""
local g_nSetCostNum 		= 0

--=========================================================
-- PreLoad
--=========================================================
function Gift_Reuse_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("GIFT_REUSE_DRAP_INPUT_ITEM", false)
	this:RegisterEvent("GIFT_REUSE_RCLICK_INPUT_ITEM", false)
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
function Gift_Reuse_OnLoad()
	g_Gift_Reuse_Frame_UnifiedPosition = Gift_Reuse_Frame:GetProperty("UnifiedPosition")

	-- Gift_Reuse_OK_Button : SetEvent("Clicked", "Gift_Reuse_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function Gift_Reuse_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				Gift_Reuse_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Gift_Reuse_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_Gift_Reuse()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	Gift_Reuse_OnClose()
			-- end
			Gift_Reuse_Reset()
			Gift_Reuse_Frame_On_ResetPos()
			-- 打开背包
			OpenWindow("Packet")
			this:Show()
			Gift_Reuse_ParamInit()
			Gift_Reuse_MoneyUpdate()
			Gift_Reuse_YuanBaoUpdate()
			Gift_Reuse_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Gift_Reuse_OnClose()
					end
				end
			end
			if this:IsVisible() then

				-- 刷新这里强制清空界面
				Gift_Reuse_Reset()

				Gift_Reuse_ParamInit()
				Gift_Reuse_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)

			-- PushDebugMessage(Get_XParam_STR(0))
			-- PushDebugMessage(Get_XParam_STR(1))

			g_nComfirmParam1 = Get_XParam_INT(1)
			g_nComfirmParam2 = Get_XParam_INT(2)
			g_nComfirmParam3 = Get_XParam_INT(3)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("Gift_Reuse_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
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
			Gift_Reuse_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			Gift_Reuse_Update(0)
		end

	-- 右键背包道具放入
	elseif event == "GIFT_REUSE_RCLICK_INPUT_ITEM" and this:IsVisible() then
		local nItemBagPos = tonumber(arg0)
		-- PushDebugMessage("YURE_MISSION3_RCLICK_INPUT_ITEM")
		Gift_Reuse_OnRClickBagItem(nItemBagPos)

	-- 道具拖拽放入
	elseif event == "GIFT_REUSE_DRAP_INPUT_ITEM" and this:IsVisible() then
		local nItemBagPos = tonumber(arg0)
		-- PushDebugMessage("YURE_MISSION3_DRAP_INPUT_ITEM")
		Gift_Reuse_OnDragInputItem(nItemBagPos)

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		Gift_Reuse_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		Gift_Reuse_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Gift_Reuse_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		Gift_Reuse_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Gift_Reuse_Frame_On_ResetPos()
	end
end

--=========================================================
-- 道具右键放入
--=========================================================
function Gift_Reuse_OnRClickBagItem(nItemBagPos)
	-- PushDebugMessage("Gift_Reuse_OnDragInputItem"..",nItemBagPos:"..nItemBagPos..",nDragButtonIndex:"..nDragButtonIndex)

	Gift_Reuse_OnInputItem(nItemBagPos)
end

--=========================================================
-- 道具拖拽放入
--=========================================================
function Gift_Reuse_OnDragInputItem(nItemBagPos)
	-- PushDebugMessage("Gift_Reuse_OnDragInputItem"..",nItemBagPos:"..nItemBagPos..",nDragButtonIndex:"..nDragButtonIndex)

	Gift_Reuse_OnInputItem(nItemBagPos)
end

--=========================================================
-- 道具放入处理
--=========================================================
function Gift_Reuse_OnInputItem(nItemBagPos)
	-- PushDebugMessage("Gift_Reuse_OnInputItem"..",nItemBagPos:"..nItemBagPos)

	local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )
	local bCanInputItem = 0
	for nKindIndex = 1, table.getn(g_tGiftReuseInfo) do
		local tCanInputItemID = g_tGiftReuseInfo[nKindIndex].tCostItemID
		for i = 1, table.getn(tCanInputItemID) do
			if tCanInputItemID[i] == nItemTableIndex then
				bCanInputItem = 1
				g_strInputKindName = g_tGiftReuseInfo[nKindIndex].strKindName
				break
			end
		end
	end
	
	if 1 ~= bCanInputItem then
		PushDebugMessage("#{LWHS_230525_10}")
		return
	end

	--判断 是否已加锁
	if 1 == PlayerPackage : IsLock(nItemBagPos) then
		PushDebugMessage("#{LWHS_230525_12}")
		return
	end

	if g_nInputItemBagPos >= 0 then
		LifeAbility : Lock_Packet_Item(g_nInputItemBagPos, 0)
	end

	g_nInputItemBagPos = nItemBagPos
	LifeAbility : Lock_Packet_Item(g_nInputItemBagPos, 1)

	g_nSetCostNum = PlayerPackage : GetBagItemNum(g_nInputItemBagPos)

	Gift_Reuse_Update(0)
end

--=========================================================
-- 右键界面ActionButton
--=========================================================
function Gift_Reuse_OnActionItemRClicked()
	Gift_Reuse_Reset()
	Gift_Reuse_Update(0)
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Gift_Reuse_ParamInit()
	-- g_nSetCostNum = Get_XParam_INT(2)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function Gift_Reuse_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnReuseGift" )
			Set_XSCRIPT_ScriptID(790060)
			Set_XSCRIPT_Parameter(0, g_nComfirmParam1)					
			Set_XSCRIPT_Parameter(1, g_nComfirmParam2)
			Set_XSCRIPT_Parameter(2, g_nComfirmParam3)
			Set_XSCRIPT_Parameter(3, 1)				
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		
	end
end

--===============================================
-- TextChanged()
--===============================================
function Gift_Reuse_TextChanged()

	local nCurNum = tonumber(Gift_Reuse_Input : GetText())

	if nil == nCurNum or nCurNum < 0 then
		g_nSetCostNum = 0
		-- Gift_Reuse_Input : SetText( tostring(0) )
		Gift_Reuse_Update(0)
		return
	end

	if g_nSetCostNum == nCurNum then
		return
	end
	
	g_nSetCostNum = nCurNum
	Gift_Reuse_Update(0)
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =Gift_Reuse
function Gift_Reuse_Update(bOpen)
	
	if g_nInputItemBagPos >= 0 then
		local nItemTableIndex = PlayerPackage : GetItemTableIndex( g_nInputItemBagPos )

		if nItemTableIndex <= 0 then
			Gift_Reuse_Reset()
			return
		end

		local nHaveAvailableCount = PlayerPackage:CountAvailableItemByIDTable(nItemTableIndex)
		
		local theAction = DataPool : CreateActionItemForShow(nItemTableIndex, 1)
		local strItemName = PlayerPackage:GetItemName( nItemTableIndex )

		-- ActionButton
		if nil ~= theAction and 0 ~= theAction:GetID() then
			Gift_ReuseBtn : SetActionItem(theAction:GetID())
		end

		-- 名字
		Gift_Reuse_Text2 : SetText( ScriptGlobal_Format("#{LWHS_230525_13}", strItemName) )

		-- 消耗数量
		-- if g_nSetCostNum < 1 then
		-- 	g_nSetCostNum = 1
		-- end

		if g_nSetCostNum > nHaveAvailableCount then
			g_nSetCostNum = nHaveAvailableCount
		end

		if g_nSetCostNum > 0 then
			Gift_Reuse_Input : SetText( tostring(g_nSetCostNum) )
		end
		
		local nGiveNum = g_nSetCostNum * g_nGiftToPieceNum

		-- 拆解所得信息
		Gift_Reuse_Text3 : SetText( ScriptGlobal_Format("#{LWHS_230525_15}", nGiveNum, g_strInputKindName) )
	else
		Gift_ReuseBtn : SetActionItem(-1)
		Gift_Reuse_Text2 : SetText( "" )
		Gift_Reuse_Text3 : SetText( "" )
		Gift_Reuse_Input : SetText( tostring(0) )
	end
end

--=========================================================
-- 重置界面
--=========================================================
function Gift_Reuse_Reset()
	if g_nInputItemBagPos >= 0 then
		LifeAbility : Lock_Packet_Item(g_nInputItemBagPos, 0)
	end

	g_nInputItemBagPos	= -1
	g_strInputKindName 	= ""
	g_nSetCostNum		= 0
	g_nComfirmParam1	= 0
	g_nComfirmParam2	= 0
	g_nComfirmParam3	= 0
end

--=========================================================
-- 界面确认按钮
--=========================================================
function Gift_Reuse_ConfirmClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnReuseGift" )
		Set_XSCRIPT_ScriptID(790060)
		Set_XSCRIPT_Parameter(0, g_nServerObjID)					
		Set_XSCRIPT_Parameter(1, g_nInputItemBagPos)
		Set_XSCRIPT_Parameter(2, g_nSetCostNum)
		Set_XSCRIPT_Parameter(3, 0)				
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function Gift_Reuse_OnClose()	
	this:Hide()
	StopCareObject_Gift_Reuse()
	-- 重置
	Gift_Reuse_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="Gift_Reuse_OnHidden();" />
--=========================================================
function Gift_Reuse_OnHidden()
	StopCareObject_Gift_Reuse()
	-- 重置
	Gift_Reuse_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_Gift_Reuse()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "Gift_Reuse")
end

function StopCareObject_Gift_Reuse()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "Gift_Reuse")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function Gift_Reuse_MoneyUpdate()
	-- Gift_Reuse_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- Gift_Reuse_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function Gift_Reuse_YuanBaoUpdate()
	-- Gift_Reuse_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function Gift_Reuse_Frame_On_ResetPos()
	Gift_Reuse_Frame:SetProperty("UnifiedPosition", g_Gift_Reuse_Frame_UnifiedPosition)
end