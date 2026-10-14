-- 龙纹提升合成等级界面
-- !!!reloadscript =LongwenLevelUp

local m_UI_NUM = 20110725
local m_ObjCared = -1
local m_Equip_Idx = -1
local m_Equip_Item = -1
local m_Stuff_Item = -1
local zwTabIndex = -1 --上次升级使用的铸纹的表格ID，用于升级后找到背包中是否有同类型的铸纹，直接放进材料框中

-- 10157001 龙纹 绑定
-- 10157002 龙纹
-- !!createitemnew = 10157001 = 10
-- !!createitemnew = 10157002 = 10
-- !!createitemnew = 38002106 = 250
-- !!createitemnew = 38002107 = 250
-- !!createitemnew = 38000185 = 5
-- !!createitemnew = 38000186 = 5

local ZWTabIndexList=
{
	[38000152] = { item1 = 38000152, item2 = 38000184  },		--铸纹血玉--绑定
	[38000164] = { item1 = 38000164, item2 = 38000185  },		--铸纹精玉
	[38000165] = { item1 = 38000165, item2 = 38000186  },		--铸纹龙玉
	[38000184] = { item1 = 38000152, item2 = 38000184  },		--铸纹血玉
	[38000185] = { item1 = 38000164, item2 = 38000185  },		--铸纹精玉
	[38000186] = { item1 = 38000165, item2 = 38000186  },		--铸纹龙玉

}

local UI_TYPE_COMPOUND	= 1

local TYPE_COMPOUND		= 1
local TYPE_STARUP		= 2

local m_UIType = 0

local m_Money_COMPOUND = 10000			--合成花费固定为1J

local needMoney = 0

local m_needConfirm = 1

--龙纹提升合成等级的材料
local m_LevelupStuff = {
							[1] = { item = 38000152, num = 5  },		--铸纹血玉--绑定
							[2] = { item = 38000164, num = 10 },		--铸纹精玉
							[3] = { item = 38000165, num = 20 },		--铸纹龙玉
							[4] = { item = 38000184, num = 5  },		--铸纹血玉
							[5] = { item = 38000185, num = 10 },		--铸纹精玉
							[6] = { item = 38000186, num = 20 },		--铸纹龙玉
						}

local m_NeedConfirmLevel = 99			--等级为99级，且...
local m_MaxStuffNum = 89				--材料最大值

local m_YuLinStuff = {
	[1] = {item = 38002106,num = 1},	--绑定
	[2] = {item = 38002107,num = 1},	--不绑定
}

local m_YuLinFlag = 0

-- 是否开启自动逻辑
local m_bOpenAutoLogic 	= 0
-- 是否可以自动执行
local m_bCanAutoLogic 	= 0
-- 自动执行间隔 单位ms
local m_nTickTime 		= 200

--PreLoad
function LongwenLevelUp_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("UPDATE_LW_LEVELUP")
	this:RegisterEvent("AFTER_UPDATE_LW_LEVELUP_CONFIRM")
	this:RegisterEvent("AFTER_UPDATE_LW_BIND_CONFIRM")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
end

--OnLoad
function LongwenLevelUp_OnLoad()
end

--OnEvent
function LongwenLevelUp_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then

		--if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
		--	return
		--end

	-- 二级密码 电话密保检查
		if GetAuthorizedSafeFlag() == 0 and CheckPhoneMibaoAndMinorPassword() ~= 1 then --非授权安全模式下需要验证
			return
		end

		LongwenLevelUp_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)

		--if m_UIType == UI_TYPE_COMPOUND then
		--end

		LongwenLevelUp_Update(-1)
		LongwenLevelUp_Update_Sub(-1)
		LongwenLevelUp_Update_Stuff(-1)
		LongwenLevelUp_Item_Change(-1)
		this:Show();
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20150520 and this:IsVisible()) then

		-- 刷新类型 1 成功刷新；2失败刷新
		local nRefreshType = Get_XParam_INT(0)

		-- 失败了，如果还在自动升级，就给关了
		if 2 == nRefreshType then
			-- 关闭自动升级
			if 1 == m_bOpenAutoLogic then
				LongwenLevelUp_AutoUpClose()
			end		
			return
		end

		-- 自动填充材料逻辑
		local YuLingLW = Get_XParam_INT(1)
		local LWbagIndex = 0
		local YlbagIndex = 0
		if YuLingLW == 1 then			
			--获得绑定的合理性龙纹
			LWbagIndex =PlayerPackage:GetValidLwForLevelUp(1)
			if LWbagIndex == -1 then
			--非绑定合理性龙纹
				LWbagIndex =PlayerPackage:GetValidLwForLevelUp(0)
			end
			
			if LWbagIndex == -1 then
				LWbagIndex = PlayerPackage:GetValidZwForLevelUp(m_YuLinStuff[1].item,1)
				if LWbagIndex == -1 then
					LWbagIndex = PlayerPackage:GetValidZwForLevelUp(m_YuLinStuff[2].item,0)
				end
				if LWbagIndex ~= -1 then
					m_YuLinFlag = 1
				end
			end
			
			if LWbagIndex >= 0 then
				local theAction = EnumAction(LWbagIndex, "packageitem");
				LongwenLevelUp_Object2:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(LWbagIndex,1);
				m_Equip_Item = LWbagIndex
			end
		elseif YuLingLW == 2 then	
			if Get_XParam_INT(2) ~= -1 then
				YlbagIndex = Get_XParam_INT(2)
			else		
				YlbagIndex = PlayerPackage:GetValidZwForLevelUp(m_YuLinStuff[1].item,1)
				if YlbagIndex == -1 then
					YlbagIndex = PlayerPackage:GetValidZwForLevelUp(m_YuLinStuff[2].item,0)
				end
				
				if  YlbagIndex == -1 then
					YlbagIndex =PlayerPackage:GetValidLwForLevelUp(1)
					if YlbagIndex == -1 then
					--非绑定合理性龙纹
						YlbagIndex =PlayerPackage:GetValidLwForLevelUp(0)
					end
					if LWbagIndex ~= -1 then
						m_YuLinFlag = 0
					end
				end
			end
			if YlbagIndex >= 0 then
				local theAction = EnumAction(YlbagIndex, "packageitem");
				LongwenLevelUp_Object2:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(YlbagIndex,1);
				m_Equip_Item = YlbagIndex
			end
		end

		if LWbagIndex == -1 and YlbagIndex == -1 then
			LongwenLevelUp_Object2:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(m_Equip_Item,0);
			m_Equip_Item = -1			
		
			LongwenLevelUp_Object3:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(m_Stuff_Item,0);
			m_Stuff_Item = -1;
		else
			--获得绑定的合理性铸纹
			LongwenLevelUp_Update_Stuff(m_Stuff_Item)

			if m_Stuff_Item == -1 then

				local ZwbagIndex = -1
			--	if (ZWTabIndexList[zwTabIndex]==nil) then
			--		PushDebugMessage(zwTabIndex)
			--	end
				if (ZWTabIndexList[zwTabIndex]~=nil) then
					ZwbagIndex =PlayerPackage:GetValidZwForLevelUp(ZWTabIndexList[zwTabIndex].item1,1)
					if ZwbagIndex == -1 then
				--非绑定合理性龙纹
						ZwbagIndex =PlayerPackage:GetValidZwForLevelUp(ZWTabIndexList[zwTabIndex].item2,0)
					end
				end

				if ZwbagIndex == -1 then
			-- 铸纹消失
					LongwenLevelUp_Object3:SetActionItem(-1);
					LifeAbility : Lock_Packet_Item(m_Stuff_Item,0);
					m_Stuff_Item = -1
				elseif ZwbagIndex >= 0 then
					local theAction = EnumAction(ZwbagIndex, "packageitem");
					LongwenLevelUp_Object3:SetActionItem(theAction:GetID());
					LifeAbility : Lock_Packet_Item(ZwbagIndex,1);
					m_Stuff_Item = ZwbagIndex
				end
			end
		end
		LongwenLevelUp_UICheck()

		-- PushDebugMessage("自动填充材料逻辑")

		if 1 == m_bOpenAutoLogic and 1 == m_bCanAutoLogic then
			-- PushDebugMessage("1 == m_bOpenAutoLogic and 1 == m_bCanAutoLogic")

			-- 特殊情况处理，如果之前是用的铸纹材料，但是铸纹耗尽了，这种情况下中断自动逻辑
			if zwTabIndex > 0 and m_Stuff_Item < 0 and nil ~= ZWTabIndexList[zwTabIndex] then
				local strItemName = DataPool:Lua_GetItemNameByIndex(ZWTabIndexList[zwTabIndex].item1)
				local strMsg = ScriptGlobal_Format("#{LWDJ_170921_39}", strItemName)
				zwTabIndex = -1
				-- 关闭自动升级
				-- LongwenLevelUp_AutoUpClose()
				MessageBoxSelf3("LongwenLevelUp_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
				return 
			end

			SetTimer("LongwenLevelUp","LongwenLevelUp_OnTimer()", m_nTickTime)
			
		elseif 1 == m_bOpenAutoLogic and 0 == m_bCanAutoLogic then
			-- 关闭自动升级
			LongwenLevelUp_AutoUpClose()
			-- PushDebugMessage("m_bOpenAutoLogic"..m_bOpenAutoLogic.."m_bCanAutoLogic"..m_bCanAutoLogic)
		else
			-- PushDebugMessage("m_bOpenAutoLogic"..m_bOpenAutoLogic.."m_bCanAutoLogic"..m_bCanAutoLogic)
		end

	elseif (event == "UPDATE_LW_LEVELUP" and this:IsVisible() ) then

		if m_UIType == UI_TYPE_COMPOUND then

			if 1 ~= LongwenLevelUp_CheckCanMoveItem() then
				return
			end

			--if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
				--return
			--end
				-- 二级密码 电话密保检查
			if GetAuthorizedSafeFlag() == 0 and CheckPhoneMibaoAndMinorPassword() ~= 1 then --非授权安全模式下需要验证
				return
			end
			
			if arg1 ~= nil and tonumber(arg1) == 3 and arg0 ~= nil then

				if m_Equip_Idx ~= -1 and m_Equip_Item ~= -1 then
					LongwenLevelUp_Update_Stuff(tonumber(arg0))
				else
					--PushDebugMessage("1111111111")							--暂时不知提示什么。。
				end

			elseif arg1 ~= nil and tonumber(arg1) == 2 and arg0 ~= nil then

				if m_Equip_Idx ~= -1 then
					LongwenLevelUp_Update_Sub( tonumber(arg0) )
				else
					LongwenLevelUp_Update( tonumber(arg0) )
				end

			elseif arg1 ~= nil and tonumber(arg1) == 1 and arg0 ~= nil then
				LongwenLevelUp_Update_Sub( tonumber(arg0) )

			elseif arg1 ~= nil and tonumber(arg1) == 0 and arg0 ~= nil then
				LongwenLevelUp_Update( tonumber(arg0) )
			end
		end

	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		LongwenLevelUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		LongwenLevelUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			LongwenLevelUp_Item_Change(m_Equip_Idx)

		elseif  arg0 ~= nil and tonumber(arg0) == m_Equip_Item then
			LongwenLevelUp_Update_Sub(m_Equip_Item)

		elseif  arg0 ~= nil and tonumber(arg0) == m_Stuff_Item then
			LongwenLevelUp_Update_Stuff(m_Stuff_Item)
		end

	elseif (event == "AFTER_UPDATE_LW_BIND_CONFIRM" and this:IsVisible()) then
		LongwenLevelUp_OK_Clicked_Confirm()

	elseif (event == "AFTER_UPDATE_LW_LEVELUP_CONFIRM" and this:IsVisible()) then
		LongwenLevelUp_OK_Clicked_Continue()

	end
end

function LongwenLevelUp_OnTimer()
	LongwenLevelUp_OnLevelUpOnce()
	KillTimer("LongwenLevelUp_OnTimer()")
end

--Update UI
function LongwenLevelUp_Update(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if m_UIType == UI_TYPE_COMPOUND then

			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end

			local main_lv = PlayerPackage:GetBagLWData(itemIdx, "LEVEL")

			if  main_lv ~= nil and main_lv >= 100 then
				PushDebugMessage("#{LW_KVK_110704_08}")  --该龙纹已达到最高合成等级100级，不能继续提升。
				return
			end

			local sub_lv = PlayerPackage:GetBagLWData(m_Equip_Item, "LEVEL")
			if  main_lv ~= nil and sub_lv ~= nil and main_lv < sub_lv then
				PushDebugMessage("#{LW_KVK_110704_09}") --被提升的龙纹合成等级低于参与提升的龙纹合成等级，无法放入。
				return
			end
		end

		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end

		LongwenLevelUp_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx

	else
		LongwenLevelUp_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end
	LongwenLevelUp_UICheck();

	if 1 == m_bOpenAutoLogic then	
		LongwenLevelUp_AutoUpOpen()
	else
		LongwenLevelUp_AutoUpClose()
	end

end

function LongwenLevelUp_Update_Sub(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		local YuLinFlag = 0

		if m_UIType == UI_TYPE_COMPOUND then
			local nItemIndex = PlayerPackage:GetItemTableIndex( itemIdx )
			for nindex=1, table.getn(m_YuLinStuff) do
				if m_YuLinStuff[nindex].item == nItemIndex then
					YuLinFlag = 1
					break
				end
			end
			
			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 and YuLinFlag == 0 then
				PushDebugMessage("#{LWDJ_170921_10}")	--此处只能放入龙纹。
				return
			end

			if YuLinFlag == 0 then
				if PlayerPackage:IsLock( itemIdx ) == 1 then
					PushDebugMessage("#{LWDJ_170921_33}")	--被上锁的龙纹不能作材料龙纹。
					return
				end
			
				local gem_count = LifeAbility : GetEquip_GemCount( itemIdx )
				if gem_count ~= nil and gem_count > 0 then
					PushDebugMessage("#{LW_KVK_110704_54}")	--镶嵌有宝石的龙纹不能作为合成材料！
					return
				end

				local haveDiaowen = LifeAbility : IsEquipHaveDiaowen( itemIdx )
				if haveDiaowen > 0 then
					PushDebugMessage("#{ZBDW_091105_18}")	--有雕纹的龙纹不能作为材料龙纹!
					return
				end

				local main_lv = PlayerPackage:GetBagLWData(m_Equip_Idx  , "LEVEL")
				local sub_lv = PlayerPackage:GetBagLWData(itemIdx  , "LEVEL")
				if  main_lv ~= nil and sub_lv ~= nil and main_lv < sub_lv then
					PushDebugMessage("#{LW_KVK_110704_11}") --参与提升的龙纹合成等级高于被提升的龙纹合成等级，无法放入。
					return
				end
			end
		end

		m_YuLinFlag = YuLinFlag
		if m_Equip_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Item,0);
		end
		LongwenLevelUp_Object2:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Item = itemIdx
	else
		LongwenLevelUp_Object2:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Item,0);
		m_Equip_Item = -1;
	end
	LongwenLevelUp_UICheck()
end

--Update UI
function LongwenLevelUp_Update_Stuff(itemIdx)		--铸纹血玉

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if m_UIType == UI_TYPE_COMPOUND then

			local nFlag = 0
			local nNum = table.getn(m_LevelupStuff)
			local nItemIndex = PlayerPackage:GetItemTableIndex( itemIdx )
			for nIndex = 1, nNum do
				if nItemIndex == m_LevelupStuff[nIndex].item then
					nFlag = 1
					break
				end
			end

			if nFlag ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_59}") --此处只能放入铸纹血玉。
				return
			end

			if PlayerPackage:IsLock( itemIdx ) == 1 then
				PushDebugMessage("#{LW_KVK_110704_60}")	--被上锁的铸纹血玉不能作材料龙纹。
				return
			end
		end

		if m_Stuff_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Stuff_Item,0);
		end

		LongwenLevelUp_Object3:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Stuff_Item = itemIdx

	else
		LongwenLevelUp_Object3:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Stuff_Item,0);
		m_Stuff_Item = -1;
	end
	LongwenLevelUp_UICheck();

end


function LongwenLevelUp_Item_Change(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if m_UIType == UI_TYPE_COMPOUND then

			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end

			local main_lv = PlayerPackage:GetBagLWData(itemIdx, "LEVEL")

			if  main_lv ~= nil and main_lv >= 100 then
				PushDebugMessage("#{LW_KVK_110704_08}")		--该龙纹已达到最高合成等级100级，不能继续提升。
				this:Hide()									--隐藏界面
				return
			end

			local sub_lv = PlayerPackage:GetBagLWData(m_Equip_Item, "LEVEL")
			if  main_lv ~= nil and sub_lv ~= nil and main_lv < sub_lv then
				PushDebugMessage("#{LW_KVK_110704_09}") --被提升的龙纹合成等级低于参与提升的龙纹合成等级，无法放入。
				return
			end
		end

		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end

		LongwenLevelUp_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx

	else
		LongwenLevelUp_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end
	LongwenLevelUp_UICheck();

end

--Care Obj
function LongwenLevelUp_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--Auto_OK
function LongwenLevelUp_Auto_OK_Clicked(bComfirmed)

	if nil == bComfirmed then
		bComfirmed = 0
	end

	-- 如果正在自动升级 关掉
	if 1 == m_bOpenAutoLogic and 1 ~= bComfirmed then
		LongwenLevelUp_AutoUpClose()
		return
	end

	if m_Equip_Idx == -1 then
		PushDebugMessage("#{LWDJ_170921_40}")
		return
	end

	if m_Equip_Item == -1 then
		PushDebugMessage("#{LWDJ_170921_41}")
		return
	end

	local nHaveMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")

	if nHaveMoney < m_Money_COMPOUND then
		PushDebugMessage("#{LW_KVK_110704_13}")  --对不起，你身上金钱不足，无法继续进行。
		return
	end

	if 1 ~= bComfirmed then
		MessageBoxSelf3("LongwenLevelUp_OnComfirmedBack", {["Content"] = "#{LWDJ_170921_38}",["Type"] = "YesNo", })
		return
	end
	
	if 1 == LongwenLevelUp_OnLevelUpOnce() then
		-- 打开自动升级
		LongwenLevelUp_AutoUpOpen()
	end
	
end

-- 自动升级启动
function LongwenLevelUp_AutoUpOpen()
	-- 取消快捷提升 LWDJ_170921_36
	LongwenLevelUp_QuickLevelUp : SetText("#{LWDJ_170921_36}")
	LongwenLevelUp_QuickLevelUp_Animate : Show()
	m_bOpenAutoLogic = 1	

	LongwenLevelUp_OK:Disable()
end

-- 关闭自动升级
function LongwenLevelUp_AutoUpClose()
	-- 快捷提升 LWDJ_170921_35
	LongwenLevelUp_QuickLevelUp : SetText("#{LWDJ_170921_35}")
	LongwenLevelUp_QuickLevelUp_Animate : Hide()
	m_bOpenAutoLogic = 0
	KillTimer("LongwenLevelUp_OnTimer()")

	LongwenLevelUp_OK:Enable()
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function LongwenLevelUp_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		LongwenLevelUp_Auto_OK_Clicked(1)
	end

	if "No" == strRet then
		-- 关闭自动升级
		LongwenLevelUp_AutoUpClose()
	end
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function LongwenLevelUp_OnBindComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		LongwenLevelUp_OK_Clicked_Confirm()
	end

	if "No" == strRet then
		-- 关闭自动升级
		LongwenLevelUp_AutoUpClose()
	end
end

--OnOK
function LongwenLevelUp_OK_Clicked()
	LongwenLevelUp_OnLevelUpOnce()
end

-- 执行一次升级操作
function LongwenLevelUp_OnLevelUpOnce()

	-- PushDebugMessage("LongwenLevelUp_OnLevelUpOnce")

	if m_Equip_Idx == -1 then
		PushDebugMessage("#{LWDJ_170921_40}")
		return 0
	end

	if m_Equip_Item == -1 then
		PushDebugMessage("#{LWDJ_170921_41}")
		return 0
	end

	if m_UIType == UI_TYPE_COMPOUND then

		local main_lv = PlayerPackage:GetBagLWData(m_Equip_Idx  , "LEVEL")
		if m_YuLinFlag == 0 then 
			local sub_lv = PlayerPackage:GetBagLWData(m_Equip_Item  , "LEVEL")

			if main_lv == nil or sub_lv == nil then
				return 0									--出错了，不解释
			end

			if main_lv < sub_lv then
				PushDebugMessage("#{LW_KVK_110704_12}") --参与提升的龙纹合成等级高于被提升的龙纹合成等级，无法继续进行。
				return 0
			end
		end

		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")

		if selfMoney < needMoney then
			PushDebugMessage("#{LW_KVK_110704_13}")  --对不起，你身上金钱不足，无法继续进行。

			-- 关闭自动升级
			if 1 == m_bOpenAutoLogic then
				LongwenLevelUp_AutoUpClose()
			end	

			return 0
		end

		--如果主龙纹没绑定，且材料中游绑定的，则弹二次确认框
		if PlayerPackage:GetItemBindStatusByIndex(m_Equip_Idx) ~= 1 and
			( PlayerPackage:GetItemBindStatusByIndex(m_Equip_Item) == 1 or ( m_Stuff_Item >= 0 and PlayerPackage:GetItemBindStatusByIndex(m_Stuff_Item) == 1 ) ) then
			-- PushEvent("UPDATE_LW_BIND_CONFIRM", "#{LWDJ_170921_26}")

			MessageBoxSelf3("LongwenLevelUp_OnBindComfirmedBack", {["Content"] = "#{LWDJ_170921_26}",["Type"] = "YesNo", })
		else
			LongwenLevelUp_OK_Clicked_Confirm()
		end

	end

	return 1
end

--Confirm
function LongwenLevelUp_OK_Clicked_Confirm()
	if m_Equip_Idx == -1 then
		PushDebugMessage("#{LWDJ_170921_40}")
		return
	end

	if m_Equip_Item == -1 then
		PushDebugMessage("#{LWDJ_170921_41}")
		return
	end

	if m_UIType == UI_TYPE_COMPOUND then

		if m_Stuff_Item >= 0 and main_lv == m_NeedConfirmLevel then

			local stuff_num = PlayerPackage:GetBagLWData(m_Equip_Idx  , "STUFF")

			local nCount = 0
			local nNum = table.getn(m_LevelupStuff)
			local nItemIndex = PlayerPackage:GetItemTableIndex( m_Stuff_Item )
			for nIndex = 1, nNum do
				if nItemIndex == m_LevelupStuff[nIndex].item then
					nCount = m_LevelupStuff[nIndex].num
					break
				end
			end

			if nCount + stuff_num > m_MaxStuffNum then
				PushEvent("UPDATE_LW_LEVELUP_CONFIRM")
			else
				LongwenLevelUp_OK_Clicked_Continue()
			end

		else
			LongwenLevelUp_OK_Clicked_Continue()
		end

	end
end

--OnContinue
function LongwenLevelUp_OK_Clicked_Continue()

	PlayerPackage:Lw_Op_Do(TYPE_COMPOUND, m_Equip_Idx,m_Equip_Item,m_Stuff_Item)

	-- 升级龙纹仍然保留在窗口内
	local tEquip_Idx = m_Equip_Idx
	local theAction = EnumAction(tEquip_Idx, "packageitem")
	if theAction:GetID() ~= 0 then
		LongwenLevelUp_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(tEquip_Idx,1);
		m_Equip_Idx = tEquip_Idx
	else
		LongwenLevelUp_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1
	end
	-- 材料龙纹消失
	LongwenLevelUp_Object2:SetActionItem(-1);
	LifeAbility : Lock_Packet_Item(m_Equip_Item,0);
	m_Equip_Item = -1
	-- 铸纹血玉消失
--	LongwenLevelUp_Object3:SetActionItem(-1);
--	LifeAbility : Lock_Packet_Item(m_Stuff_Item,0);
	zwTabIndex =PlayerPackage:GetItemTableIndex(m_Stuff_Item)
--	m_Stuff_Item_Last =m_Stuff_Item
--	m_Stuff_Item = -1

end


--Right button clicked
function LongwenLevelUp_Resume_Equip()
	if 1 ~= LongwenLevelUp_CheckCanMoveItem() then
		return
	end
	LongwenLevelUp_Update(-1)
end

--Right button clicked
function LongwenLevelUp_Resume_Item()
	if 1 ~= LongwenLevelUp_CheckCanMoveItem() then
		return
	end
	LongwenLevelUp_Update_Sub(-1)
end

--Right button clicked
function LongwenLevelUp_Resume_Stuff()
	if 1 ~= LongwenLevelUp_CheckCanMoveItem() then
		return
	end
	LongwenLevelUp_Update_Stuff(-1)
end

-- 是否能移动道具，自动的时候不让操作了
function LongwenLevelUp_CheckCanMoveItem()
	if 1 == m_bOpenAutoLogic then
		-- PushDebugMessage("不让动了")
		return 0
	else
		return 1
	end
end


function LongwenLevelUp_UICheck()
	LongwenLevelUp_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	LongwenLevelUp_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
	LongwenLevelUp_NeedMoney : SetProperty("MoneyNumber", 0)

	-- LongwenLevelUp_OK:Disable()
	-- LongwenLevelUp_QuickLevelUp:Disable()

	m_bCanAutoLogic = 0

	if m_Equip_Idx ~= -1 then
		needMoney = m_Money_COMPOUND
		LongwenLevelUp_NeedMoney : SetProperty("MoneyNumber", needMoney)
	end

	if m_Equip_Idx ~= -1 and m_Equip_Item ~= -1 then
		-- LongwenLevelUp_OK:Enable()
		-- LongwenLevelUp_QuickLevelUp:Enable()
		m_bCanAutoLogic = 1
	end
end

--close & cancel
function LongwenLevelUp_Close()
	this:Hide()
end

function LongwenLevelUp_Cancel_Clicked()
	this:Hide()
end

--handle Hide Event
function LongwenLevelUp_Frame_OnHiden()

	-- PushDebugMessage("LongwenLevelUp_Frame_OnHiden")

	LongwenLevelUp_AutoUpClose()
	
	LongwenLevelUp_Update(-1)
	LongwenLevelUp_Update_Sub(-1)
	LongwenLevelUp_Update_Stuff(-1)
	LongwenLevelUp_Item_Change(-1)
end


