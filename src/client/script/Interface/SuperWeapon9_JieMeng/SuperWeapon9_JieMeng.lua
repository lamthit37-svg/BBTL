-- 开蒙神器解蒙界面 2017-11-17 lishilong
--
local MAX_OBJ_DISTANCE = 3.0
local g_objCared = -1
local g_npcObjId = -1
local g_SuperWeapon9_JieMengFrame_UnifiedPosition
local g_nCostMoney = 100*100*100

-- ==============================
-- 放入物品的位置
local g_nItemPos 			= -1
local g_bConfirm			= 0

--=========================================================
-- PreLoad
--=========================================================
function SuperWeapon9_JieMeng_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	
	this:RegisterEvent("SUPERWEAPON9_JM_INPUT", false)
	
	this:RegisterEvent("SUPERWEAPON9_JM_DRAGEND_OUT", false)	-- 挪出
	this:RegisterEvent("SUPERWEAPON9_JM_CONFIRM_RET", false)	-- 二次确认
	
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function SuperWeapon9_JieMeng_OnLoad()
	g_SuperWeapon9_JieMengFrame_UnifiedPosition = SuperWeapon9_JieMeng_Frame:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function SuperWeapon9_JieMeng_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 920171116 ) then
		-- 0 关闭，1打开， 2刷新
		local nOpType 	= Get_XParam_INT(0)
		local objid 	= Get_XParam_INT(1)
		
		if objid == nil or objid < 0 or 0 == nOpType then
			-- 关闭界面
			if this:IsVisible() then
				SuperWeapon9_JieMeng_Close()
			end
			
		elseif 1 == nOpType then
			-- 打开界面
			-- 关注npc
			g_npcObjId = objid
			g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
			BeginCareObject_SuperWeapon9_JieMeng()
			-- 显示界面
			SuperWeapon9_JieMeng_Reset()
			SuperWeapon9_JieMeng_MoneyUpdate()
			this:Show()
			
		elseif 2 == nOpType then
			-- 放入物品刷新界面
			if this:IsVisible() then
				SuperWeapon9_JieMeng_Reset()
				local nItemPos 	= Get_XParam_INT(2)
				local nNum1 	= Get_XParam_INT(3)
				local nNum2 	= Get_XParam_INT(4)
				local nNum3 	= Get_XParam_INT(5)
				local nNum4 	= Get_XParam_INT(6)
				SuperWeapon9_JieMeng_Update(nItemPos, nNum1, nNum2, nNum3, nNum4)
			end
		end
	
	-- 右键物品或者拖拽的消息
	elseif event == "SUPERWEAPON9_JM_INPUT" then
		if arg0 ~= nil then
			--SuperWeapon9_JieMeng_Reset()
			SuperWeapon9_JieMeng_OnInputItem( arg0 )
		end
	
	-- 二次确认
	elseif event == "SUPERWEAPON9_JM_CONFIRM_RET" then
		g_bConfirm = 1
		
	-- 放入物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		if( arg0~= nil and -1 == tonumber(arg0)) then
			return
		end

		if tonumber(arg0) == g_nItemPos then
			if( this:IsVisible() ) then
				SuperWeapon9_JieMeng_Reset()
			end
		end
		
	elseif event =="SUPERWEAPON9_JM_DRAGEND_OUT" and this:IsVisible() then
		--PushDebugMessage("SUPERWEAPON9_JM_DRAGEND_OUT")
		if arg0 ~= nil and 22 == tonumber(arg0) then
			SuperWeapon9_JieMeng_Reset()
		end
	
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			SuperWeapon9_JieMeng_Close()
		end	
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		SuperWeapon9_JieMeng_Close()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		SuperWeapon9_JieMeng_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		SuperWeapon9_JieMengFrame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SuperWeapon9_JieMengFrame_On_ResetPos()
	end
end

--=========================================================
-- 放入物品事件
--=========================================================
function SuperWeapon9_JieMeng_OnInputItem(nItemPos)	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnInPutItem" )
		Set_XSCRIPT_ScriptID(892629)
		Set_XSCRIPT_Parameter(0, tonumber(g_npcObjId))			-- targetId
		Set_XSCRIPT_Parameter(1, tonumber(nItemPos))			-- 道具背包位置
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--=========================================================
-- 界面更新：放入物品时更新
--=========================================================
function SuperWeapon9_JieMeng_Update(nItemPos, nNum1, nNum2, nNum3, nNum4)
	if nil == nNum1 or nil == nNum2 or nil == nNum3 or nil == nNum4 then
		return
	end
	
	if nNum1 < 0 then
		nNum1 = 0 
	end
	if nNum2 < 0 then
		nNum2 = 0 
	end
	if nNum3 < 0 then
		nNum3 = 0 
	end
	if nNum4 < 0 then
		nNum4 = 0 
	end
	
	if nNum1 > 9999 then
		nNum1 = 9999 
	end
	if nNum2 > 9999 then
		nNum2 = 9999 
	end
	if nNum3 > 9999 then
		nNum3 = 9999 
	end
	if nNum4 > 9999 then
		nNum4 = 9999 
	end

	-- Action道具操作
	local nBagIndex = tonumber( nItemPos )
	
	if -1 == nBagIndex then
		return
	end
	
	local theAction = EnumAction( nBagIndex, "packageitem" )

	if 0 == theAction : GetID() then
		return
	end
	
	-- 更换ActionButton锁定的背包格
	if g_nItemPos ~= -1 then
		LifeAbility : Lock_Packet_Item( g_nItemPos, 0 )
	end
	LifeAbility : Lock_Packet_Item( nBagIndex, 1 )
	g_nItemPos = nBagIndex
	
	-- 设置图标
	SuperWeapon9_JieMeng_Object : SetActionItem( theAction : GetID() )
	
	-- 拥有金钱显示
	SuperWeapon9_JieMeng_MoneyUpdate()
	
	-- 所需金钱显示
	SuperWeapon9_JieMeng_DemandMoney : SetProperty( "MoneyNumber", tostring( g_nCostMoney ) )
	
	-- 返还材料显示
	SuperWeapon9_JieMeng_Info3_Num : SetText(tostring(nNum1))
	SuperWeapon9_JieMeng_Info4_Num : SetText(tostring(nNum2))
	SuperWeapon9_JieMeng_Info5_Num : SetText(tostring(nNum3))
	SuperWeapon9_JieMeng_Info6_Num : SetText(tostring(nNum4))
	
	-- 激活确定按钮
	SuperWeapon9_JieMeng_OK:Enable()
	
end

--=========================================================
-- 具体的执行解蒙操作
--=========================================================
function SuperWeapon9_JieMeng_Do()

	-- 解蒙操作
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "On9StarSuperWeaponDown" )
		Set_XSCRIPT_ScriptID(892629)
		Set_XSCRIPT_Parameter(0, tonumber(g_nItemPos))			--道具背包位置
		Set_XSCRIPT_Parameter(1, g_bConfirm)					--是否确认
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

--=========================================================
--重置界面
--=========================================================
function SuperWeapon9_JieMeng_Reset()

	-- 所需金钱清0
	SuperWeapon9_JieMeng_DemandMoney : SetProperty( "MoneyNumber", tostring( 0 ) )
	
	-- Actionbutton清空
	SuperWeapon9_JieMeng_Object : SetActionItem(-1)
	-- 提示清空
	SuperWeapon9_JieMeng_Info3_Num : SetText("")
	SuperWeapon9_JieMeng_Info4_Num : SetText("")
	SuperWeapon9_JieMeng_Info5_Num : SetText("")
	SuperWeapon9_JieMeng_Info6_Num : SetText("")
	
	--SuperWeapon9_JieMeng_OK:Disable()
	
	if -1 ~= g_nItemPos then
		LifeAbility:Lock_Packet_Item(g_nItemPos, 0)
		g_nItemPos = -1
	end
	
	g_bConfirm = 0
end

--=========================================================
--右键点击取消
--=========================================================
function SuperWeapon9_JieMeng_Item_cancel()
	if( this:IsVisible() ) then
		SuperWeapon9_JieMeng_Reset()
	end
end

--=========================================================
-- 关闭界面
--=========================================================
function SuperWeapon9_JieMeng_Close()	
	this:Hide()
	StopCareObject_SuperWeapon9_JieMeng()
	-- 重置
	SuperWeapon9_JieMeng_Reset()
end

--=========================================================
--界面隐藏
--=========================================================
function SuperWeapon9_JieMeng_OnHiden()
	StopCareObject_SuperWeapon9_JieMeng()
	-- 重置
	SuperWeapon9_JieMeng_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_SuperWeapon9_JieMeng()
	-- 关心
	this:CareObject(g_objCared, 1, "SuperWeapon9_JieMeng")
end

function StopCareObject_SuperWeapon9_JieMeng()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "SuperWeapon9_JieMeng")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function SuperWeapon9_JieMeng_MoneyUpdate()
	SuperWeapon9_JieMeng_SelfJiaozi : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	SuperWeapon9_JieMeng_SelfMoney : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 按钮事件
--=========================================================

function SuperWeapon9_JieMeng_OKEvent()
	SuperWeapon9_JieMeng_Do()
end

function SuperWeapon9_JieMeng_CancleEvent()
	SuperWeapon9_JieMeng_Close()
end

--=========================================================
-- 界面位置
--=========================================================
function SuperWeapon9_JieMengFrame_On_ResetPos()
  SuperWeapon9_JieMeng_Frame:SetProperty("UnifiedPosition", g_SuperWeapon9_JieMengFrame_UnifiedPosition)
end