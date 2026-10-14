local g_Object = -1;
local objCared = -1;
local g_EquipBaoshiyi_Frame_UnifiedPosition;
local GEMSOURCE_BUTTONS = {}
local GEMDEST_BUTTONS = {}
local EQUIPITEM_SOURCE = -1
local EQUIPITEM_DEST = -1
--local EQUIPITEM_QIANKUNFU = -1
local bConfirm = -1
-- 装备允许镶嵌的宝石类型表
local g_EquipGemTable = {}
local g_GemLevelTable = {}
local g_bClick = -1;
--local g_needFu = -1;
function EquipBaoshiyi_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("UPDATE_BAOSHIYI")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("BAOSHIYI_CLEAR")
end

function EquipBaoshiyi_OnLoad()
	GEMSOURCE_BUTTONS[1] = EquipBaoshiyi_Special_Button
	GEMSOURCE_BUTTONS[2] = EquipBaoshiyi_Special_Button1
	GEMSOURCE_BUTTONS[3] = EquipBaoshiyi_Special_Button2
	GEMSOURCE_BUTTONS[4] = EquipBaoshiyi_Special_Button3
	GEMSOURCE_BUTTONS[5] = EquipBaoshiyi_Special_Button4
	EQUIPITEM_SOURCE = -1;
	EQUIPITEM_DEST = -1;


	GEMDEST_BUTTONS[1] = EquipBaoshiyi_Special_Button5
	GEMDEST_BUTTONS[2] = EquipBaoshiyi_Special_Button6
	GEMDEST_BUTTONS[3] = EquipBaoshiyi_Special_Button7
	GEMDEST_BUTTONS[4] = EquipBaoshiyi_Special_Button8
	GEMDEST_BUTTONS[5] = EquipBaoshiyi_Special_Button9
	--QIANKUNFU_BUTTON = EquipBaoshiyi_Special_ButtonM
	g_EquipBaoshiyi_Frame_UnifiedPosition = EquipBaoshiyi_Frame:GetProperty("UnifiedPosition");
	--EquipBaoshiyi_huifu : Disable()
	EquipBaoshiyi_zhuanyi : Enable()
	EquipBaoshiyi_zhuanyi : SetText("#{BSQKY_20110506_05}")
	g_EquipGemTable[0] = { 1, 2, 3, 4, 6, 7, 8, 9, 21, 26 }
	g_EquipGemTable[1] = { 11, 12, 13, 14, 16, 17, 18, 19 }
	g_EquipGemTable[2] = { 11, 12, 13, 14, 16, 17, 18, 19 }
	g_EquipGemTable[3] = { 11, 12, 13, 14, 16, 17, 18, 19 }
	g_EquipGemTable[4] = { 11, 12, 13, 14, 16, 17, 18, 19 }
	g_EquipGemTable[5] = { 11, 12, 13, 14, 16, 17, 18, 19 }
	g_EquipGemTable[6] = { 1, 2, 3, 4, 6, 7, 8, 9, 21, 26 }
	g_EquipGemTable[7] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 26 }
	g_EquipGemTable[11] = { 1, 2, 3, 4, 6, 7, 8, 9, 21, 26 }
	g_EquipGemTable[12] = { 1, 2, 3, 4, 6, 7, 8, 9, 21, 26 }
	g_EquipGemTable[13] = { 1, 2, 3, 4, 6, 7, 8, 9, 21, 26 }
	g_EquipGemTable[14] = { 1, 2, 3, 4, 6, 7, 8, 9, 21, 26 }
	g_EquipGemTable[15] = { 11, 12, 13, 14, 16, 17, 18, 19 }
	g_EquipGemTable[17] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 26 }
	g_EquipGemTable[18] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 26 }
	g_EquipGemTable[19] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 26 }
	g_EquipGemTable[20] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 }
	g_EquipGemTable[21] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 26 }
	g_EquipGemTable[23] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 26 }
	g_GemLevelTable[1] = 2
	g_GemLevelTable[2] = 3
	g_GemLevelTable[3] = 6
	g_GemLevelTable[4] = 8
	g_GemLevelTable[5] = 24
	g_GemLevelTable[6] = 29
	g_GemLevelTable[7] = 34
	g_GemLevelTable[8] = 39
	g_GemLevelTable[9] = 44
	--EQUIPITEM_QIANKUNFU = 30900104
end


function EquipBaoshiyi_OnEvent(event)
	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			
			--取消关心
			EquipBaoshiyi_Cancel_Clicked()
		end

	elseif ( event == "UI_COMMAND" and tonumber(arg0)== 20110509 ) then
		EquipBaoshiyi_Close();
		this:Show();
		EquipBaoshiyi_OnShown();
		objCared = -1;
		local xx = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(xx);
		if objCared == -1 then
				return;
		end
		BeginCareObject_EquipBaoshiyi(objCared)
		return

	elseif ( event == "UPDATE_BAOSHIYI" and this:IsVisible() ) then
		EquipBaoshiyi_Update(arg0, arg1);

--------------------------------------------------
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
   return
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		EquipBaoshiyi_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		EquipBaoshiyi_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ"))); --zchw
		
	elseif (event == "ADJEST_UI_POS" ) then
		EquipBaoshiyi_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipBaoshiyi_Frame_On_ResetPos()
	elseif (event == "BAOSHIYI_CLEAR") then
		EquipBaoshiyi_Clear();
	end

end

function EquipBaoshiyi_OnShown()
	EquipBaoshiyi_Clear();
	EquipBaoshiyi_zhuanyi : Enable()
	EquipBaoshiyi_zhuanyi : SetText("#{BSQKY_20110506_05}")
	g_bClick = 0
	--EquipBaoshiyi_huifu : Disable()
	EquipBaoshiyi_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	EquipBaoshiyi_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ"))); --zchw
end

function EquipBaoshiyi_Clear()
	EquipBaoshiyi_NeedMoney:SetProperty("MoneyNumber", tostring(0));
	--EquipBaoshiyi_SpecialM_Info : SetText("#{BSQKY_20110506_36}")
	EquipBaoshiyi_zhuanyi : SetText("#{BSQKY_20110506_05}")
	--g_needFu = -1
	if (EQUIPITEM_SOURCE ~= -1) then
		GEMSOURCE_BUTTONS[1]:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(EQUIPITEM_SOURCE,0);
		EQUIPITEM_SOURCE = -1
	end
	for i=2,5 do 
		GEMSOURCE_BUTTONS[i]:SetActionItem(-1);
	end
	if (EQUIPITEM_DEST ~= -1) then
		GEMDEST_BUTTONS[1]:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(EQUIPITEM_DEST,0);
		EQUIPITEM_DEST = -1
	end
	for i=2,5 do 
		GEMDEST_BUTTONS[i]:SetActionItem(-1);
	end
	--if (EQUIPITEM_QIANKUNFU ~= -1) then
	--	QIANKUNFU_BUTTON:SetActionItem(-1);
	--	LifeAbility : Lock_Packet_Item(EQUIPITEM_QIANKUNFU,0);
	--	EQUIPITEM_QIANKUNFU = -1
	--end
	bConfirm = -1
end

function EquipBaoshiyi_Update(UI_index, Item_index)
	local i_index = tonumber(Item_index)
	local ui_index = tonumber(UI_index)
	if ui_index < 0 or ui_index > 2 then
		return
	end
	local theAction = EnumAction(i_index, "packageitem");
	
	EquipBaoshiyi_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	EquipBaoshiyi_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	local uiPos = -1;
	local gem_count = 0
	if ui_index ~= 3 then
		gem_count = LifeAbility : GetEquip_GemCount(i_index);
		if gem_count > 4 or gem_count == -1 then
			return
		end
		bConfirm = -1
		g_bClick = 0
		EquipBaoshiyi_zhuanyi : SetText("#{BSQKY_20110506_05}")
		--时装不能操作
		local equippoint = LifeAbility : Get_Equip_Point(i_index);
		if (not g_EquipGemTable[equippoint]) or (equippoint == 16) then
			PushDebugMessage("#{BSQKY_20110506_30}")
			return
		end
		
		--宗门装备暂时关闭
		if equippoint == 23 then
			PushDebugMessage("#{XWXT_230825_22}")
			return
		end
	end
	if theAction:GetID() ~= 0 then
		--重楼不能操作
		--liubo2012.8.24 TT121918 重楼可以操作了
		--if PlayerPackage : GetItemTableIndex( i_index ) == 10420088 or
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10420089 or
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10420090 or
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10422016 or
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10422149 or
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10422150 or
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10422155 or
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10423024 or 
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10423025 or 
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10423026 or 
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10423064 or
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10420093 or		--新增不绑定的真重楼链，虽然被注释了，也写上吧；这种注释掉的代码逻辑，千万别放开，后续又增加了很多重楼ID的
		--	 PlayerPackage : GetItemTableIndex( i_index ) == 10420091 then
		--		PushDebugMessage("#{BSQKY_20110506_29}")
		--		return
		--end
		if ui_index == 0 then
			if EQUIPITEM_SOURCE == -1 then
				if gem_count < 1 then
					PushDebugMessage("#{BSQKY_20110506_13}")
					return
				end
				GEMSOURCE_BUTTONS[1]:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(i_index,1);
				EQUIPITEM_SOURCE = i_index;
				uiPos = 1;
				--return
			--end
			else
				if EQUIPITEM_DEST ~= -1 then
					LifeAbility : Lock_Packet_Item(EQUIPITEM_DEST,0);
				end
				GEMDEST_BUTTONS[1]:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(i_index,1);
				EQUIPITEM_DEST = i_index;
				uiPos = 2;
			end
		elseif ui_index == 1 then
			if gem_count < 1 then
				PushDebugMessage("#{BSQKY_20110506_13}")
				return
			end
			if EQUIPITEM_SOURCE ~= -1 then
				LifeAbility : Lock_Packet_Item(EQUIPITEM_SOURCE,0);
			end
			GEMSOURCE_BUTTONS[1]:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(i_index,1);
			EQUIPITEM_SOURCE = i_index;
			uiPos = 1;
		elseif ui_index == 2 then
			if EQUIPITEM_DEST ~= -1 then
				LifeAbility : Lock_Packet_Item(EQUIPITEM_DEST,0);
			end
			GEMDEST_BUTTONS[1]:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(i_index,1);
			EQUIPITEM_DEST = i_index;
			uiPos = 2;
		--elseif ui_index == 3 then--宝石乾坤符
		--	if PlayerPackage : GetItemTableIndex( i_index ) ~= 30900104 then
		--		PushDebugMessage("#{BSQKY_20110506_26}")
		--		return
		--	end
			
		--	if EQUIPITEM_QIANKUNFU ~= -1 then
		--			LifeAbility : Lock_Packet_Item(EQUIPITEM_QIANKUNFU,0);
		--	end
		--	QIANKUNFU_BUTTON:SetActionItem(theAction:GetID());
		--	LifeAbility : Lock_Packet_Item(i_index,1);
		--	EQUIPITEM_QIANKUNFU = i_index
		end
		EquipBaoshiyi_NeedMoney:SetProperty("MoneyNumber", tostring(100000));
		if uiPos == 1 then--和宝石摘除共用一套实现
			if not LifeAbility:SplitGem_Update(i_index) then
				for i=1,4 do
					GEMSOURCE_BUTTONS[i+1] : SetActionItem(-1)
					GEMSOURCE_BUTTONS[i+1] : Gloom();
				end
			else
				local ActionID,nItemID
				--local needFu = 0;
				for i=1,4 do
					nItemID = LifeAbility : GetSplitGem_Gem (i-1);
					if nItemID ~= -1 then
						ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
						GEMSOURCE_BUTTONS[i+1] : SetActionItem(ActionID);
						--GEMSOURCE_BUTTONS[i+1] : Gloom();
						--local gemLevel = LifeAbility : GetEquip_GemLevel(EQUIPITEM_SOURCE, i -1)
						--if gemLevel > 0 and gemLevel < 10 then
							--needFu = needFu + g_GemLevelTable[gemLevel]
						--end
						--if needFu > 0 then
							--local Msg = string.format( "#{BSQKY_20110506_37}%d#{BSQKY_20110506_38}", tonumber(needFu))
							--EquipBaoshiyi_SpecialM_Info : SetText(Msg)
							--g_needFu = needFu
						--end
					else
						GEMSOURCE_BUTTONS[i+1] : SetActionItem(-1)
						GEMSOURCE_BUTTONS[i+1] : Gloom();
					end
				end
				--for i=gem_count+1,4 do
				--	GEMSOURCE_BUTTONS[i+1] : SetActionItem(-1)
				--	GEMSOURCE_BUTTONS[i+1] : Gloom();
				--end
			end
			if EQUIPITEM_DEST ~= -1 then
				if not LifeAbility:Baoshiyi_Update(EQUIPITEM_DEST) then
					for i=1,4 do
						GEMDEST_BUTTONS[i+1] : SetActionItem(-1)
						GEMDEST_BUTTONS[i+1] : Gloom();
					end
				else
					local ActionID,nItemID
			
					for i=1,4 do
						nItemID = LifeAbility : Baoshiyi_Gem (i-1);
						if nItemID ~= -1 then
							ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
							GEMDEST_BUTTONS[i+1] : SetActionItem(ActionID);
							GEMDEST_BUTTONS[i+1] : Bright();
						else
							GEMDEST_BUTTONS[i+1] : SetActionItem(-1)
							GEMDEST_BUTTONS[i+1] : Gloom();
						end
					end
					--for i=gem_count+1,4 do
					--	GEMDEST_BUTTONS[i+1] : SetActionItem(-1)
					--	GEMDEST_BUTTONS[i+1] : Gloom();
					--end
				end
			end
		elseif uiPos == 2 then--这里用自己实现的一套
			if not LifeAbility:Baoshiyi_Update(i_index) then
				for i=1,4 do
					GEMDEST_BUTTONS[i+1] : SetActionItem(-1)
					GEMDEST_BUTTONS[i+1] : Gloom();
				end
			else
				local ActionID,nItemID
		
				for i=1,4 do
					nItemID = LifeAbility : Baoshiyi_Gem (i-1);
					if nItemID ~= -1 then
						ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
						GEMDEST_BUTTONS[i+1] : SetActionItem(ActionID);
						GEMDEST_BUTTONS[i+1] : Bright();
					else
						GEMDEST_BUTTONS[i+1] : SetActionItem(-1)
						GEMDEST_BUTTONS[i+1] : Gloom();
					end
				end
				--for i=gem_count+1,4 do
				--	GEMDEST_BUTTONS[i+1] : SetActionItem(-1)
				--	GEMDEST_BUTTONS[i+1] : Gloom();
				--end
			end
			if EQUIPITEM_SOURCE ~= -1 then
				if not LifeAbility:SplitGem_Update(EQUIPITEM_SOURCE) then
					for i=1,4 do
						GEMSOURCE_BUTTONS[i+1] : SetActionItem(-1)
						GEMSOURCE_BUTTONS[i+1] : Gloom();
					end
				else
					local ActionID,nItemID
			
					for i=1,4 do
						nItemID = LifeAbility : GetSplitGem_Gem (i-1);
						if nItemID ~= -1 then
							ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
							GEMSOURCE_BUTTONS[i+1] : SetActionItem(ActionID);
							--GEMSOURCE_BUTTONS[i+1] : Gloom();
						else
							GEMSOURCE_BUTTONS[i+1] : SetActionItem(-1)
							GEMSOURCE_BUTTONS[i+1] : Gloom();
						end
					end
					--for i=gem_count+1,4 do
					--	GEMSOURCE_BUTTONS[i+1] : SetActionItem(-1)
					--	GEMSOURCE_BUTTONS[i+1] : Gloom();
					--end
				end
			end
		end
	else
	end

end

function EquipBaoshiyi_Resume_Equip(nIndex)
	if nIndex < 1 or nIndex > 3 then
		return
	end
	EquipBaoshiyi_NeedMoney:SetProperty("MoneyNumber", tostring(0));
	--EquipBaoshiyi_huifu : Disable()
	--EquipBaoshiyi_zhuanyi : Enable()
	if nIndex == 1 and (EQUIPITEM_SOURCE ~= -1) then
		GEMSOURCE_BUTTONS[1]:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(EQUIPITEM_SOURCE,0);
		EQUIPITEM_SOURCE = -1
		for i=2,5 do 
			GEMSOURCE_BUTTONS[i]:SetActionItem(-1);
		end
		if EQUIPITEM_DEST ~= -1 then
			EquipBaoshiyi_Update(2, EQUIPITEM_DEST)
		end
		g_bClick = 0
		EquipBaoshiyi_zhuanyi : SetText("#{BSQKY_20110506_05}")
		--EquipBaoshiyi_SpecialM_Info : SetText("#{BSQKY_20110506_36}")
	elseif nIndex == 2 and (EQUIPITEM_DEST ~= -1) then
		GEMDEST_BUTTONS[1]:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(EQUIPITEM_DEST,0);
		EQUIPITEM_DEST = -1
		for i=2,5 do 
			GEMDEST_BUTTONS[i]:SetActionItem(-1);
		end
		if EQUIPITEM_SOURCE ~= -1 then
			EquipBaoshiyi_Update(1, EQUIPITEM_SOURCE)
		end
		g_bClick = 0
		EquipBaoshiyi_zhuanyi : SetText("#{BSQKY_20110506_05}")
	--elseif nIndex == 3 and (EQUIPITEM_QIANKUNFU ~= -1) then
	--	QIANKUNFU_BUTTON:SetActionItem(-1);
	--	LifeAbility : Lock_Packet_Item(EQUIPITEM_QIANKUNFU,0);
	--	EQUIPITEM_QIANKUNFU = -1
	end
end

function EquipBaoshiyi_UpdateButton()
	local ActionID,nItemID
	for i=1,4 do
		nItemID = LifeAbility : GetSplitGem_Gem (i-1);
		if nItemID ~= -1 then
			ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
			if ActionID and ActionID ~= -1 then
				GEMSOURCE_BUTTONS[i+1] : SetActionItem(ActionID);
			end
		else
			GEMSOURCE_BUTTONS[i+1] : SetActionItem(-1)
			GEMSOURCE_BUTTONS[i+1] : Gloom();
		end
	end
	for i=1,4 do
		nItemID = LifeAbility : Baoshiyi_Gem(i-1);
		if nItemID ~= -1 then
			ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
			if ActionID and ActionID ~= -1 then
				GEMDEST_BUTTONS[i+1] : SetActionItem(ActionID);
				GEMDEST_BUTTONS[i+1] : Bright();
			end
		else
			GEMDEST_BUTTONS[i+1] : SetActionItem(-1)
			GEMDEST_BUTTONS[i+1] : Gloom();
		end
	end
end
function EquipBaoshiyi_Check()
	if EQUIPITEM_SOURCE == -1 then
		PushDebugMessage("#{BSQKY_20110506_04}")
		return 0
	end
	if EQUIPITEM_DEST == -1 then
		PushDebugMessage("#{BSQKY_20110506_08}")
		return 0
	end
	--if EQUIPITEM_QIANKUNFU == -1 then
	--	PushDebugMessage("#{BSQKY_20110506_26}")
	--	return 0
	--end
	--if PlayerPackage:GetBagItemNum(EQUIPITEM_QIANKUNFU) < g_needFu then
	--if PlayerPackage:CountAvailableItemByIDTable(tonumber(EQUIPITEM_QIANKUNFU)) < g_needFu then
	--	PushDebugMessage("#{BSQKY_20110506_39}")
	--	return 0
	--end
	
	local equippointSrc = LifeAbility : Get_Equip_Point(EQUIPITEM_SOURCE);
	if (not g_EquipGemTable[equippointSrc]) or (equippointSrc == 16) then
		PushDebugMessage("#{BSQKY_20110506_30}")
		return
	end
	local equippointDst = LifeAbility : Get_Equip_Point(EQUIPITEM_DEST);
	if (not g_EquipGemTable[equippointDst]) or (equippointDst == 16) then
		PushDebugMessage("#{BSQKY_20110506_30}")
		return
	end
	
	local gem_count = LifeAbility : GetEquip_GemCount(EQUIPITEM_SOURCE);
	if gem_count > 4 then
		return 0
	end
	local hole_count = LifeAbility : GetEquip_HoleCount(EQUIPITEM_DEST);
	local gemdest_count = LifeAbility : GetEquip_GemCount(EQUIPITEM_DEST);
	
	local nItemIDSrc = -1
	local nItemIDDest = -1
	for i=1,4 do
		nItemIDSrc = LifeAbility : GetSplitGem_Gem (i-1);
		nItemIDDest = LifeAbility : Baoshiyi_Gem (i-1);
		if (nItemIDSrc ~= -1) then
			if (i > hole_count) then
				PushDebugMessage("#{BSQKY_20110506_16}")
				return 0
			end
			if nItemIDDest ~= -1 then
				PushDebugMessage("#{BSQKY_20110506_17}")
				return 0
			end
			-- 这里需要调整一下, 只需要判断EquipSrc的前三个孔和EquipDest的前三个孔是否有重复
			local gemType = LifeAbility : Baoshiyi_GetGemType(EQUIPITEM_SOURCE, i-1)
			if ( i < 4 ) then
				local cando = LifeAbility : Can_Enchase(EQUIPITEM_DEST, i - 1);--nItemIDSrc
				if cando == false then
					PushDebugMessage("#{BSQKY_20110506_18}")
					return 0
				end
				-- 得考虑目标装备实际打孔数量, 可能没有打够前3个
				local nMaxSlot = math.min( 3, hole_count );
				for k=1, nMaxSlot do
					local gemTypeDst = LifeAbility : Baoshiyi_GetGemType(EQUIPITEM_DEST, k-1)
					if gemTypeDst ~= -1 and gemTypeDst == gemType then
						PushDebugMessage("#{BSQKY_20110506_19}")
						return 0
					end
				end
				--PushDebugMessage(tostring(gemType)..tostring(equippointDst))
				local passFlag = 0
				for i, gt in g_EquipGemTable[equippointDst] do
					if gt == gemType then
						passFlag = 1
						break
					end
				end
				--PushDebugMessage(tostring(passFlag)..tostring(equippointDst))
				if passFlag == 0 then
					PushDebugMessage("#{BSQKY_20110506_18}")
					return 0
				end
			end
		end
	end
	if hole_count - gemdest_count < gem_count then--目标装备的剩余孔数不能小于源装备上的宝石数量
		PushDebugMessage("#{BSQKY_20110506_16}")
		return 0
	end
	return 1
end
function EquipBaoshiyi_Zhuanyi_Clicked()
	if g_bClick ~= 1 then
		if EquipBaoshiyi_Check() ~= 1 then
			return
		end
		for i=1,4 do
			LifeAbility : Baoshiyi_SetGemByIndex(i-1, i-1, 0)
		end
		EquipBaoshiyi_UpdateButton()
		--EquipBaoshiyi_huifu : Enable()
		--EquipBaoshiyi_zhuanyi : Disable()
		EquipBaoshiyi_zhuanyi : SetText("#{BSQKY_20110506_06}")
		g_bClick = 1
	else
		EquipBaoshiyi_zhuanyi : SetText("#{BSQKY_20110506_05}")
		EquipBaoshiyi_Update(1, EQUIPITEM_SOURCE)
		EquipBaoshiyi_Update(2, EQUIPITEM_DEST)
		g_bClick = 0
	end
end

function EquipBaoshiyi_Huifu_Clicked()
	if EQUIPITEM_SOURCE == -1 then
		EquipBaoshiyi_huifu : Disable()
		return
	end
	local gem_count = LifeAbility : GetEquip_GemCount(EQUIPITEM_SOURCE);
	if gem_count > 4 then
		EquipBaoshiyi_huifu : Disable()
		return
	end
	--for i=1,4 do
	--	LifeAbility : Baoshiyi_SetGemByIndex(i-1, i-1, 1)
	--end
	--EquipBaoshiyi_UpdateButton()
	EquipBaoshiyi_Update(1, EQUIPITEM_SOURCE)
	EquipBaoshiyi_Update(2, EQUIPITEM_DEST)
	EquipBaoshiyi_huifu : Disable()
	EquipBaoshiyi_zhuanyi : Enable()
end

function EquipBaoshiyi_Buttons_Clicked()

	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	if EquipBaoshiyi_Check() ~= 1 then
		return
	end
	--if EQUIPITEM_QIANKUNFU == -1 then
	--	PushDebugMessage("#{BSQKY_20110506_26}")
	--	return
	--end
--	if PlayerPackage:CountAvailableItemByIDTable(tonumber(EQUIPITEM_QIANKUNFU)) + PlayerPackage:CountAvailableItemByIDTable(30900114) < g_needFu then
--		local bCheck_Test = EquipBaoshiyi_Check_Yuanbao:GetCheck()
--		Clear_XSCRIPT()
--					Set_XSCRIPT_Function_Name("Baoshiyi_Yuanbao_Pay")
--					Set_XSCRIPT_ScriptID(311200)
--					Set_XSCRIPT_Parameter(0,EQUIPITEM_QIANKUNFU)
--					Set_XSCRIPT_Parameter(1,bCheck_Test)
--					Set_XSCRIPT_Parameter(2,g_needFu)
--					Set_XSCRIPT_ParamCount(3)
--				Send_XSCRIPT()
--		return 0
--	end
	if bConfirm == -1 then
		local equipTableIndex = PlayerPackage : GetItemTableIndex( EQUIPITEM_DEST )
		if IsUnbindChongLouEquip(equipTableIndex) == 1 then
			PushEvent("DISPLACEGEM_CONFIRM", 26,1)--弹出确认框
		else
			PushEvent("DISPLACEGEM_CONFIRM", 26,0)--弹出确认框
		end
		bConfirm = 1
	elseif bConfirm == 1 then
		--LifeAbility : Do_Displace(EQUIPITEM_SOURCE,EQUIPITEM_DEST,EQUIPITEM_QIANKUNFU)
		LifeAbility : Do_Displace(EQUIPITEM_SOURCE,EQUIPITEM_DEST, 0) --2015 VIP随身移功能 By YuanPeiLong
		bConfirm = -1
	end
	--LifeAbility : Do_Displace(EQUIPITEM_SOURCE,EQUIPITEM_DEST,EQUIPITEM_QIANKUNFU)
	--EquipBaoshiyi_Close()
	--EquipBaoshiyi_Clear()
end

function EquipBaoshiyi_Close()
	EquipBaoshiyi_Clear()
	PushEvent("DISPLACE_CLOSE_MSGBOX");
	this:Hide()
end

function EquipBaoshiyi_Cancel_Clicked()
	EquipBaoshiyi_Close();
	return;
end

function EquipBaoshiyi_OnHidden()
	StopCareObject_EquipBaoshiyi(objCared)
	EquipBaoshiyi_Close()
	return
end
--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_EquipBaoshiyi(objCaredId)

	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "EquipBaoshiyi");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_EquipBaoshiyi(objCaredId)
	this:CareObject(objCaredId, 0, "EquipBaoshiyi");
	g_Object = -1;

end

function EquipBaoshiyi_IsBind( ItemID )

	if(GetItemBindStatus(ItemID) == 1) then
		return 1;
	else
		return 0;
	end
end

function EquipBaoshiyi_Frame_On_ResetPos()
  EquipBaoshiyi_Frame:SetProperty("UnifiedPosition", g_EquipBaoshiyi_Frame_UnifiedPosition);
end

