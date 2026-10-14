-- !!!reloadscript =WuhunMagicUp
local m_UI_NUM = 20090721
local m_UI_ComfirmForCompound = 79007601
local m_UI_RefreshForCompound = 79007602
local m_ObjCared = -1
local m_Equip_Idx = -1
local m_Equip_Item = -1
local g_ItemItm   = -1;
local UI_TYPE_ATTR	= 1--武魂扩展属性学习
local UI_TYPE_COMPOUND	= 2--武魂提升灵力
local UI_TYPE_LIFE	= 3--武魂增加寿命
local UI_TYPE_SLOT	= 4--武魂开辟属性栏

local m_UIType = 0

local m_Money_COMPOUND = {}

local INDEX_ATTRBOOK_BEGIN	= 30700214	--御·折冰属性书
local INDEX_ATTRBOOK_END	= 30700229	--暴·拔毒属性书

local INDEX_ADDLIFE = 30700233 --延寿丹

local INDEX_SLOT_ITEM1 = 20310158 --麟木剑
local INDEX_SLOT_ITEM2 = 20310159 --破天剑

-- 武魂灵珠
local g_nBindItemID				= 38005571
local g_nNotBindItemID			= 38005570
local g_nPutWuHunLingZhuID		= 0
local g_nMaxShowNum				= 999

local needMoney = 0

local needConfirm = 1

local g_YBCheck = 1--默认选中
g_WuHun_Material_Buy = -1

local g_LastTimer = -1 --增加点击扩展武魂属性的冷却时间
local MIN_PASS_TIME = 1 --冷却时间1秒

--PreLoad
function WuhunMagicUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_KFS_MAGICUP")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("BUY_ITEM")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
end

--OnLoad
function WuhunMagicUp_OnLoad()
	--武魂合成消耗Money
	m_Money_COMPOUND[1] = 10000
	m_Money_COMPOUND[2] = 10000
	m_Money_COMPOUND[3] = 15000
	m_Money_COMPOUND[4] = 15000
	m_Money_COMPOUND[5] = 20000
	m_Money_COMPOUND[6] = 20000
	m_Money_COMPOUND[7] = 25000
	m_Money_COMPOUND[8] = 25000
	m_Money_COMPOUND[9] = 30000


end

--OnEvent
function WuhunMagicUp_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then
		
		WuhunMagicUp_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)
		
		-- 元宝确认
		WuhunMagicUp_Blank_QuerenLace:Hide()

		-- 特殊下标文本框
		WuhunMagicUp_Object2_Info : Hide()

		if m_UIType == UI_TYPE_ATTR then
			WuhunMagicUp_Title:SetText("#{WH_xml_XX(22)}")	--扩展属性学习
			WuhunMagicUp_Info:SetText("#{WH_xml_XX(23)}")
			WuhunMagicUp_Info2:SetText("#{WH_xml_XX(24)}")
			WuhunMagicUp_Info3:SetText("#{WH_xml_XX(25)}")
		
		elseif m_UIType == UI_TYPE_COMPOUND then
			WuhunMagicUp_Title:SetText("#{WH_xml_XX(18)}")	--合成
			WuhunMagicUp_Info:SetText("#{WH_xml_XX(19)}")
			WuhunMagicUp_Info2:SetText("#{WH_xml_XX(20)}")
			WuhunMagicUp_Info3:SetText("#{WH_xml_XX(21)}")
		
		elseif m_UIType == UI_TYPE_LIFE then
			if Get_XParam_INT(2) ~= nil and Get_XParam_INT(2) == 1 then
				if this:IsVisible() then
					this:Hide()
				end
				return
			end
			WuhunMagicUp_Title:SetText("#{WH_xml_XX(42)}")	--增加寿命
			WuhunMagicUp_Info:SetText("#{WH_xml_XX(43)}")
			WuhunMagicUp_Info2:SetText("#{WH_xml_XX(44)}")
			WuhunMagicUp_Info3:SetText("#{WH_xml_XX(45)}")
			-- 元宝确认
			WuhunMagicUp_Blank_QuerenLace:Show()
			if g_YBCheck == 1 then
				WuhunMagicUp_Blank_Queren:SetCheck( 1 )
			elseif g_YBCheck == 0 then
				WuhunMagicUp_Blank_Queren:SetCheck( 0 )
			end
		elseif m_UIType == UI_TYPE_SLOT then
			return
			--WuhunMagicUp_Title:SetText("#{WH_xml_XX(84)}")	--开辟属性栏
			--WuhunMagicUp_Info:SetText("#{WH_xml_XX(85)}")
			--WuhunMagicUp_Info2:SetText("#{WH_xml_XX(86)}")
			--WuhunMagicUp_Info3:SetText("#{WH_xml_XX(87)}")
		end		

		WuhunMagicUp_Update(-1)
		WuhunMagicUp_Update_Sub(-1)
		this:Show();
	
	elseif (event == "UPDATE_KFS_MAGICUP" and this:IsVisible() ) then
		if m_UIType == UI_TYPE_COMPOUND then
			if arg1 ~= nil and tonumber(arg1) == 2 and arg0 ~= nil then
				if m_Equip_Idx ~= -1 then
					-- PushDebugMessage("WuhunMagicUp_Update_Sub2"..",arg1"..arg1..",arg0"..arg0)
					WuhunMagicUp_Update_Sub( tonumber(arg0) )
				else 
					WuhunMagicUp_Update( tonumber(arg0) )
				end
			elseif arg1 ~= nil and tonumber(arg1) == 1 and arg0 ~= nil then
				-- PushDebugMessage("WuhunMagicUp_Update_Sub2"..",arg1"..arg1..",arg0"..arg0)
				WuhunMagicUp_Update_Sub( tonumber(arg0) )
			elseif arg1 ~= nil and tonumber(arg1) == 0 and arg0 ~= nil then
				WuhunMagicUp_Update( tonumber(arg0) )
			end
		else
			if arg1 ~= nil and tonumber(arg1) == 0 and arg0 ~= nil then
				WuhunMagicUp_Update( tonumber(arg0) )
		
			elseif arg1 ~= nil and tonumber(arg1) == 2 and arg0 ~= nil then
				WuhunMagicUp_Update( tonumber(arg0) )
			
			elseif arg1 ~= nil and tonumber(arg1) == 1 and arg0 ~= nil then
				WuhunMagicUp_Update_Sub( tonumber(arg0) )
			end
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == m_UI_ComfirmForCompound) then
		-- 合成的二次确认框
		local strMsg = Get_XParam_STR(0)
		-- g_nComfirmParam1 = Get_XParam_INT(1)
		-- ["Type"] "Ok" "YesNo"
		MessageBoxSelf3("WuhunMagicUp_OnCompoundComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
	elseif (event == "UI_COMMAND" and tonumber(arg0) == m_UI_RefreshForCompound) then
		-- 合成完成以后刷新界面
		-- WuhunMagicUp_Object1 : SetActionItem(-1);	
		-- WuhunMagicUp_Object2 : SetActionItem(-1);
		-- LifeAbility : Lock_Packet_Item(m_Equip_Idx, 0)
		-- LifeAbility : Lock_Packet_Item(m_Equip_Item, 0)
		-- m_Equip_Idx = -1
		-- m_Equip_Item = -1

	elseif (event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible()) then
		if(arg0~=nil and tonumber(arg0) == 85) then
			WuhunMagicUp_Resume_Equip()
		elseif(arg0~=nil and tonumber(arg0) == 86) then
			WuhunMagicUp_Resume_Item()
		end
	elseif (event == "MONEY_CHANGE_EX") then
		WuhunMagicUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	
	elseif (event == "MONEYJZ_CHANGE_EX") then 
		WuhunMagicUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	elseif event == "BUY_ITEM" and this:IsVisible() then
		if m_UIType == UI_TYPE_LIFE and m_Equip_Idx ~= -1 and g_WuHun_Material_Buy > 0 then
			local item = tonumber(arg1)
			if item > 0 then
				if INDEX_ADDLIFE ~= item then 
					return 
				end
				local itemIdx = PlayerPackage:GetBagPosByItemIndex(item)
				if itemIdx >= 0 then
					g_WuHun_Material_Buy = -1
					WuhunMagicUp_Update_Sub(itemIdx)
				end
			end
		end

	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then

		-- 武魂合成特写逻辑
		if m_UIType == UI_TYPE_COMPOUND then
			WuhunMagicUp_ItemChange_ForCompound()
			return
		end

		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			WuhunMagicUp_Update(m_Equip_Idx)
		
		elseif  arg0 ~= nil and tonumber(arg0) == m_Equip_Item then
			--WuhunMagicUp_Update_Sub(m_Equip_Item)
		
			--【修改人：陈永帅】
			--【TT：78726】
			if (g_ItemItm ~= -1) then
				local nextItem = PlayerPackage : GetBagPosByItemIndex(g_ItemItm)
				if nextItem >=0 then
					WuhunMagicUp_Update_Sub(nextItem)
				else
					WuhunMagicUp_Update_Sub(-1)
				end
			else
				WuhunMagicUp_Update_Sub(-1)
			end
		end
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	end
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function WuhunMagicUp_OnCompoundComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		WuhunMagicUp_OnCompound(1)
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 合成确认
--=========================================================
function WuhunMagicUp_OnCompound(bComfirmed)

	if nil == bComfirmed then
		bComfirmed = 0
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnWuHunCompoundNew" )
		Set_XSCRIPT_ScriptID(790076)
		Set_XSCRIPT_Parameter(0, m_Equip_Idx)					
		Set_XSCRIPT_Parameter(1, m_Equip_Item)					
		Set_XSCRIPT_Parameter(2, bComfirmed)					
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--Update UI
function WuhunMagicUp_Update(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		if PlayerPackage:IsBagItemKFS( itemIdx ) ~= 1 then
			PushDebugMessage("#{WH_090729_13}") -- 此处只能放入武魂。
			return
		end
		
		if m_UIType == UI_TYPE_COMPOUND then
			-- PushDebugMessage("WuhunMagicUp_Update")
			local main_lv = PlayerPackage:GetBagKfsData(itemIdx  , "EXTRALEVEL")
			local sub_lv = PlayerPackage:GetBagKfsData(m_Equip_Item  , "EXTRALEVEL")
			
			-- if  main_lv ~= nil and sub_lv ~= nil and main_lv ~= sub_lv then 
			-- 	PushDebugMessage("#{WH_090729_17}")  --参与合成的武魂灵力等级需要等于要提升灵力等级的武魂
			-- 	return
			-- end

			main_lv = PlayerPackage:GetBagKfsData(itemIdx  , "NEEDLEVEL")
			sub_lv = PlayerPackage:GetBagKfsData(m_Equip_Item  , "NEEDLEVEL")
			if  main_lv ~= nil and sub_lv ~= nil and main_lv > sub_lv and 1 == PlayerPackage:IsBagItemKFS( m_Equip_Item ) then 
				PushDebugMessage("#{WH_090729_16}") --参与合成的武魂携带等级不能小于要提升灵力等级的武魂。
				return
			end

			main_lv = PlayerPackage:GetBagKfsData(itemIdx  , "EXTRALEVEL")
			if main_lv ~= nil and main_lv == 10 then
				PushDebugMessage("#{WH_090729_14}")  --10级了
				return
			end
		elseif  m_UIType == UI_TYPE_ATTR then

			local slotNum = PlayerPackage:GetBagKfsData(itemIdx  , "SLOT")
			local attrNum = PlayerPackage:GetBagKfsAttrExNum(itemIdx)
			if attrNum >= slotNum and slotNum >= 0 then
				if m_Equip_Idx == itemIdx then
					WuhunMagicUp_Object1:SetActionItem(-1);			
					LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
					m_Equip_Idx = -1;
					return
				end
				
				PushDebugMessage("#{WH_090729_56}") -- 需要有空余的属性栏，才能学习扩展属性。
				return
			end
		elseif m_UIType == UI_TYPE_LIFE then
			-- 寿命超过上限
			local curLife = PlayerPackage:GetBagKfsData(itemIdx, "LIFE")
			local maxLife = PlayerPackage:GetBagKfsData(itemIdx, "MAXLIFE")
			if curLife >= maxLife then
				if m_Equip_Idx == itemIdx then
					WuhunMagicUp_Object1:SetActionItem(-1);			
					LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
					m_Equip_Idx = -1;
					return
				end				
				PushDebugMessage("#{WHYH_161121_86}") --该武魂不需要延长寿命。
				return
			end			
		elseif  m_UIType == UI_TYPE_SLOT then
			return
			--local comLv = PlayerPackage:GetBagKfsData(itemIdx  , "EXTRALEVEL")
			--local slotNum = PlayerPackage:GetBagKfsData(itemIdx  , "SLOT")
			--if comLv ~=nil and slotNum ~= nil and slotNum >= comLv then
				--if m_Equip_Idx == itemIdx then
					--WuhunMagicUp_Object1:SetActionItem(-1);			
					--LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
					--m_Equip_Idx = -1;
					--return
				--end
				--if slotNum == 10 then
					--PushDebugMessage("#{WH_090817_13}") -- 武魂的扩展属性栏数已经到达最大值10栏。
				--else
					--PushDebugMessage("#{WH_090729_50}") -- 该武魂不能开辟新的属性栏。提升灵力等级后，可以开辟新的属性栏。
				--end
				--return
			--end
		end
		
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end
		
		WuhunMagicUp_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx
		
	else
		WuhunMagicUp_Object1:SetActionItem(-1);			
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
		m_Equip_Idx = -1;
	end
	WuhunMagicUp_UICheck();

end

function WuhunMagicUp_Update_Sub(itemIdx)

	-- 武魂合成放入逻辑特写
	if m_UIType == UI_TYPE_COMPOUND then
		WuhunMagicUp_Update_Sub_ForCompound(itemIdx)
		return
	end

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		if m_UIType == UI_TYPE_ATTR then
			local itemID = PlayerPackage:GetItemTableIndex(itemIdx)
			if itemID < INDEX_ATTRBOOK_BEGIN or itemID > INDEX_ATTRBOOK_END then
				PushDebugMessage("#{WH_090729_20}")  --此处只能放入武魂属性书。
				return
			end

			if PlayerPackage:IsLock( itemIdx ) == 1 then
				PushDebugMessage("#{WH_090729_07}")	--道具上锁。
				return
			end
	
		-- elseif m_UIType == UI_TYPE_COMPOUND then
		-- 	-- PushDebugMessage("WuhunMagicUp_Update_Sub")
		-- 	local itemID = PlayerPackage:GetItemTableIndex(itemIdx)
		-- 	if PlayerPackage:IsBagItemKFS( itemIdx ) ~= 1 and g_nBindItemID ~= itemID and g_nNotBindItemID ~= itemID then
		-- 		PushDebugMessage("#{WHYH_210811_1}")	--此处只能放入武魂或者武魂灵珠。
		-- 		return
		-- 	end
			
		-- 	if PlayerPackage:IsLock( itemIdx ) == 1 then
		-- 		PushDebugMessage("#{WH_090729_15}")	--被上锁的武魂不能作材料武魂。
		-- 		return
		-- 	end

		-- 	if 1 == PlayerPackage:IsBagItemKFS( itemIdx ) then
		-- 		local gem_count = LifeAbility : GetEquip_GemCount( itemIdx )
		-- 		if gem_count ~= nil and gem_count > 0 then
		-- 			PushDebugMessage("#{WH_20090904_01}")	--WH_20090904_01 镶嵌有宝石的武魂不能作为合成材料！
		-- 			return
		-- 		end
				
		-- 		local haveDiaowen = LifeAbility : IsEquipHaveDiaowen( itemIdx )
		-- 		if haveDiaowen > 0 then
		-- 			PushDebugMessage("#{ZBDW_091105_17}")	--有雕纹的武魂不能作为材料武魂
		-- 			return
		-- 		end

		-- 		local main_lv = PlayerPackage:GetBagKfsData(m_Equip_Idx  , "NEEDLEVEL")
		-- 		local sub_lv = PlayerPackage:GetBagKfsData(itemIdx  , "NEEDLEVEL")
		-- 		if  main_lv ~= nil and sub_lv ~= nil and main_lv > sub_lv then 
		-- 			PushDebugMessage("#{WH_090729_16}") --参与合成的武魂携带等级不能小于要提升灵力等级的武魂。
		-- 			return
		-- 		end

		-- 		-- main_lv = PlayerPackage:GetBagKfsData(m_Equip_Idx  , "EXTRALEVEL")
		-- 		-- sub_lv = PlayerPackage:GetBagKfsData(itemIdx  , "EXTRALEVEL")
		-- 		-- if  main_lv ~= nil and sub_lv ~= nil and main_lv ~= sub_lv then 
		-- 		-- 	PushDebugMessage("#{WH_090729_17}")  --参与合成的武魂灵力等级需要等于要提升灵力等级的武魂
		-- 		-- 	return
		-- 		-- end
		-- 	end			
	
		elseif m_UIType == UI_TYPE_LIFE then
			local itemID = PlayerPackage:GetItemTableIndex(itemIdx)
			if itemID ~=  INDEX_ADDLIFE then
				PushDebugMessage("#{WH_090729_36}") --此处只能放入武魂延寿丹。
				return
			end

			if PlayerPackage:IsLock( itemIdx ) == 1 then
				PushDebugMessage("#{WH_090729_07}")	--道具已上锁
				return
			end
		elseif m_UIType == UI_TYPE_SLOT then
			return
			--local itemID = PlayerPackage:GetItemTableIndex(itemIdx)
			--if itemID ~=  INDEX_SLOT_ITEM1 and itemID ~= INDEX_SLOT_ITEM2 then
				--PushDebugMessage("#{WH_090729_51}") --此处只能放入麟木箭、破天剑
				--return
			--end

			--if PlayerPackage:IsLock( itemIdx ) == 1 then
				--PushDebugMessage("#{WH_090729_52}")	--道具已上锁
				--return
			--end
		end  

		if m_Equip_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Item,0);
		end
		WuhunMagicUp_Object2:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Item = itemIdx
	else
		WuhunMagicUp_Object2:SetActionItem(-1);			
		LifeAbility : Lock_Packet_Item(m_Equip_Item,0);		
		m_Equip_Item = -1;
	end

	WuhunMagicUp_UICheck()
end

-- 武魂合成道具数量变化逻辑特写
function WuhunMagicUp_ItemChange_ForCompound()

	if nil == arg0 then
		return
	end

	-- PushDebugMessage("WuhunMagicUp_ItemChange_ForCompound nChangeItemPos: In"..arg0)

	local nChangeItemPos = tonumber(arg0)

	if nil == nChangeItemPos then

		-- 这种情况是各种背包整理和天机锦囊的操作 直接更新数量
		if g_nPutWuHunLingZhuID > 0 and m_Equip_Item >= 0 then
			WuhunMagicUp_Update_Sub(m_Equip_Item)
		end

		return
	end

	-- PushDebugMessage("WuhunMagicUp_ItemChange_ForCompound nChangeItemPos:"..nChangeItemPos)

	if m_UIType ~= UI_TYPE_COMPOUND then
		return
	end

	-- 刷新的是主窗口的道具
	if nChangeItemPos == m_Equip_Idx then
		WuhunMagicUp_Update(m_Equip_Idx)
		return
	end

	-- 材料窗口没有东西的时候就不管了
	-- if condition then
	-- 	-- statements
	-- end

	local nChangeItemID = PlayerPackage:GetItemTableIndex(nChangeItemPos)

	-- 如果放入的是灵珠，涉及到灵珠的物品数量改变都刷新一次
	-- if nChangeItemPos == m_Equip_Item and g_nPutWuHunLingZhuID > 0 then
	if (nChangeItemID == g_nBindItemID or nChangeItemID == g_nNotBindItemID or nChangeItemPos == m_Equip_Item) and g_nPutWuHunLingZhuID > 0 then
		-- PushDebugMessage("WuhunMagicUp_ItemChange_ForCompound 如果放入的是灵珠，涉及到灵珠的物品数量改变都刷新一次:"..g_nPutWuHunLingZhuID)

		local nCurPosItemTableID = PlayerPackage:GetItemTableIndex(m_Equip_Item)

		-- 说明本来位置的灵珠被消耗光了 重新计算一个位置扔进去
		if nil == nCurPosItemTableID or nCurPosItemTableID < 0 then	
			local nNextPos = PlayerPackage : GetBagPosByItemIndex(g_nPutWuHunLingZhuID)
			if nil == nNextPos or nNextPos < 0 then
				if g_nPutWuHunLingZhuID == g_nBindItemID then
					nNextPos = PlayerPackage : GetBagPosByItemIndex(g_nNotBindItemID)
				else
					nNextPos = PlayerPackage : GetBagPosByItemIndex(g_nBindItemID)
				end				
			end

			-- 两种道具都没有直接清空
			if nil == nNextPos or nNextPos < 0 then
				WuhunMagicUp_Update_Sub(-1)
			else
				WuhunMagicUp_Update_Sub(nNextPos)
			end
		else
			WuhunMagicUp_Update_Sub(m_Equip_Item)
		end
		return
	end

	-- 到这里就是正常逻辑了
	if nChangeItemPos == m_Equip_Item then
		-- PushDebugMessage("WuhunMagicUp_ItemChange_ForCompound 到这里就是正常逻辑了:")
		WuhunMagicUp_Update_Sub(m_Equip_Item)
	end

end

-- 武魂合成放入逻辑特写
function WuhunMagicUp_Update_Sub_ForCompound(itemIdx)

	if m_UIType ~= UI_TYPE_COMPOUND then
		return
	end

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		-- PushDebugMessage("WuhunMagicUp_Update_Sub")
		local itemID = PlayerPackage:GetItemTableIndex(itemIdx)
		if PlayerPackage:IsBagItemKFS( itemIdx ) ~= 1 and g_nBindItemID ~= itemID and g_nNotBindItemID ~= itemID then
			PushDebugMessage("#{WHYH_210811_1}")	--此处只能放入武魂或者武魂灵珠。
			return
		end
		
		if PlayerPackage:IsLock( itemIdx ) == 1 then
			PushDebugMessage("#{WH_090729_15}")	--被上锁的武魂不能作材料武魂。
			return
		end

		if 1 == PlayerPackage:IsBagItemKFS( itemIdx ) then
			local gem_count = LifeAbility : GetEquip_GemCount( itemIdx )
			if gem_count ~= nil and gem_count > 0 then
				PushDebugMessage("#{WH_20090904_01}")	--WH_20090904_01 镶嵌有宝石的武魂不能作为合成材料！
				return
			end
			
			local haveDiaowen = LifeAbility : IsEquipHaveDiaowen( itemIdx )
			if haveDiaowen > 0 then
				PushDebugMessage("#{ZBDW_091105_17}")	--有雕纹的武魂不能作为材料武魂
				return
			end

			local main_lv = PlayerPackage:GetBagKfsData(m_Equip_Idx  , "NEEDLEVEL")
			local sub_lv = PlayerPackage:GetBagKfsData(itemIdx  , "NEEDLEVEL")
			if  main_lv ~= nil and sub_lv ~= nil and main_lv > sub_lv then 
				PushDebugMessage("#{WH_090729_16}") --参与合成的武魂携带等级不能小于要提升灵力等级的武魂。
				return
			end

			-- main_lv = PlayerPackage:GetBagKfsData(m_Equip_Idx  , "EXTRALEVEL")
			-- sub_lv = PlayerPackage:GetBagKfsData(itemIdx  , "EXTRALEVEL")
			-- if  main_lv ~= nil and sub_lv ~= nil and main_lv ~= sub_lv then 
			-- 	PushDebugMessage("#{WH_090729_17}")  --参与合成的武魂灵力等级需要等于要提升灵力等级的武魂
			-- 	return
			-- end
		end	
		
		-- 解锁上一个锁定的道具
		if g_nPutWuHunLingZhuID > 0 then
			LifeAbility:Lock_Packet_ItemByID(g_nBindItemID, 0)
			LifeAbility:Lock_Packet_ItemByID(g_nNotBindItemID, 0)
		elseif m_Equip_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Item, 0)
		end

		-- 锁新道具
		local nItemTableID = PlayerPackage:GetItemTableIndex(itemIdx)
		if g_nBindItemID == nItemTableID or g_nNotBindItemID == nItemTableID then
			local nHaveCountBind = PlayerPackage:CountAvailableItemByIDTable(g_nBindItemID)
			local nHaveCountNotBind = PlayerPackage:CountAvailableItemByIDTable(g_nNotBindItemID)
			local nTotalCount = nHaveCountBind + nHaveCountNotBind
			if nHaveCountBind > 0 then
				local theActionCreate = DataPool:CreateBindActionItemForShow(g_nBindItemID, 1)
				WuhunMagicUp_Object2 : SetActionItem(theActionCreate:GetID())
			else
				local theActionCreate = DataPool:CreateActionItemForShow(g_nNotBindItemID, 1)
				WuhunMagicUp_Object2 : SetActionItem(theActionCreate:GetID())
			end
			
			WuhunMagicUp_Object2_Info : Show()
			WuhunMagicUp_SetSpecailMatNumForCompound(nTotalCount)

			LifeAbility:Lock_Packet_ItemByID(g_nBindItemID, 1)
			LifeAbility:Lock_Packet_ItemByID(g_nNotBindItemID, 1)
			g_nPutWuHunLingZhuID = nItemTableID
		else
			WuhunMagicUp_Object2 : SetActionItem(theAction:GetID())
			WuhunMagicUp_Object2_Info : Hide()
			LifeAbility : Lock_Packet_Item(itemIdx, 1)
			g_nPutWuHunLingZhuID = 0
		end	
	
		-- 缓存当前背包位置
		m_Equip_Item = itemIdx
	else

		-- 解锁上一个锁定的道具
		if g_nPutWuHunLingZhuID > 0 then
			LifeAbility:Lock_Packet_ItemByID(g_nBindItemID, 0)
			LifeAbility:Lock_Packet_ItemByID(g_nNotBindItemID, 0)
		elseif m_Equip_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Item, 0)
		end

		WuhunMagicUp_Object2:SetActionItem(-1);		
		WuhunMagicUp_Object2_Info : Hide()	
		m_Equip_Item = -1;
		g_nPutWuHunLingZhuID = 0
	end

	WuhunMagicUp_UICheck()
end

function WuhunMagicUp_SetSpecailMatNumForCompound(nTotalCount)
	local strForShow = ScriptGlobal_Format("#{WHYH_210811_52}", nTotalCount)
	if nTotalCount > g_nMaxShowNum then
		strForShow = "#{WHYH_210811_53}"
	end

	-- strForShow = nTotalCount
	-- PushDebugMessage("nTotalCount"..nTotalCount)
	WuhunMagicUp_Object2_Info : SetText(strForShow)
end

--Care Obj
function WuhunMagicUp_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--add by kaibin for tt86633 2010-12-9
--点击增加扩展属性cooldown时间检查
function AddExtAttr_PassTime()
   local iCur = Exchange:GetTickCount();

	if g_LastTimer == -1 then
		g_LastTimer = iCur;
		return 1
	end

   if ( iCur - g_LastTimer < MIN_PASS_TIME * 1000) then
      return 0
   else
      g_LastTimer = iCur;
   	  return 1
   end
end

--OnOK
function WuhunMagicUp_Life_OK_Clicked()
	if m_UIType ~= UI_TYPE_LIFE then
		return
	end
	
	-- 判断是否为安全时间
	--if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		--PushDebugMessage("#{WHYH_161121_8}")
		--return
	--end
	
	-- 判断电话密保和二级密码保护
	--if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		--return
	--end

	-- 是否放入武魂
	if m_Equip_Idx == -1 then
		PushDebugMessage("#{WHYH_161121_87}")
		return
	end
	if PlayerPackage:IsBagItemKFS( m_Equip_Idx ) ~= 1 then
		PushDebugMessage("#{WHYH_161121_87}")
		return
	end
	
	-- 寿命超过上限
	local curLife = PlayerPackage:GetBagKfsData(m_Equip_Idx, "LIFE")
	local maxLife = PlayerPackage:GetBagKfsData(m_Equip_Idx, "MAXLIFE")
	if curLife >= maxLife then
		PushDebugMessage("#{WHYH_161121_86}") --该武魂不需要延长寿命。
		return
	end			
	
	-- 玩家身上的金钱是否足够
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")	
	if selfMoney < needMoney then
		PushDebugMessage("#{WHYH_161121_88}")  --对不起，你身上金钱不足，无法继续进行。
		return
	end
	
	if m_ObjCared == -1 then
		PlayerPackage:Kfs_Op_Do(4 , m_Equip_Idx,m_Equip_Item, 1, g_YBCheck)
	else
		PlayerPackage:Kfs_Op_Do(4 , m_Equip_Idx,m_Equip_Item, 0, g_YBCheck)
	end
	
	-- 关闭界面
	-- this:Hide();
end

--OnOK
function WuhunMagicUp_OK_Clicked()
	-- 延寿特殊处理
	if m_UIType == UI_TYPE_LIFE then
		WuhunMagicUp_Life_OK_Clicked()
		return
	end
	
	if m_Equip_Idx == -1 or m_Equip_Item == -1 then
		return
	end
	
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	
	if selfMoney < needMoney then
		PushDebugMessage("#{WH_090729_18}")  --对不起，你身上金钱不足，无法继续进行。
		return
	end
	

	if m_UIType == UI_TYPE_ATTR then
		PlayerPackage:Kfs_Op_Do(2 , m_Equip_Idx ,m_Equip_Item)

	elseif m_UIType == UI_TYPE_COMPOUND then
		-- local level = PlayerPackage:GetBagKfsData(m_Equip_Idx  , "EXTRALEVEL")
		-- if level == nil or level >= 7 then    --拉收 级别控制 客户端
		-- 	PushDebugMessage("#{WH_090828_04}")  --5级以上合成暂不开放。
		-- 	return
		-- end

		-- if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		-- 	return
		-- end
		
		-- if needConfirm == 1 then
		-- 	PopComfirm_Alpha1("#{WH_090825_01}")  --由于材料武魂是绑定的，合成后的武魂也将与您绑定
		-- 	needConfirm = 0
		-- 	return
		-- end
		
		-- PlayerPackage:Kfs_Op_Do(3 , m_Equip_Idx,m_Equip_Item)

		-- g_ItemItm = PlayerPackage : GetItemTableIndex( m_Equip_Item )
		WuhunMagicUp_OnCompound(0)
		
		-- WuhunMagicUp_Object1:SetActionItem(-1);	
		-- WuhunMagicUp_Object2:SetActionItem(-1);
		-- LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		-- LifeAbility : Lock_Packet_Item(m_Equip_Item,0);
		-- m_Equip_Item = -1
		-- m_Equip_Idx = -1
	
	--elseif m_UIType == UI_TYPE_LIFE then
		--if m_ObjCared == -1 then
			--PlayerPackage:Kfs_Op_Do(4 , m_Equip_Idx,m_Equip_Item, 1, g_YBCheck)
		--else
			--PlayerPackage:Kfs_Op_Do(4 , m_Equip_Idx,m_Equip_Item, 0, g_YBCheck)
		--end
		
		--this:Hide();	--[YuanPeiLong]
	--elseif m_UIType == UI_TYPE_SLOT then
		--add by kaibin 增加点击增加武魂扩展属性冷却时间判断
		--if AddExtAttr_PassTime() == 0 then
			--return
		--end
		--【修改人：陈永帅】
		--【TT：78726】
		--g_ItemItm = PlayerPackage : GetItemTableIndex( m_Equip_Item )
		--PlayerPackage:Kfs_Op_Do(9 , m_Equip_Idx,m_Equip_Item)
	end
end

--Right button clicked
function WuhunMagicUp_Resume_Equip()

	WuhunMagicUp_Update(-1)

end

--Right button clicked
function WuhunMagicUp_Resume_Item()
	
	WuhunMagicUp_Update_Sub(-1)

end

--handle Hide Event
function WuhunMagicUp_OnHiden()

	WuhunMagicUp_Update(-1)
	WuhunMagicUp_Update_Sub(-1)

	-- g_nPutWuHunLingZhuID = 0

end

function WuhunMagicUp_UICheck()
	WuhunMagicUp_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	WuhunMagicUp_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); 
	WuhunMagicUp_DemandMoney : SetProperty("MoneyNumber", 0)
	WuhunMagicUp_OK:Disable()
	needConfirm = 1

	if m_Equip_Idx ~= -1 then
	
		if m_UIType == UI_TYPE_ATTR then
			needMoney = 80000
		
		elseif m_UIType == UI_TYPE_COMPOUND then
			local comLevel = PlayerPackage:GetBagKfsData(m_Equip_Idx  , "EXTRALEVEL")
			if comLevel ~= nil and comLevel > 0 and comLevel < 10 then
				needMoney = m_Money_COMPOUND[comLevel]
			end

		elseif m_UIType == UI_TYPE_LIFE then
			needMoney = 50000
		--elseif m_UIType == UI_TYPE_SLOT then
			--needMoney = PlayerPackage:GetBagKfsSlotMoney(m_Equip_Idx)
		end
		if IsTBFinalServer() >= 1 then
			needMoney = 0
		end
		WuhunMagicUp_DemandMoney : SetProperty("MoneyNumber", needMoney)
	end
	
	if m_Equip_Idx ~= -1 and ( m_UIType == UI_TYPE_LIFE or m_Equip_Item ~= -1 )then
		WuhunMagicUp_OK:Enable()
	end
end

function WuhunMagicUp_Queren_Clicked()
	local bCheck = WuhunMagicUp_Blank_Queren:GetCheck();
	if ( bCheck == 1 ) then
		g_YBCheck = 1
		WuhunMagicUp_Blank_Queren:SetCheck( 1 )
	elseif ( bCheck == 0 ) then
		g_YBCheck = 0
		WuhunMagicUp_Blank_Queren:SetCheck( 0 )
	end
end

--Help
function WuhunMagicUp_Help_Clicked()
	if m_UIType == UI_TYPE_ATTR then
		Helper:GotoHelper("*WuhunExtraPropertyUp")
	elseif m_UIType == UI_TYPE_COMPOUND then
		Helper:GotoHelper("*WuhunMagicUp")
	elseif m_UIType == UI_TYPE_LIFE then
		Helper:GotoHelper("*Wuhun")
	elseif m_UIType == UI_TYPE_SLOT then
		Helper:GotoHelper("*WuhunExtraPropertyUp")
	end	

end
