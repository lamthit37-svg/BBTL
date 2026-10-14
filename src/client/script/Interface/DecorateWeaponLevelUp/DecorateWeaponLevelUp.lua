
local g_DecorateWeaponLevelUp_Frame_UnifiedPosition;
local g_WeaponBagPos = -1
local g_SourceDecoWeaponId = -1
local g_clientNpcId = -1
local g_DestDecoWeaponLevelId = {}
local g_curSelectId = -1

local g_DecorateWeaponLevelUp_YuanBaoPay = 1

function DecorateWeaponLevelUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	this:RegisterEvent("DECOWEAPON_LEVELUP_REMOVE_EQUIP")
	
	this:RegisterEvent("UPDATE_DECOWEAPON_LEVELUP")
	this:RegisterEvent("FAKEOBJ_MYSELFEQUIP_CHANGE", false)
end

function DecorateWeaponLevelUp_OnLoad() 
	g_DecorateWeaponLevelUp_Frame_UnifiedPosition = DecorateWeaponLevelUp_Frame:GetProperty("UnifiedPosition");
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
	
	g_DecorateWeaponLevelUp_YuanBaoPay = 1;
end

function DecorateWeaponLevelUp_OnEvent(event) 
	if (event == "ADJEST_UI_POS" ) then
		DecorateWeaponLevelUp_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DecorateWeaponLevelUp_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DecorateWeaponLevelUp_OnHiden()
		
	elseif (event == "MONEY_CHANGE_EX") then
		local playerMoney = Player:GetData("MONEY")
		DecorateWeaponLevelUp_SelfMoney:SetProperty("MoneyNumber", playerMoney)
		
	elseif (event == "MONEYJZ_CHANGE_EX") then
		local playerJZ = Player:GetData("MONEY_JZ")
		DecorateWeaponLevelUp_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
		
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 891788 then
	
		PushEvent( "CLOSE_DRESSPREVIEW")
		PushEvent( "CLOSE_GEMEFFECTPREVIEW") 
		
		local Type = Get_XParam_INT(0)
		if Type == 1 then       --打开界面
			if this : IsVisible() then									-- 如果界面开着，则不处理
				return
			end
		
			
			local npcObjId = Get_XParam_INT(1)
			g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
			if g_clientNpcId == -1 then
				PushDebugMessage("未发现 NPC")
				DecorateWeapon_OnHiden()
				return
			end
			
		
			this:CareObject( g_clientNpcId, 1, "DecorateWeaponLevelUp" )
			
			DecorateWeaponLevelUp_FakeObject:AttachWindowEx("DecoWeapon_Player")
			SetFakeObjDataEx("DecoWeapon_Player")
			
			DecorateWeaponLevelUp_Init()
			if g_DecorateWeaponLevelUp_YuanBaoPay == 1 or g_DecorateWeaponLevelUp_YuanBaoPay == 0 then
				DecorateWeaponLevelUp_YuanBaoPay:SetCheck(g_DecorateWeaponLevelUp_YuanBaoPay)
			end
			this:Show()
		elseif Type == 2 then	--刷新界面
			DecorateWeaponLevelUp_Update(Get_XParam_INT(1))
		elseif Type == 3 then --升到满级
			DecorateWeaponLevelUp_Init()
		elseif Type == 4 then --发送二次确认框
			PushEvent( "DECOWEAPON_LEVELUP_CONFIRM", g_WeaponBagPos )
		end
		
	elseif event == "UPDATE_DECOWEAPON_LEVELUP" then
		if tonumber(arg0) == 1 then   --放入武器
			DecorateWeaponLevelUp_Update(tonumber(arg1))
		end
	elseif event == "DECOWEAPON_LEVELUP_REMOVE_EQUIP" then
		DecorateWeaponLevelUp_Resume_Equip()
		
	elseif event == "FAKEOBJ_MYSELFEQUIP_CHANGE" then
		SetFakeObjDataEx("DecoWeapon_Player")
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(g_curSelectId)
	end
	
		-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			DecorateWeaponLevelup_ResetData()
			this:CareObject( g_clientNpcId, 0, "DecorateWeaponLevelUp" )
			g_clientNpcId = -1
			DecorateWeaponLevelUp_FakeObject:DetachWindowEx("DecoWeapon_Player")
			
			g_DecorateWeaponLevelUp_YuanBaoPay = DecorateWeaponLevelUp_YuanBaoPay:GetCheck();
			this:Hide()
		end
	end		
	
end

function DecorateWeaponLevelUp_Frame_On_ResetPos()
  DecorateWeaponLevelUp_Frame:SetProperty("UnifiedPosition", g_DecorateWeaponLevelUp_Frame_UnifiedPosition);
end

function DecorateWeaponLevelup_ResetData()
	if g_WeaponBagPos ~= -1 then
		LifeAbility:Lock_Packet_Item(g_WeaponBagPos, 0)
		g_WeaponBagPos = -1
	end
	
	g_SourceDecoWeaponId = -1
	
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
end

function DecorateWeaponLevelUp_Init()
	DecorateWeaponLevelup_ResetData()
	
	DecorateWeaponLevelUp_ALLChoice:Disable()
	DecorateWeaponLevelUp_ALLChoice:SetText("#{DECOW_160126_44}")
	
	DecorateWeaponLevelUp_DemandMoney:SetProperty("MoneyNumber", 0)
	local playerMoney = Player:GetData("MONEY")
	DecorateWeaponLevelUp_SelfMoney:SetProperty("MoneyNumber", playerMoney)
	local playerJZ = Player:GetData("MONEY_JZ")
	DecorateWeaponLevelUp_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
	
	DecorateWeaponLevelUp_LevelInfo:SetText("")
	DecorateWeaponLevelUp_NeedNameInfo:SetText("")
	DecorateWeaponLevelUp_NeedNumberInfo:SetText("")
	
	DecorateWeaponLevelUp_Object1:SetActionItem(-1)
	DecorateWeaponLevelUp_Object1:SetToolTip("#{DECOW_160126_90}")
	DecorateWeaponLevelUp_OK:Disable()
end

function DecorateWeaponLevelUp_Update(WeaponBagPos)
	DecorateWeaponLevelup_ResetData()
	DecorateWeaponLevelUp_Object1:SetActionItem(-1)
	DecorateWeaponLevelUp_Object1:SetToolTip("#{DECOW_160126_90}")
	
	local theAction = EnumAction(WeaponBagPos, "packageitem")
	if theAction:GetID() ~= 0 then
		local NextLevel, DestDecoWeaponId, costMoneyNum, BindItemId, ItemId, NeedNum = DecoWeaponUI:GetDecoWeaponLevelData(WeaponBagPos)
		if NextLevel == -1 then
			return 
		end
	
		g_WeaponBagPos = WeaponBagPos
		
		LifeAbility:Lock_Packet_Item(g_WeaponBagPos, 1)
		DecorateWeaponLevelUp_Object1:SetActionItem(theAction:GetID())

		g_SourceDecoWeaponId = PlayerPackage:GetItemTableIndex(WeaponBagPos)	
		
		DecorateWeaponLevelUp_ALLChoice_Init(NextLevel)
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(DestDecoWeaponId)
		g_curSelectId = DestDecoWeaponId
		
		DecorateWeaponLevelUp_DemandMoney:SetProperty("MoneyNumber", costMoneyNum)
		DecorateWeaponLevelUp_LevelInfo:SetText(tostring(NextLevel-1))
		DecorateWeaponLevelUp_NeedNameInfo:SetText(PlayerPackage:GetItemName(BindItemId))
		DecorateWeaponLevelUp_NeedNumberInfo:SetText(tostring(NeedNum))
		DecorateWeaponLevelUp_OK:Enable()
	end
end

function DecorateWeaponLevelUp_ALLChoice_Init(level)
	local WeaponName = {}
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
	
	g_DestDecoWeaponLevelId[1], WeaponName[1], g_DestDecoWeaponLevelId[2], WeaponName[2], 
	g_DestDecoWeaponLevelId[3], WeaponName[3], g_DestDecoWeaponLevelId[4], WeaponName[4],
	g_DestDecoWeaponLevelId[5], WeaponName[5]= DecoWeaponUI:GetDecoWeaponLevelInfo(g_SourceDecoWeaponId)
	if name1 == -1 then
		return
	end
	
	DecorateWeaponLevelUp_ALLChoice:ResetList()
	
	for i=1 ,5 do
		WeaponName[i] = ScriptGlobal_Format("#{DECOW_160126_8}", WeaponName[i])
	end 
	 	
	if level > 0 and level < 6 then
		DecorateWeaponLevelUp_ALLChoice:SetText(WeaponName[level])
	end
	
	for i = 1 , 5 do 
		DecorateWeaponLevelUp_ALLChoice:AddTextItem(WeaponName[i] ,i) 
	end 
	
	DecorateWeaponLevelUp_ALLChoice:Enable() 
end

function DecorateWeaponLevelUp_OnHiden()
	DecorateWeaponLevelup_ResetData()
	
	this:CareObject( g_clientNpcId, 0, "DecorateWeaponLevelUp" )
	g_clientNpcId = -1
	DecorateWeaponLevelUp_FakeObject:DetachWindowEx("DecoWeapon_Player")
	
	g_DecorateWeaponLevelUp_YuanBaoPay = DecorateWeaponLevelUp_YuanBaoPay:GetCheck();
	this:Hide()
end

function DecorateWeaponLevelUp_Level_Changed() 

	local _name,ComIdx = DecorateWeaponLevelUp_ALLChoice:GetCurrentSelect()
	
	if ComIdx > 0 and ComIdx < 6 and g_DestDecoWeaponLevelId[ComIdx] ~= -1 then 
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(g_DestDecoWeaponLevelId[ComIdx])
		g_curSelectId = g_DestDecoWeaponLevelId[ComIdx]
	end
end

function DecorateWeaponLevelUp_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			DecorateWeaponLevelUp_FakeObject:RotateBeginEx("DecoWeapon_Player", -0.3);
		--向左旋转结束
		else
			DecorateWeaponLevelUp_FakeObject:RotateEndEx();
		end
	end
end

----------------------------------------------------------------------------------
function DecorateWeaponLevelUp_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			DecorateWeaponLevelUp_FakeObject:RotateBeginEx("DecoWeapon_Player", 0.3);
		--向右旋转结束
		else
			DecorateWeaponLevelUp_FakeObject:RotateEndEx();
		end
	end
end

function DecorateWeaponLevelUp_OnOK()
	if g_WeaponBagPos == -1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryDecoWeaponLevelUp")
		Set_XSCRIPT_ScriptID(891788)
		Set_XSCRIPT_Parameter(0, g_WeaponBagPos)
		Set_XSCRIPT_Parameter(1, tonumber(DecorateWeaponLevelUp_YuanBaoPay:GetCheck()))
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function DecorateWeaponLevelUp_Resume_Equip()
	if g_WeaponBagPos ~= -1 then
		DecorateWeaponLevelUp_Init()
	end
end