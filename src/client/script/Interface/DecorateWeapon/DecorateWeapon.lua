
local g_DecorateWeapon_Frame_UnifiedPosition;
local g_clientNpcId = -1
local g_WeaponBagPos = -1
local g_DestDecoWeaponId = -1
local g_DestDecoWeaponLevelId = {}
local g_bSendConfirm = 1

function DecorateWeapon_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	this:RegisterEvent("UPDATE_DECOWEAPON_CONVER") --拖入框放入武器
	this:RegisterEvent("DECOWEAPON_CONVER_CONFIRM_OK")
	this:RegisterEvent("FAKEOBJ_MYSELFEQUIP_CHANGE", false)
end

function DecorateWeapon_OnLoad() 
	g_DecorateWeapon_Frame_UnifiedPosition = DecorateWeapon_Frame:GetProperty("UnifiedPosition");
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
end

function DecorateWeapon_OnEvent(event) 

	if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 891787 then
		local Type = Get_XParam_INT(0)
		PushEvent( "CLOSE_DRESSPREVIEW")
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
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
		
			this:CareObject( g_clientNpcId, 1, "DecorateWeapon" )
			
			DecorateWeapon_FakeObject:AttachWindowEx("DecoWeapon_Player")
			SetFakeObjDataEx("DecoWeapon_Player")
			
			DecorateWeapon_Init()
			this:Show()
			g_bSendConfirm = 1
			
		elseif Type == 2 then		--成功刷新界面
			DecorateWeapon_Init()
		end
	
	elseif (event == "ADJEST_UI_POS" ) then
		DecorateWeapon_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DecorateWeapon_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DecorateWeapon_OnHiden()
		
	elseif (event == "MONEY_CHANGE_EX") then
		local playerMoney = Player:GetData("MONEY")
		DecorateWeapon_SelfMoney:SetProperty("MoneyNumber", playerMoney)
		
	elseif (event == "MONEYJZ_CHANGE_EX") then
		local playerJZ = Player:GetData("MONEY_JZ")
		DecorateWeapon_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
		
	elseif (event == "UPDATE_DECOWEAPON_CONVER") then
		DecorateWeapon_Update(tonumber(arg0))
	
	elseif (event == "DECOWEAPON_CONVER_CONFIRM_OK") then
		g_bSendConfirm = 0
		
	elseif (event == "FAKEOBJ_MYSELFEQUIP_CHANGE")  then
		SetFakeObjDataEx("DecoWeapon_Player")
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(g_DestDecoWeaponId)
	end
	
		-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			this:CareObject( g_clientNpcId, 0, "DecorateWeapon" )
			DecorateWeapon_FakeObject:DetachWindowEx("DecoWeapon_Player")
			g_clientNpcId = -1		
			DecorateWeapon_RestData()
			this:Hide() 
		end
	end	
end

function DecorateWeapon_Frame_On_ResetPos()
  DecorateWeapon_Frame:SetProperty("UnifiedPosition", g_DecorateWeapon_Frame_UnifiedPosition);
end

function DecorateWeapon_Init()
	DecorateWeapon_RestData()
	
	if Player:GetData("Is2606S") == 1 then
		DecorateWeapon_Explian:SetText("#{QXF_260623_160}")
	else
		DecorateWeapon_Explian:SetText("#{DECOW_160126_9}")
	end
	
	DecorateWeapon_ALLChoice:Disable()
	DecorateWeapon_ALLChoice:SetText("#{DECOW_160126_16}")
	
	DecorateWeapon_DemandMoney:SetProperty("MoneyNumber", 0)
	local playerMoney = Player:GetData("MONEY")
	DecorateWeapon_SelfMoney:SetProperty("MoneyNumber", playerMoney)
	local playerJZ = Player:GetData("MONEY_JZ")
	DecorateWeapon_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
	
	DecorateWeapon_OK:Disable()
	DecorateWeapon_Object:SetActionItem(-1)
	g_bSendConfirm = 1
end

function DecorateWeapon_Update(bagBos)
	DecorateWeapon_RestData()
	local theAction = EnumAction(bagBos, "packageitem")
	if theAction:GetID() ~= 0 then
	
		local costMoney, DestDecoWeaponId = DecoWeaponUI:GetDecoWeaponConverInfo(bagBos)
		if costMoney == -1 then
			return 
		end
		
		g_WeaponBagPos = bagBos
		
		LifeAbility:Lock_Packet_Item(g_WeaponBagPos, 1)
		DecorateWeapon_Object:SetActionItem(theAction:GetID())
		
		g_DestDecoWeaponId = DestDecoWeaponId
		
		DecorateWeapon_DemandMoney:SetProperty("MoneyNumber", costMoney)
		DecorateWeapon_OK:Enable()
		
		DecorateWeapon_ALLChoice_Init()
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(DestDecoWeaponId)
		g_bSendConfirm = 1
	end
end

function DecorateWeapon_ALLChoice_Init()
	local WeaponName = {}
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
	
	g_DestDecoWeaponLevelId[1], WeaponName[1], g_DestDecoWeaponLevelId[2], WeaponName[2], 
	g_DestDecoWeaponLevelId[3], WeaponName[3], g_DestDecoWeaponLevelId[4], WeaponName[4],
	g_DestDecoWeaponLevelId[5], WeaponName[5]= DecoWeaponUI:GetDecoWeaponLevelInfo(g_DestDecoWeaponId)
	
	if name1 == -1 then
		return
	end
	
	DecorateWeapon_ALLChoice:ResetList()
	
	for i=1 ,5 do
		WeaponName[i] = ScriptGlobal_Format("#{DECOW_160126_8}", WeaponName[i])
	end 
	 	
	DecorateWeapon_ALLChoice:SetText(WeaponName[1])
	
	for i = 1 , 5 do 
		DecorateWeapon_ALLChoice:AddTextItem(WeaponName[i] ,i) 
	end 
	
	DecorateWeapon_ALLChoice:Enable() 
end

function DecorateWeapon_RestData()
	if g_WeaponBagPos ~= -1 then
		LifeAbility:Lock_Packet_Item(g_WeaponBagPos, 0)
		g_WeaponBagPos = -1
	end
	g_WeaponBagPos = -1
	g_DestDecoWeaponId = -1
	
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
end

function DecorateWeapon_OnHiden()
	this:CareObject( g_clientNpcId, 0, "DecorateWeapon" )
	DecorateWeapon_FakeObject:DetachWindowEx("DecoWeapon_Player")
	g_clientNpcId = -1
	
	DecorateWeapon_RestData()
	this:Hide() 
end

function DecorateWeapon_Level_Changed() 

	local _name,ComIdx = DecorateWeapon_ALLChoice:GetCurrentSelect()
	
	if ComIdx > 0 and ComIdx < 6 and g_DestDecoWeaponLevelId[ComIdx] ~= -1 then 
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(g_DestDecoWeaponLevelId[ComIdx])
	end
end

function DecorateWeapon_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			DecorateWeapon_FakeObject:RotateBeginEx("DecoWeapon_Player", -0.3);
		--向左旋转结束
		else
			DecorateWeapon_FakeObject:RotateEndEx("DecoWeapon_Player");
		end
	end
end

----------------------------------------------------------------------------------
function DecorateWeapon_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			DecorateWeapon_FakeObject:RotateBeginEx("DecoWeapon_Player", 0.3);
		--向右旋转结束
		else
			DecorateWeapon_FakeObject:RotateEndEx();
		end
	end
end

function DecorateWeapon_OnOK()
	if g_WeaponBagPos ~= -1 then
		local myMoney = Player:GetData("MONEY_JZ") + Player:GetData("MONEY")
		local costMoney, DestDecoWeaponId = DecoWeaponUI:GetDecoWeaponConverInfo(g_WeaponBagPos)
		if costMoney == -1 then
			return 
		end
		
		if myMoney < costMoney then
			PushDebugMessage("#{DECOW_160126_33}")
			return
		end
		
		if g_bSendConfirm == 1 then
			PushEvent( "DECOWEAPON_CONVER_CONFIRM", g_WeaponBagPos )
		else
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ConvertDecoWeapon")
			Set_XSCRIPT_ScriptID(891787)
			Set_XSCRIPT_Parameter(0, g_WeaponBagPos)
			Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
	end
end

function DecorateWeapon_Resume_Equip()
	if g_WeaponBagPos ~= -1 then
		DecorateWeapon_Init()
	end
end

function DecorateWeapon_OnHelp()
	PushEvent("OPEN_FUQICHENGHAO",3)
end