local Current = 0;

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

local Bind_Item1 = -1
local Bind_Item2 = -1
local g_Object = -1;

local LastItem1 = -1;
local LastItem2 = -1;

local g_EquipBind_Frame_UnifiedPosition;
local g_EquipBind_YuanBaoPay = 1

function EquipBind_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_EQUIPBIND",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("BUY_ITEM",false)				--快捷购买，更新界面
end

function EquipBind_OnLoad()

	g_EquipBind_Frame_UnifiedPosition=EquipBind_Frame:GetProperty("UnifiedPosition");
	g_EquipBind_YuanBaoPay = 1;

end

function EquipBind_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 1005) then
		if this:IsVisible() then
			EquipBind_Close();
		end
		if g_EquipBind_YuanBaoPay == 1 or g_EquipBind_YuanBaoPay == 0 then
			EquipBind_YuanBaoPay:SetCheck(g_EquipBind_YuanBaoPay)
		end
		this:Show();
		
		objCared = -1;
		local xx = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(xx);

		if objCared == -1 then
				PushDebugMessage("server传过来的数据有问题。");
				return;
		end
		EquipBind_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		EquipBind_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ"))); --zchw
		BeginCareObject_EquipBind(objCared)
	elseif ( event == "UPDATE_EQUIPBIND" ) then
		if arg0~= nil then
			EquipBind_Update(arg0,arg1)
			
		end	
		EquipBind_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		EquipBind_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ"))) --zchw
	elseif ( event == "RESUME_ENCHASE_GEM_EX" ) then
		if arg0 ~= nil then
			EquipBind_Resume_Gem(tonumber(arg0));
			
		end
		EquipBind_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		EquipBind_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ"))) --zchw
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			
			--取消关心
			EquipBind_Close()
		end
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then

		if( arg0~= nil and -1 == tonumber(arg0)) then
			return;
		end

		if( arg0~= nil ) then
			if (Bind_Item1 == tonumber(arg0) ) then
				EquipBind_Resume_Gem(31)			
			end
			if (Bind_Item2 == tonumber(arg0) ) then
				EquipBind_Resume_Gem(32)			
			end
			
		end
		EquipBind_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		EquipBind_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ"))) --zchw

		LastItem1 = -1;
		LastItem2 = -1;
	elseif event == "BUY_ITEM" and this:IsVisible() then	--快捷购买，更新界面
		local itemId = tonumber(arg1)
		EquipBind_Update(2,tonumber(PlayerPackage:GetBagPosByItemIndex(itemId)));	
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		EquipBind_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	--zchw
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		EquipBind_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		
	elseif (event == "ADJEST_UI_POS" ) then
		EquipBind_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipBind_Frame_On_ResetPos()
	end


end

function EquipBind_OnShown()
	EquipBind_Clear();
end

function EquipBind_Clear()
	if Bind_Item1 ~= -1 then
		EquipBind_MainItem:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(Bind_Item1,0);
		Bind_Item1 = -1

	end
	if Bind_Item2 ~= -1 then
		EquipBind_OtherItem:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(Bind_Item2,0);
		Bind_Item2 = -1
	end
	EquipBind_NeedMoney:SetProperty("MoneyNumber", "");
		
	LastItem1 = -1;
	LastItem2 = -1;
end

function EquipBind_Update(UI_index,Item_index)
	local i_index = tonumber(Item_index)
	local u_index = tonumber(UI_index)
	local theAction = EnumAction(i_index, "packageitem");

	if u_index == 1 then
		if theAction:GetID() ~= 0 then
				local EquipPoint = LifeAbility : Get_Equip_Point(i_index)
				if EquipPoint == -1 or EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10 or EquipPoint == 18 then
					if EquipPoint ~= -1 then
						PushDebugMessage("不能放入这种装备。")
					end
					return
				end
				
				if EquipPoint == 22 then
					PushDebugMessage("#{MKXZ_191028_01}")
					return
				end
				
				--宗门装备暂时关闭
				if EquipPoint == 23 then
					PushDebugMessage("#{XWXT_230825_17}")
					return
				end
				
				-- 15级神器不可以刻铭 by lishilong 2016-9-19 
				local nitemTableIndex = PlayerPackage : GetItemTableIndex( i_index )
				if nil == nitemTableIndex then
					return
				end
				
				if 10300422 == nitemTableIndex or 10302448 == nitemTableIndex or 
					10304426 == nitemTableIndex or 10305444 == nitemTableIndex or
					10306042 == nitemTableIndex or 10307042 == nitemTableIndex or 10308042 == nitemTableIndex 
					or 10316042 == nitemTableIndex then
					PushDebugMessage("#{XSQSJ_160812_32}")
					return
				end
				
				if Bind_Item1 ~= -1 then
					LifeAbility : Lock_Packet_Item(Bind_Item1,0);
				end
				EquipBind_MainItem:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(i_index,1);
				Bind_Item1 = i_index
				local equip_level = LifeAbility : Get_Equip_Level(i_index);
				local equip_point = LifeAbility : Get_Equip_Point(i_index);
				local needmoney
				
				if equip_point == 0 or equip_point == 2 then
					needmoney = 500 + equip_level * 200
				else
					needmoney = 250 + equip_level * 100
				end
				
				EquipBind_NeedMoney:SetProperty("MoneyNumber", tostring(needmoney));
		else
				EquipBind_MainItem:SetActionItem(-1);			
				LifeAbility : Lock_Packet_Item(Bind_Item1,0);		
				Bind_Item1 = -1;
		end
	elseif u_index == 2 then
		if theAction:GetID() ~= 0 then
				if PlayerPackage : GetItemTableIndex( i_index ) ~= 30900013 and
					 PlayerPackage : GetItemTableIndex( i_index ) ~= 30900014 then
					PushDebugMessage("这里必须放入刻铭符。")
					return
				end
				if Bind_Item2 ~= -1 then
					LifeAbility : Lock_Packet_Item(Bind_Item2,0);
				end
				EquipBind_OtherItem:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(i_index,1);
				Bind_Item2 = i_index
		else
				EquipBind_OtherItem:SetActionItem(-1);			
				LifeAbility : Lock_Packet_Item(Bind_Item2,0);		
				Bind_Item2 = -1;
		end
	end

	LastItem1 = -1;
	LastItem2 = -1;
end

function EquipBind_Buttons_Clicked()

	
	if Bind_Item1 == -1 then 
		PushDebugMessage("请放入要刻铭的装备。")
		return
	end
	--if Bind_Item2 == -1 then
	--	PushDebugMessage("请放入刻铭符。")
	--	return
	--end
		
	-- 如果装备是非绑定，而刻铭符是绑定
	if( Bind_Item1 and Bind_Item2 and Bind_Item2 ~= -1 and GetItemBindStatus( Bind_Item1 ) == 0 and GetItemBindStatus( Bind_Item2 ) == 1 ) then
		-- 看装备是否变了，如果没有变表示上次已经提醒过了
		if ( LastItem1 ~= Bind_Item1 ) or ( LastItem2 ~= Bind_Item2 ) then
			LastItem1 = Bind_Item1;
			LastItem2 = Bind_Item2;
			ShowSystemInfo("QZBDDJ_090901_01");
			return
		end		
	end
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("FinishBind");
		Set_XSCRIPT_ScriptID(809266);
		Set_XSCRIPT_Parameter(0,Bind_Item1);
		Set_XSCRIPT_Parameter(1,Bind_Item2);
		Set_XSCRIPT_Parameter(2,tonumber(EquipBind_YuanBaoPay:GetCheck()));
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
end

function EquipBind_Close()
	g_EquipBind_YuanBaoPay = EquipBind_YuanBaoPay:GetCheck();
	this:Hide()
end

function EquipBind_Cancel_Clicked()
	EquipBind_Close();
	return;
end

function EquipBind_OnHiden()
	StopCareObject_EquipBind(objCared)
	EquipBind_Clear()
	g_EquipBind_YuanBaoPay = EquipBind_YuanBaoPay:GetCheck();
	return
end
--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_EquipBind(objCaredId)

	g_Object = objCaredId;

	this:CareObject(g_Object, 1, "EquipBind");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_EquipBind(objCaredId)
	this:CareObject(objCaredId, 0, "EquipBind");
	g_Object = -1;

end

function EquipBind_Resume_Gem(nIndex)
	if nIndex < 31 or nIndex > 32 then
		return
	end

	nIndex = nIndex - 30
	if( this:IsVisible() ) then
		if nIndex == 1 then
			if Bind_Item1 ~= -1 then
				EquipBind_MainItem:SetActionItem(-1)			
				LifeAbility : Lock_Packet_Item(Bind_Item1,0);
				Bind_Item1 = -1
				EquipBind_NeedMoney:SetProperty("MoneyNumber", 0);
			end
		else
			if Bind_Item2 ~= -1 then
				EquipBind_OtherItem:SetActionItem(-1)			
				LifeAbility : Lock_Packet_Item(Bind_Item2,0);
				Bind_Item2 = -1
			end
		end
	end
	
	LastItem1 = -1;
	LastItem2 = -1;
end

function EquipBind_Frame_On_ResetPos()
  EquipBind_Frame:SetProperty("UnifiedPosition", g_EquipBind_Frame_UnifiedPosition);
end