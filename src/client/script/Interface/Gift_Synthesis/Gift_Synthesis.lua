-- Gift_Synthesis 礼物合成 2023-8-2 lishilong
-- !!!reloadscript =Gift_Synthesis
--

local g_Gift_Synthesis_Frame_UnifiedPosition
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

local g_nUICommandID		= 79006002
local g_nMaxInputNum		= 250

-- ?	良品礼物：猴儿酿（38004167），佛跳墙（38004166），金丝冠（38004165）
-- ?	精品礼物：宝斋刻刀（38004164），竹蜻蜓（38004163），妙法拂尘（38004162）
-- ?	珍品礼物：竹雅香炉（38004619），青瓷梅子盏（38004618），太湖银鱼（38004161），大红袍（38004160），多宝塔碑帖（38004159），焦尾琴（38004158），冰素针（38004157），山水图（38004156），十样花罗（38004155），上等马驹（38004154），天青汝窑瓷（38004153），菩提木佛珠（38004152）
-- ?	神品礼物：朱砂印泥（38004617），酸角糕（38004616），澄心纸（38004615），湖州笔（38004150），玄铁矿石（38004149），青玉佩（38004148），剑谱（38004147），徐夫人匕（38004146），胭脂盒（38004145），满日弓（38004144），琴箫曲谱（38004143），义山诗集（38004142），桃花泉奕谱（38004141），女儿红（38004140）

-- 礼物信息
local g_tGiftReuseInfo		=
{
	[1] = { strKindName = "#{LWHS_230525_55}", tCostItemID = { 38004167, 38004166, 38004165, }, }, 
	[2] = { strKindName = "#{LWHS_230525_56}", tCostItemID = { 38004164, 38004163, 38004162, }, }, 
	[3] = { strKindName = "#{LWHS_230525_57}", tCostItemID = { 38004619, 38004618, 38004161, 38004160, 38004159, 38004158, 38004157, 38004156, 38004155, 38004154, 38004153, 38004152, }, }, 
	[4] = { strKindName = "#{LWHS_230525_58}", tCostItemID = { 38004617, 38004616, 38004615, 38004150, 38004149, 38004148, 38004147, 38004146, 38004145, 38004144, 38004143, 38004142, 38004141, 38004140, 38004151,}, }, 
}

-- 放入物品背包位置
local g_nIndex 				= 0
local g_nCurPoint 			= 0
local g_nCanGiveItemNum 	= 0
local g_nGiveItemID 		= 0
local g_nSetCompoundNum 	= 0

--=========================================================
-- PreLoad
--=========================================================
function Gift_Synthesis_PreLoad()
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
function Gift_Synthesis_OnLoad()
	g_Gift_Synthesis_Frame_UnifiedPosition = Gift_Synthesis_Frame:GetProperty("UnifiedPosition")

	-- Gift_Synthesis_OK_Button : SetEvent("Clicked", "Gift_Synthesis_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function Gift_Synthesis_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				Gift_Synthesis_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Gift_Synthesis_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_Gift_Synthesis()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	Gift_Synthesis_OnClose()
			-- end
			Gift_Synthesis_Reset()
			Gift_Synthesis_Frame_On_ResetPos()
			-- 打开背包
			OpenWindow("Packet")
			this:Show()
			Gift_Synthesis_InsertNumBox:SetProperty("DefaultEditBox", "True")
			Gift_Synthesis_ParamInit()
			Gift_Synthesis_MoneyUpdate()
			Gift_Synthesis_YuanBaoUpdate()
			Gift_Synthesis_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Gift_Synthesis_OnClose()
					end
				end
			end
			if this:IsVisible() then

				-- 刷新这里强制清空界面
				Gift_Synthesis_Reset()

				Gift_Synthesis_ParamInit()
				Gift_Synthesis_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			-- local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- g_nComfirmParam2 = Get_XParam_INT(2)
			-- g_nComfirmParam3 = Get_XParam_INT(3)
			-- -- ["Type"] "Ok" "YesNo"
			-- MessageBoxSelf3("Gift_Synthesis_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
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
			Gift_Synthesis_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			Gift_Synthesis_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		Gift_Synthesis_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		Gift_Synthesis_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Gift_Synthesis_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		Gift_Synthesis_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Gift_Synthesis_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Gift_Synthesis_ParamInit()
	g_nIndex 			= Get_XParam_INT(2)
	g_nCurPoint 		= Get_XParam_INT(3)
	g_nCanGiveItemNum 	= Get_XParam_INT(4)
	g_nGiveItemID 		= Get_XParam_INT(5) 

	Gift_Synthesis_InsertNumBox : SetText( tostring(g_nCanGiveItemNum) )
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function Gift_Synthesis_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		
	end

	if "No" == strRet then
		
	end
end

--===============================================
-- TextChanged()
--===============================================
function Gift_Synthesis_TextChanged()

	local nCurNum = tonumber(Gift_Synthesis_InsertNumBox : GetText())

	if nil == nCurNum or nCurNum < 0 then
		g_nSetCompoundNum = 0
		-- Gift_Synthesis_InsertNumBox : SetText( tostring(1) )
		Gift_Synthesis_Update(0)
		return
	end

	if g_nSetCompoundNum == nCurNum then
		return
	end
	
	g_nSetCompoundNum = nCurNum
	Gift_Synthesis_Update(0)
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =Gift_Synthesis
function Gift_Synthesis_Update(bOpen)

	if nil == g_nIndex then
		return
	end

	local tCurInfo = g_tGiftReuseInfo[g_nIndex]

	if nil == tCurInfo then
		return
	end
		
	local strGiveItemName = PlayerPackage:GetItemName( g_nGiveItemID )

	-- 界面标题
	Gift_Synthesis_DragTitle : SetText( ScriptGlobal_Format("#{LWHS_230525_25}", strGiveItemName) )

	-- 文字说明
	Gift_Synthesis_Info : SetText( ScriptGlobal_Format("#{LWHS_230525_26}", g_nCurPoint, tCurInfo.strKindName, g_nCanGiveItemNum, strGiveItemName) )

	-- 消耗数量
	-- if g_nSetCompoundNum < 1 then
	-- 	g_nSetCompoundNum = 1
	-- end

	if g_nSetCompoundNum > g_nMaxInputNum then
		g_nSetCompoundNum = g_nMaxInputNum
	end

	if g_nSetCompoundNum > g_nCanGiveItemNum then
		g_nSetCompoundNum = g_nCanGiveItemNum
	end

	if g_nSetCompoundNum > 0 then
		Gift_Synthesis_InsertNumBox : SetText( tostring(g_nSetCompoundNum) )
	end

end

--=========================================================
-- 重置界面
--=========================================================
function Gift_Synthesis_Reset()
	g_nIndex 			= 0
	g_nCurPoint 		= 0
	g_nCanGiveItemNum 	= 0
	g_nGiveItemID 		= 0
	g_nSetCompoundNum	= 0
	g_nComfirmParam1	= 0
	g_nComfirmParam2	= 0
	g_nComfirmParam3	= 0
end

--=========================================================
-- 界面确认按钮
--=========================================================
function Gift_Synthesis_ConfirmClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCompoundGift" )
		Set_XSCRIPT_ScriptID(790060)
		Set_XSCRIPT_Parameter(0, g_nServerObjID)					
		Set_XSCRIPT_Parameter(1, g_nIndex)
		Set_XSCRIPT_Parameter(2, g_nSetCompoundNum)
		Set_XSCRIPT_Parameter(3, 0)				
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function Gift_Synthesis_OnClose()	
	this:Hide()
	StopCareObject_Gift_Synthesis()
	-- 重置
	Gift_Synthesis_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="Gift_Synthesis_OnHidden();" />
--=========================================================
function Gift_Synthesis_OnHidden()
	StopCareObject_Gift_Synthesis()
	-- 重置
	Gift_Synthesis_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_Gift_Synthesis()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "Gift_Synthesis")
end

function StopCareObject_Gift_Synthesis()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "Gift_Synthesis")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function Gift_Synthesis_MoneyUpdate()
	-- Gift_Synthesis_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- Gift_Synthesis_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function Gift_Synthesis_YuanBaoUpdate()
	-- Gift_Synthesis_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function Gift_Synthesis_Frame_On_ResetPos()
	Gift_Synthesis_Frame:SetProperty("UnifiedPosition", g_Gift_Synthesis_Frame_UnifiedPosition)
end