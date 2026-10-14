-- 神器升级界面
-- Author: lishilong 2016-6-1
--=========================================================
--常量定义
--=========================================================
local g_nObjCaredID 		= -1
local ObjCaredID = -1
local g_nItemPos 			= -1
local g_bIsReset 			= 1
local g_nAcceptClickedNum 	= 0
local g_bInputed			= 0
local g_ShenqiSJ_Frame_UnifiedPosition

local MAX_OBJ_DISTANCE 		= 3.0
local EQUIP_SHENQI_BEGIN = 10300000
local EQUIP_SHENQI_END = 10399999
local g_DesLevelTable = {
							[1] = 42,
							[2] = 52,
							[3] = 62,
							[4] = 72,
							[5] = 82,
							[6] = 92,
						}

function ShenqiSJ_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "OBJECT_CARED_EVENT" )
	this : RegisterEvent( "PACKAGE_ITEM_CHANGED" )
	this : RegisterEvent( "MONEY_CHANGE_EX" )
	this : RegisterEvent( "MONEYJZ_CHANGE_EX" )
	this : RegisterEvent( "UPDATE_SHENQI_LEVEL_UP" )
	this : RegisterEvent( "SUPER_ATTR_RECOIN_CONFIRM_OK" )
	this : RegisterEvent("ADJEST_UI_POS")
	this : RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

function ShenqiSJ_OnLoad()
	g_ShenqiSJ_Frame_UnifiedPosition = ShenqiSJ_Frame:GetProperty("UnifiedPosition")
	ShenqiSJ_Reset()
end

--=========================================================
--事件响应
--=========================================================
function ShenqiSJ_OnEvent( event )

	if event == "UI_COMMAND" and tonumber(arg0) == 920160815 then
		local bIsOpen = Get_XParam_INT(0)
		local targetId = Get_XParam_INT(1)
		
		if 0 == bIsOpen then
			-- 关闭界面
			ShenqiSJ_Close()
			return
		end
		
		ObjCaredID = DataPool : GetNPCIDByServerID( targetId )
		if ObjCaredID == -1 then
			--PushDebugMessage("server传过来的数据有问题。")
			return
		end
		g_nObjCaredID = targetId
		BeginCareObject_ShenqiSJ()
		ShenqiSJ_Reset()
		ShenqiSJ_MoneyUpdate()
		this : Show()

	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ShenqiSJ_MoneyUpdate()

	elseif event == "OBJECT_CARED_EVENT" then
		if( tonumber(arg0) ~= ObjCaredID ) then
			return
		end
		if( arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1=="destroy" ) then
			ShenqiSJ_Close()
		end

	elseif event == "PACKAGE_ITEM_CHANGED" then
		if( arg0~= nil and -1 == tonumber(arg0)) then
			return
		end

		if tonumber(arg0) == g_nItemPos then
			if( this:IsVisible() ) then
				ShenqiSJ_Reset()
			end
		end
	
	-- 右键物品或者拖拽的消息
	elseif event == "UPDATE_SHENQI_LEVEL_UP" then
		if arg0 ~= nil then
			ShenqiSJ_Reset()
			ShenqiSJ_Update( arg0 )
		end

	-- 二次确认框确认 86级神器二次确认框
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2016092992 then
		g_nAcceptClickedNum = 1
		ShenqiSJ_Buttons_Clicked()
	
	-- 二次确认框确认 42级神器带刻铭二次确认框
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2016092993 then
		g_nAcceptClickedNum = 1
		ShenqiSJ_Buttons_Clicked()
	
	elseif (event == "ADJEST_UI_POS" ) then
		ShenqiSJ_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ShenqiSJ_Frame_On_ResetPos()
		
	end

end

--=========================================================
--确定按钮
--=========================================================
function ShenqiSJ_Buttons_Clicked()
	
	--判断电话密保和二级密码保护
	--if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then
	--	return
	--end
	
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{XSQSJ_160812_18}")
		return
	end
	
	-- 判断是否已经放入了神器
	if -1 == g_nItemPos then
		PushDebugMessage("#{XSQSJ_160812_27}")
		return
	end
	
	-- 判断物品是否加锁
	--if 1 == PlayerPackage : IsLock( g_nItemPos ) then
	--	PushDebugMessage("#{XSQSJ_160812_07}")
	--	return
	--end
	
	local nItemID = PlayerPackage : GetItemTableIndex( g_nItemPos )
	--	判断是否是神器
	if nItemID < EQUIP_SHENQI_BEGIN or nItemID > EQUIP_SHENQI_END then
		PushDebugMessage("#{XSQSJ_160812_08}")
		return
	end
	
	local strContext, nIndex = ShenqiSJ_Level:GetCurrentSelect()
	if nIndex < 0 then
		PushDebugMessage("非法目标等级选择")
		return
	end 
	
	local nDesLevel = tonumber(strContext)
	if -1 == nDesLevel then
		PushDebugMessage("非法目标等级选择")
		return
	end
	
	-- 判断神器是否小于92级
	local nEquipLevel = tonumber(LifeAbility : Get_Equip_Level(g_nItemPos))
	if nEquipLevel >= 92 then
		PushDebugMessage("#{XSQSJ_160812_09}")
		return
	end
	
	-- 判断旧神器是否在神器升级表里
	local bRet, nShenqiLevel, nCostMoney, nCostItemID, nCostItemNum = ShenqiUpgrade : GetShenqiLevelUpInfo(nItemID, nDesLevel)
	if 0 == bRet or nil == bRet then
		PushDebugMessage("神器升级数据错误，无此升级信息")
		return
	end
	
	-- 神器等级配置错误
	if nEquipLevel ~= nShenqiLevel then
		PushDebugMessage("神器升级数据错误，神器等级不一致")
		return
	end
	
	-- 现有神器等级大于等于目标神器等级，策划配表错误
	if nShenqiLevel >= nDesLevel then
		PushDebugMessage("神器升级数据错误，目标等级小于源等级")
		return
	end
	
	-- 判断神器是否通灵
	-- 关于通灵，通灵前神器品质为5或者6对应5、6星（未炼魂5星，炼魂6星），通灵后为7星0阶 品质变为70开始
	--local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(g_nItemPos))
	--if nByQual > 6 then
	--	PushDebugMessage("#{XSQSJ_160812_19}")
	--	return
	--end
	
	-- 判断对应的神符是否够
	local nHaveNum = PlayerPackage:CountAvailableItemByIDTable(nCostItemID)
	if nHaveNum < nCostItemNum then
		local strItemName = PlayerPackage:GetItemName(nCostItemID)
		local strMsg = ScriptGlobal_Format("#{XSQSJ_160812_20}", strItemName)
		PushDebugMessage(strMsg)
		return
	end
	
	-- 判断钱是否够用
	local nHaveMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if nCostMoney > nHaveMoney then
		PushDebugMessage("#{XSQSJ_160812_21}")
		return
	end
	
	-- 调用服务器脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnShenqiLevelUp" )
		Set_XSCRIPT_ScriptID( 500506 )
		Set_XSCRIPT_Parameter( 0, g_nItemPos )
		Set_XSCRIPT_Parameter( 1, nDesLevel )
		Set_XSCRIPT_Parameter( 2, g_nAcceptClickedNum )
		Set_XSCRIPT_ParamCount( 3 )
	Send_XSCRIPT()
end

--=========================================================
--选择目标神器等级
--=========================================================
function ShenqiSJ_SelectLevel()
	if 0 == g_bInputed then
		--PushDebugMessage("#{XSQSJ_160812_19}")
		return
	end
	ShenqiSJ_Update( g_nItemPos )
end

--=========================================================
--选择目标神器等级
--=========================================================
function ShenqiSJ_SelectLevelClick()
	if 0 == g_bInputed then
		PushDebugMessage("#{XSQSJ_160812_19}")
		return
	end
end

--=========================================================
--更新界面
--=========================================================
function ShenqiSJ_Update( nPacketPos )

	local nBagIndex = tonumber( nPacketPos )
	
	if -1 == nBagIndex then
		return
	end
	
	local theAction = EnumAction( nBagIndex, "packageitem" )

	if 0 == theAction : GetID() then
		return
	end
	
	-- 获取物品ID
	local nItemID = PlayerPackage : GetItemTableIndex( nBagIndex )
	if nItemID <= 0 then
		PushDebugMessage("非法操作")
		return
	end
	
	-- 判断物品是否加锁
	--if 1 == PlayerPackage : IsLock( nBagIndex ) then
	--	PushDebugMessage("#{XSQSJ_160812_07}")
	--	return
	--end
	
	--	判断是否是神器
	if nItemID < EQUIP_SHENQI_BEGIN or nItemID > EQUIP_SHENQI_END then
		PushDebugMessage("#{XSQSJ_160812_08}")
		return
	end
	
	-- 判断神器是否通灵
	-- 关于通灵，通灵前神器品质为5或者6对应5、6星（未炼魂5星，炼魂6星），通灵后为7星0阶 品质变为70开始
	--local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nBagIndex))
	--if nByQual > 6 then
		--PushDebugMessage("#{XSQSJ_160812_19}")
		--return
	--end
	
	-- 判断神器是否小于92级
	local nEquipLevel = tonumber(LifeAbility : Get_Equip_Level(nBagIndex))
	if nEquipLevel >= 92 then
		PushDebugMessage("#{XSQSJ_160812_09}")
		return
	end
	
	-- 填充目标level下拉框
	if 1 == g_bIsReset then
		ShenqiSJ_Level:ResetList()
		
		if 86 == nEquipLevel then
			-- 86级神器只能升级成为96级
			ShenqiSJ_Level:AddTextItem(96, 0)
			ShenqiSJ_Level:SetCurrentSelect(0)
		else
			local nCount = 0 
			for i = 1, table.getn( g_DesLevelTable ) do
				if g_DesLevelTable[i] > nEquipLevel then
					ShenqiSJ_Level:AddTextItem(g_DesLevelTable[i], nCount)
					nCount = nCount + 1 
				end
			end
			if nCount > 0 then
				ShenqiSJ_Level:SetCurrentSelect(0)
			end
		end
			
		g_bIsReset = 0
	end
	
	local strContext, nIndex = ShenqiSJ_Level:GetCurrentSelect()
	if nIndex < 0 then
		return
	end
	local nDesLevel = tonumber(strContext)
	if -1 == nDesLevel then
		return
	end
	
	-- 判断旧神器是否在神器升级表里
	local bRet, nShenqiLevel, nCostMoney, nCostItemID, nCostItemNum = ShenqiUpgrade : GetShenqiLevelUpInfo(nItemID, nDesLevel)
	if 0 == bRet or nil == bRet then
		ShenqiSJ_Reset()
		PushDebugMessage("神器升级数据错误，无此升级信息")
		return
	end
	
	-- 神器等级配置错误
	if nEquipLevel ~= nShenqiLevel then
		ShenqiSJ_Reset()
		PushDebugMessage("神器升级数据错误，神器等级不一致")
		return
	end
	
	-- 现有神器等级大于等于目标神器等级，策划配表错误
	if nShenqiLevel >= nDesLevel then
		ShenqiSJ_Reset()
		PushDebugMessage("神器升级数据错误，目标等级小于源等级")
		return
	end

	-- 更换ActionButton锁定的背包格
	if g_nItemPos ~= -1 then
		LifeAbility : Lock_Packet_Item( g_nItemPos, 0 )
	end
	LifeAbility : Lock_Packet_Item( nBagIndex, 1 )
	g_nItemPos = nBagIndex
	
	-- 设置图标
	ShenqiSJ_Wuqi_Button : SetActionItem( theAction : GetID() )
	
	-- 设置需要的金钱
	ShenqiSJ_Spend_DemandMoney : SetProperty( "MoneyNumber", tostring( nCostMoney ) )
	
	-- 设置需要的物品
	--local strItemName = PlayerPackage:GetItemName(nCostItemID)
	--local strMsg = ScriptGlobal_Format("#{XSQSJ_160812_15}", strItemName, nCostItemNum)
	--ShenqiSJ_MaterialNeed:SetText(strMsg)
	
	-- 设置拥有的物品
	-- 未锁定物品的数量
	--local nHaveNum = PlayerPackage:CountAvailableItemByIDTable(nCostItemID)
	--if nHaveNum < nCostItemNum then
	--	strMsg = ScriptGlobal_Format("#{XSQSJ_160812_14}", strItemName, nHaveNum)
	--else
	--	strMsg = ScriptGlobal_Format("#{XSQSJ_160812_15}", strItemName, nHaveNum)
	--end
	--ShenqiSJ_Material:SetText(strMsg)
	
	-- 设置需要材料的actionbutton
	local theAction = DataPool:CreateActionItemForShow(nCostItemID, 1)
	if nil ~= theAction and nil ~= theAction:GetID() and 0 ~= theAction:GetID() then
		ShenqiSJ_Shenfu_Button:SetActionItem(theAction:GetID())
	end
	
	-- 设置拥有材料数量
	local nHaveNum = PlayerPackage:CountAvailableItemByIDTable(nCostItemID)
	if nil ~= nHaveNum then
		strMsg = ScriptGlobal_Format("#{XSQSJ_160812_38}", nHaveNum)
		ShenqiSJ_Shenfu_Num:SetText(strMsg)
	end

	-- 设置需要材料的数量
	if nil ~= nCostItemNum then
		ShenqiSJ_ShenfuNeed_Num:SetText(tostring( nCostItemNum ))
	end
	
	-- 设置确定次数
	g_nAcceptClickedNum = 0

	-- 取消置灰
	ShenqiSJ_OK:Enable()
	--ShenqiSJ_Level:Enable()
	g_bInputed = 1
end

--=========================================================
--重置界面
--=========================================================
function ShenqiSJ_Reset()
	g_nAcceptClickedNum =0
	g_bIsReset = 1
	
	ShenqiSJ_Level:ResetList()
	ShenqiSJ_Level:AddTextItem("", 0)
	ShenqiSJ_Level:SetCurrentSelect(0)
	--ShenqiSJ_Level:Disable()
	g_bInputed = 0
	
	-- 旧设计去除 材料
	--ShenqiSJ_MaterialNeed:SetText("")
	--ShenqiSJ_Material:SetText("")
	
	-- 所需金钱清0
	ShenqiSJ_Spend_DemandMoney : SetProperty( "MoneyNumber", tostring( 0 ) )
	
	-- 需要材料的图标和拥有、需求数量清空
	ShenqiSJ_Shenfu_Button : SetActionItem(-1)
	ShenqiSJ_Shenfu_Num : SetText("")
	ShenqiSJ_ShenfuNeed_Num : SetText("")
	
	ShenqiSJ_OK:Disable()
	
	if -1 ~= g_nItemPos then
		ShenqiSJ_Wuqi_Button:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(g_nItemPos, 0)
		g_nItemPos = -1
	end
end

--=========================================================
--关闭
--=========================================================
function ShenqiSJ_Close()
	this : Hide()
	StopCareObject_ShenqiSJ()
	ShenqiSJ_Reset()
end

--=========================================================
--界面隐藏
--=========================================================
function ShenqiSJ_OnHiden()
	StopCareObject_ShenqiSJ()
	ShenqiSJ_Reset()
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_ShenqiSJ()
	this : CareObject( ObjCaredID, 1, "ShenqiSJ" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_ShenqiSJ()
	this : CareObject( ObjCaredID, 0, "ShenqiSJ" )
end

--右键点击取消
function ShenqiSJ_Item_cancel()
	if( this:IsVisible() ) then
		ShenqiSJ_Reset()
	end
end

function ShenqiSJ_MoneyUpdate()
		ShenqiSJ_SelfMoney : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
		ShenqiSJ_SelfJiaozi : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
end

function ShenqiSJ_Frame_On_ResetPos()
  ShenqiSJ_Frame:SetProperty("UnifiedPosition", g_ShenqiSJ_Frame_UnifiedPosition)
end
