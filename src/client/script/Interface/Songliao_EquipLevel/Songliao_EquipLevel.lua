--六博装备升星界面

local g_objCared = -1
local MAX_OBJ_DISTANCE = 3.0
local g_uiEquipMainPos = -1 --主装备
local g_uiEquipSubPos = -1 --辅装备
local g_LastMainEquip = -1
local g_LastSubEquip = -1

function Songliao_EquipLevel_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("PROGRESSBAR_SHOW")
	this:RegisterEvent("OPEN_STALL_SALE")
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("UPDATE_LIUBOEQUIP_STARUP")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)--这个为了把物品从UI上拖下来：CUISystem::OnDragEnd
end

function Songliao_EquipLevel_OnLoad()
	g_objCared = -1
	g_uiEquipMainPos = -1 
	g_uiEquipSubPos = -1 
	g_LastMainEquip = -1
	g_LastSubEquip = -1
end

function Songliao_EquipLevel_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0)==5020231) then
		this:Show()
		Songliao_EquipLevel_Clear()
		g_objCared = -1
		local param = Get_XParam_INT(0)
		g_objCared = DataPool : GetNPCIDByServerID(param)
		if g_objCared == -1 then				
				return;
		end
		
		--关心NPC
		Songliao_EquipLevel_BeginCareNPC(g_objCared)
		return
	elseif (event == "MONEY_CHANGE_EX") then
		Songliao_EquipLevel_SelfMoney:SetProperty("MoneyNumber",  tostring(Player:GetData("MONEY")))
		return
		
	elseif (event == "MONEYJZ_CHANGE_EX") then
		Songliao_EquipLevel_SelfJiaozi:SetProperty("MoneyNumber",  tostring(Player:GetData("MONEY_JZ")))		
		return
		
	elseif(event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Songliao_EquipLevel_Close()
		end
		return
	elseif(event == "UPDATE_LIUBOEQUIP_STARUP") then
		Songliao_EquipLevel_Update(tonumber(arg0), tonumber(arg1))
		return 
	elseif(event == "RESUME_ENCHASE_GEM_EX") then
		if(arg0~=nil and (tonumber(arg0) == 32 or tonumber(arg0) == 33)) then
			Songliao_EquipLevel_Resume(tonumber(arg0))
		end
		return
	end

end

function Songliao_EquipLevel_Close()
	Songliao_EquipLevel_Clear()
	this:CareObject(g_objCared, 0, "Songliao_EquipLevel")
	g_objCared = -1
	this:Hide()
end


function Songliao_EquipLevel_BeginCareNPC(npcId)
	g_objCared = npcId
	this:CareObject(npcId, 1, "Songliao_EquipLevel")
end

function Songliao_EquipLevel_Cancel_Clicked()
	Songliao_EquipLevel_Clear()
	this:Hide()
end

function Songliao_EquipLevel_OK_Clicked()
	if g_uiEquipMainPos == -1 or g_uiEquipSubPos == -1 then
		PushDebugMessage("#{SLDZ_100805_109}")
		return
	end
	
	local notify = 0
	if g_LastMainEquip ~= g_uiEquipMainPos or g_LastSubEquip ~= g_uiEquipSubPos then
		g_LastMainEquip = g_uiEquipMainPos
		g_LastSubEquip = g_uiEquipSubPos
		notify = 1
	end
	
	if notify == 1 then
		DressEnchasing:Dress_EnchaseShowInfo("SLDZ_100805_218")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnLiuboEquipStarup")
		Set_XSCRIPT_ScriptID(502024)
		Set_XSCRIPT_Parameter(0,g_uiEquipMainPos)
		Set_XSCRIPT_Parameter(1,g_uiEquipSubPos)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
		
	Songliao_EquipLevel_Clear()
end

function Songliao_EquipLevel_Clear()
	if g_uiEquipMainPos~=-1 then
		LifeAbility : Lock_Packet_Item(g_uiEquipMainPos,0);
		g_uiEquipMainPos = -1
		Songliao_EquipLevel_Object1:SetActionItem(-1)
		Songliao_EquipLevel_OK:Disable()
		Songliao_EquipLevel_NeedMoney:SetProperty("MoneyNumber", 0)
	end
	
	if g_uiEquipSubPos ~= -1 then
		LifeAbility : Lock_Packet_Item(g_uiEquipSubPos,0);
		g_uiEquipSubPos = -1
		Songliao_EquipLevel_Object2:SetActionItem(-1)
		Songliao_EquipLevel_OK:Disable()
		Songliao_EquipLevel_NeedMoney:SetProperty("MoneyNumber", 0)
	end
	g_LastMainEquip = -1
	g_LastSubEquip = -1
end

function Songliao_EquipLevel_Resume(index)
	if index~=32 and index~=33 then
		return
	end
	
	if this:IsVisible() then
		if index == 32 and g_uiEquipMainPos~=-1 then
			LifeAbility : Lock_Packet_Item(g_uiEquipMainPos,0);
			g_uiEquipMainPos = -1
			Songliao_EquipLevel_Object1:SetActionItem(-1)
			Songliao_EquipLevel_OK:Disable()
			Songliao_EquipLevel_NeedMoney:SetProperty("MoneyNumber", 0)
		elseif index == 33 and g_uiEquipSubPos ~= -1 then
			LifeAbility : Lock_Packet_Item(g_uiEquipSubPos,0);
			g_uiEquipSubPos = -1
			Songliao_EquipLevel_Object2:SetActionItem(-1)
			Songliao_EquipLevel_OK:Disable()
			Songliao_EquipLevel_NeedMoney:SetProperty("MoneyNumber", 0)
		end
	end
end

function Songliao_EquipLevel_Update(uiIndex, itemPos)
	if g_uiEquipMainPos~=-1 and g_uiEquipSubPos~=-1 then
		-- 两个位置都已经放入装备了
		-- PushDebugMessage("")
		return
	end
	
	-- 加锁判断
	if 1 == PlayerPackage:IsLock( itemPos ) == 1 then
		PushDebugMessage("#{BSLCYH_130529_20}")
		return
	end

	local theActionItem = EnumAction(itemPos, "packageitem")
	local needMoney = 0
	local isLiuboEquip = 0
	isLiuboEquip, needMoney = CSongliaoWarData:GetLiuboEquipStarUpInfo(PlayerPackage : GetItemTableIndex( itemPos ) )
	if isLiuboEquip~=nil and isLiuboEquip==1 and needMoney~=nil then
		-- 六星六博的升级金钱为负数 新增逻辑
		if needMoney <= 0 then
			PushDebugMessage("#{SLDZ_100805_117}")
			return
		end
		
		-- 主装备逻辑
		if g_uiEquipMainPos==-1 then
			if(g_uiEquipSubPos~=-1) then
				local itemIndex = PlayerPackage : GetItemTableIndex( itemPos )
				local subEquipIndex = PlayerPackage : GetItemTableIndex( g_uiEquipSubPos )
				if math.floor(itemIndex/10) ~= math.floor(subEquipIndex/10) then
					PushDebugMessage("#{SLDZ_100805_109}")
					return
				end
			end
			g_uiEquipMainPos = itemPos
			LifeAbility : Lock_Packet_Item(g_uiEquipMainPos,1)
			Songliao_EquipLevel_Object1:SetActionItem(theActionItem:GetID())
		else
		-- 辅助装备逻辑
			if g_uiEquipSubPos==-1 then
			
				-- 辅助装备是否有宝石、强化、雕纹、铭刻 新增逻辑
				local bSp = 0
				
				-- 镶嵌有宝石的不能作为合成材料
				local nGemCount = LifeAbility : GetEquip_GemCount( itemPos )
				if nGemCount ~= nil and nGemCount > 0 then
					bSp = 1
				end

				-- 有雕纹的不能作为材料
				local bHaveDiaowen = LifeAbility : IsEquipHaveDiaowen( itemPos )
				if bHaveDiaowen > 0 then
					bSp = 1
				end
				
				-- 强化等级
				local nCurStrengthLevel = LifeAbility : Get_Equip_CurStrengthLevel(itemPos)
				if nCurStrengthLevel > 0 then
					bSp = 1
				end
				
				-- 铭刻
				-- if 1 == DataPool:IsSelfEquipLocked(itemPos) then
					-- bSp = 1
				-- end
				
				if 1 == bSp then
					-- PushDebugMessage("带有宝石、雕纹、强化，刻蚀的装备不能作为材料来提升主装备星级。")
					PushDebugMessage("#{SLDZ_181110_02}")
					return
				end
				
				if(g_uiEquipMainPos~=-1) then
					local itemIndex = PlayerPackage : GetItemTableIndex( itemPos )
					local mainEquipIndex = PlayerPackage : GetItemTableIndex( g_uiEquipMainPos )
					if math.floor(itemIndex/10) ~= math.floor(mainEquipIndex/10) then
						PushDebugMessage("#{SLDZ_100805_109}")
						return
					end
				end
				g_uiEquipSubPos = itemPos
				LifeAbility : Lock_Packet_Item(g_uiEquipSubPos,1)
				Songliao_EquipLevel_Object2:SetActionItem(theActionItem:GetID())
			end			
		end
		
		if g_uiEquipMainPos ~= -1 and g_uiEquipSubPos ~= -1 then
			Songliao_EquipLevel_OK:Enable()
			Songliao_EquipLevel_NeedMoney:SetProperty("MoneyNumber", needMoney)
		end
	else
		-- PushDebugMessage("该装备不可升星，请放入需要升级的六博装备")
		PushDebugMessage("#{SLDZ_181110_01}")
	end
end

function Songliao_EquipLevel_OnShown()
	Songliao_EquipLevel_Clear()
	Songliao_EquipLevel_SelfMoney:SetProperty("MoneyNumber",  tostring(Player:GetData("MONEY")))
	Songliao_EquipLevel_SelfJiaozi:SetProperty("MoneyNumber",  tostring(Player:GetData("MONEY_JZ")))
end
