--2015 VIP随身移功能 By YuanPeiLong
local Enchange_Item1 = -1;
local Enchange_Item2 = -1;
--local g_Object = -1;
local g_check01 = -1;--是否二次确认
local g_check02 = -1;--是否二次确认
local g_check03 = -1;--是否二次确认

local EB_FREE_BIND = 0;				-- 无绑定限制
local EB_BINDED = 1;				-- 已经绑定
local	EB_GETUP_BIND =2			-- 拾取绑定
local	EB_EQUIP_BIND =3			-- 装备绑定

local g_EquipName = {
	[0]		="武器",
	[1]		="帽子",
	[2]		="衣服",
	[3]		="手套",
	[4]		="鞋"  ,
	[5]		="腰带",
	[6]		="戒指",
	[7]	    ="项链",
	[8]		="骑乘",
	[9]		="行囊",
	[10]	="箱格",
	[11]	="戒指",
	[12]	="护符",
	[13]    ="护符",
	[14]	="护腕",
	[15]    ="护肩",
	[16]	="时装",
	[17]  ="暗器",
	[18]  ="武魂",
	[19]  ="龙纹",
	[20]  ="令牌",
	[21]	="豪侠印",
	[22]	="",
	[23]	="#{XWXT_230825_01}",
	}


local g_VIP_EquipNewStrengthen_Frame_UnifiedPosition;

function VIP_EquipNewStrengthen_PreLoad()

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("PUT_NEW_STENGTHEN_ITEM")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("TAKE_STENGTHEN_ITEM")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)--TT:192064
end

function VIP_EquipNewStrengthen_OnLoad()

	g_VIP_EquipNewStrengthen_Frame_UnifiedPosition=VIP_EquipNewStrengthen_Frame:GetProperty("UnifiedPosition");
end

function VIP_EquipNewStrengthen_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 98760002 then	--打开界面
			VIP_EquipNewStrengthen_Clear(0);
			-- local xx = Get_XParam_INT(0);
			-- if tonumber(xx) == -1 then
				-- --return
			-- end
			-- objCared = -1
			-- objCared = DataPool : GetNPCIDByServerID(xx);
			-- if tonumber(objCared)==nil or  tonumber(objCared)== -1 then
				-- PushDebugMessage("server传过来的数据有问题。");
				-- --return;
			-- end
			
			local GemUnionPos = Variable:GetVariable("2014SuiShenUnionPos");
			if(GemUnionPos ~= nil) then
				VIP_EquipNewStrengthen_Frame:SetProperty("UnifiedPosition", GemUnionPos);
			end
			VIP_EquipNewStrengthen_FenYe2:SetCheck(1)

			if Player:GetData("Is2606S") == 1 then
				VIP_EquipNewStrengthen_FenYe4:Hide()
				VIP_EquipNewStrengthen_FenYe5:Hide()
			else
				VIP_EquipNewStrengthen_FenYe4:Show()
				VIP_EquipNewStrengthen_FenYe5:Show()
			end
			
			this:Show();
			--VIP_EquipNewStrengthen_BeginCareObject(objCared);
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif  ( event == "PUT_NEW_STENGTHEN_ITEM" and this:IsVisible()) then
		--更新窗口上的装备
		if tonumber(arg0) == 0 or tonumber(arg0) == 1 or tonumber(arg0) == 2 then
			VIP_EquipNewStrengthen_Update(arg0,arg1);
		end

		local playerMoney = Player:GetData("MONEY");
		VIP_EquipNewStrengthen_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		VIP_EquipNewStrengthen_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); --zchw

	elseif	( event == "PACKAGE_ITEM_CHANGED_EX" ) then
		if (tonumber(Enchange_Item1) == tonumber(arg0)) then
			--VIP_EquipNewStrengthen_Update(0,arg0);
			VIP_EquipNewStrengthen_Clear(0);
		end
		if (tonumber(Enchange_Item2) == tonumber(arg0)) then
			--VIP_EquipNewStrengthen_Update(1,arg0);
			VIP_EquipNewStrengthen_Clear(1);
		end
	elseif (event == "TAKE_STENGTHEN_ITEM" and this:IsVisible()) then
		if arg0 == "I12" then		--移除左边,要连同右边一起移除
			VIP_EquipNewStrengthen_Clear(0)
		elseif arg0 == "I13" then		--移除右边,不需要理会左边
			VIP_EquipNewStrengthen_Clear(1)
		end
	elseif (event == "ADJEST_UI_POS" ) then
		VIP_EquipNewStrengthen_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		VIP_EquipNewStrengthen_Frame_On_ResetPos()
	elseif	( event == "MONEY_CHANGE_EX" ) then
		VIP_EquipNewStrengthen_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX") then
		VIP_EquipNewStrengthen_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
	end
end

-- function VIP_EquipNewStrengthen_BeginCareObject(objCared)
	-- g_Object = objCared;
	-- this:CareObject(tonumber(g_Object), 1, "VIP_EquipNewStrengthen");
-- end

function VIP_EquipNewStrengthen_Update(boxpos,Item_index)

	--源装备口, 因为提示不一样,所以要和目标装备口分开判断
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	--你妹的 就为你这个乱遭的提示加的N多的判断,脑残策划
	--就这么个简单的功能的判断, 写了10页策划案, 还每步提示都不一样, 还说什么写起来很简单
	--就按案子里一步一步些,我看看这个脚本到底能写多少判断

	local i_index = tonumber(Item_index)
	local theAction = EnumAction(i_index, "packageitem");
	local msg = ""

	if tonumber(boxpos) == 0 then
		-- 判断左边的
		local EquipPoint = LifeAbility : Get_Equip_Point(i_index)
		if EquipPoint == -1 then	--如果不是装备,代码里已经有返回的错误信息
			return
		end
		if EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10 or EquipPoint == 22 or EquipPoint > 23 then
				--PushDebugMessage("#{ZBQH_130521_10}")	--不是装备
				return
		end

		if PlayerPackage:IsBagItemKFS(i_index) ==1 then  --武魂的限制
			PushDebugMessage("#{ZBQH_130521_11}")
			return
		end
		
		--宗门装备暂时关闭
		if EquipPoint == 23 then
			PushDebugMessage("#{XWXT_230825_28}")
			return
		end
		
		-- 15级神器不可以刻铭 by lishilong 2016-9-19 
		local nitemTableIndex = PlayerPackage : GetItemTableIndex( i_index )
		if nil == nitemTableIndex then
			return
		end
				
		if 10300422 == nitemTableIndex or 10302448 == nitemTableIndex or 
			10304426 == nitemTableIndex or 10305444 == nitemTableIndex or 10316042 == nitemTableIndex or
			10306042 == nitemTableIndex or 10307042 == nitemTableIndex or 10308042 == nitemTableIndex then
			PushDebugMessage("#{XSQSJ_160812_31}")
			return
		end

		local curlevel = LifeAbility:Get_Equip_CurStrengthLevel(i_index);
		if tonumber(curlevel) <= 0 then
			PushDebugMessage("#{ZBQH_130521_12}")
			return
		end
		if PlayerPackage:IsLock(i_index) == 1 then
			PushDebugMessage("#{ZBQH_130521_13}");
			return
		end

		VIP_EquipNewStrengthen_Clear(0)
		local curlevel = LifeAbility:Get_Equip_CurStrengthLevel(i_index)
		VIP_EquipNewStrengthen_Info4:SetText(""..tonumber(curlevel));
		if tonumber(Enchange_Item1) ~= -1 then
			LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
		end

		VIP_EquipNewStrengthen_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(i_index,1);
		Enchange_Item1 = i_index
	end

	if tonumber(boxpos) == 1 then
		--判断右边的
		local EquipPoint2 = LifeAbility : Get_Equip_Point(i_index)
		if EquipPoint2 == -1 then	--如果不是装备,代码里已经有返回的错误信息
			return
		end
		if EquipPoint2 == 8 or EquipPoint2 == 9 or EquipPoint2 == 10 or EquipPoint2 == 22 or EquipPoint2 > 23 then
				PushDebugMessage("#{ZBQH_130521_14}")	--不是装备 和上边的提示不一样
				return
		end

		if PlayerPackage:IsBagItemKFS(i_index) ==1 then  --武魂的限制
			PushDebugMessage("#{ZBQH_130521_15}")
			return
		end
		
		--宗门装备暂时关闭
		if EquipPoint2 == 23 then
			PushDebugMessage("#{XWXT_230825_28}")
			return
		end
		
		-- 15级神器不可以刻铭 by lishilong 2016-9-19 
		local nitemTableIndex = PlayerPackage : GetItemTableIndex( i_index )
		if nil == nitemTableIndex then
			return
		end
				
		if 10300422 == nitemTableIndex or 10302448 == nitemTableIndex or 
			10304426 == nitemTableIndex or 10305444 == nitemTableIndex or 10316042 == nitemTableIndex or
			10306042 == nitemTableIndex or 10307042 == nitemTableIndex or 10308042 == nitemTableIndex then
			PushDebugMessage("#{XSQSJ_160812_31}")
			return
		end

		if tonumber(Enchange_Item1) < 0 then
			PushDebugMessage("#{ZBQH_130521_16}")
			return
		end

		local EquipPoint1 = LifeAbility : Get_Equip_Point(Enchange_Item1)
		local Equip_Level1 = LifeAbility : Get_Equip_Level(Enchange_Item1);
		local Equip_Level2 = LifeAbility : Get_Equip_Level(i_index);
		local curlevel1 = LifeAbility:Get_Equip_CurStrengthLevel(Enchange_Item1);
		local curlevel2 = LifeAbility:Get_Equip_CurStrengthLevel(i_index);

		if tonumber(EquipPoint1) ~= tonumber(EquipPoint2) then			--各种恶心提示

			local theAction1 = EnumAction(Enchange_Item1, "packageitem");
			local leftItemName = theAction1:GetName()

			if tonumber(Equip_Level1) < 40 then
				msg =  ScriptGlobal_Format("#{ZBQH_130521_17}",leftItemName, tostring(g_EquipName[EquipPoint1]))
			end

			if tonumber(Equip_Level1) >= 40 then
				msg =  ScriptGlobal_Format("#{ZBQH_130521_18}",leftItemName, tostring(g_EquipName[EquipPoint1]))
			end

			PushDebugMessage(msg)
			return
		end

		if tonumber(Equip_Level1) < 40 and tonumber(Equip_Level2) >= 40 then
			local theAction1 = EnumAction(Enchange_Item1, "packageitem");
			local leftItemName = theAction1:GetName()
			msg =  ScriptGlobal_Format("#{ZBQH_130521_17}",leftItemName, tostring(g_EquipName[EquipPoint1]))
			PushDebugMessage(msg)
			return
		end

		if tonumber(Equip_Level1) >= 40 and tonumber(Equip_Level2) < 40 then
			local theAction1 = EnumAction(Enchange_Item1, "packageitem");
			local leftItemName = theAction1:GetName()
			msg =  ScriptGlobal_Format("#{ZBQH_130521_18}",leftItemName, tostring(g_EquipName[EquipPoint1]))
			PushDebugMessage(msg)
			return
		end

		if tonumber(curlevel1) <= tonumber(curlevel2) then
			msg =  ScriptGlobal_Format("#{ZBQH_130521_19}",curlevel1)
			PushDebugMessage(msg)
			return
		end

		VIP_EquipNewStrengthen_Clear(1)
		VIP_EquipNewStrengthen_Info7:SetText(""..tonumber(curlevel2));

		VIP_EquipNewStrengthen_Object2:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(i_index,1);
		Enchange_Item2 = i_index
	end

	if tonumber(boxpos) == 2 then
		--右键点击背包的物品
		local EquipPoint2 = LifeAbility : Get_Equip_Point(i_index)
		if EquipPoint2 == -1 then	--如果不是装备,代码里已经有返回的错误信息
			return
		end
		if  EquipPoint2 == 8 or EquipPoint2 == 9 or EquipPoint2 == 10 or EquipPoint2 == 22 or EquipPoint2 > 23 then
				PushDebugMessage("#{ZBQH_130521_14}")	--不是装备
				return
		end

		if PlayerPackage:IsBagItemKFS(i_index) ==1 then  --武魂的限制
			PushDebugMessage("#{ZBQH_130521_15}")
			return
		end
		
		--宗门装备暂时关闭
		if EquipPoint2 == 23 then
			PushDebugMessage("#{XWXT_230825_28}")
			return
		end
		
		-- 15级神器不可以刻铭 by lishilong 2016-9-19 
		local nitemTableIndex = PlayerPackage : GetItemTableIndex( i_index )
		if nil == nitemTableIndex then
			return
		end
				
		if 10300422 == nitemTableIndex or 10302448 == nitemTableIndex or 
			10304426 == nitemTableIndex or 10305444 == nitemTableIndex or 10316042 == nitemTableIndex or
			10306042 == nitemTableIndex or 10307042 == nitemTableIndex or 10308042 == nitemTableIndex then
			PushDebugMessage("#{XSQSJ_160812_31}")
			return
		end

		if tonumber(Enchange_Item1) >= 0 then
			--右键点击放到右边
			local EquipPoint1 = LifeAbility : Get_Equip_Point(Enchange_Item1)
			local Equip_Level1 = LifeAbility : Get_Equip_Level(Enchange_Item1);
			local Equip_Level2 = LifeAbility : Get_Equip_Level(i_index);
			local curlevel1 = LifeAbility:Get_Equip_CurStrengthLevel(Enchange_Item1);
			local curlevel2 = LifeAbility:Get_Equip_CurStrengthLevel(i_index);

			if tonumber(EquipPoint1) ~= tonumber(EquipPoint2) then			--各种恶心提示
				local theAction1 = EnumAction(Enchange_Item1, "packageitem");
				local leftItemName = theAction1:GetName()

				if tonumber(Equip_Level1) < 40 then
					msg =  ScriptGlobal_Format("#{ZBQH_130521_17}",leftItemName, tostring(g_EquipName[EquipPoint1]))
				end

				if tonumber(Equip_Level1) >= 40 then
					msg =  ScriptGlobal_Format("#{ZBQH_130521_18}",leftItemName, tostring(g_EquipName[EquipPoint1]))
				end

				PushDebugMessage(msg)
				return
			end

			if tonumber(Equip_Level1) < 40 and tonumber(Equip_Level2) >= 40 then
				local theAction1 = EnumAction(Enchange_Item1, "packageitem");
				local leftItemName = theAction1:GetName()
				msg =  ScriptGlobal_Format("#{ZBQH_130521_17}",leftItemName, tostring(g_EquipName[EquipPoint1]))
				PushDebugMessage(msg)
				return
			end

			if tonumber(Equip_Level1) >= 40 and tonumber(Equip_Level2) < 40 then
				local theAction1 = EnumAction(Enchange_Item1, "packageitem");
				local leftItemName = theAction1:GetName()
				msg =  ScriptGlobal_Format("#{ZBQH_130521_18}",leftItemName, tostring(g_EquipName[EquipPoint1]))
				PushDebugMessage(msg)
				return
			end

			if tonumber(curlevel1) <= tonumber(curlevel2) then
				msg =  ScriptGlobal_Format("#{ZBQH_130521_19}",curlevel1)
				PushDebugMessage(msg)
				return
			end

			VIP_EquipNewStrengthen_Clear(1)
			VIP_EquipNewStrengthen_Info7:SetText(""..tonumber(curlevel2));

			VIP_EquipNewStrengthen_Object2:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(i_index,1);
			Enchange_Item2 = i_index

		else
			--右键点击放到左边
			local curlevel = LifeAbility:Get_Equip_CurStrengthLevel(i_index);
			if tonumber(curlevel) <= 0 then
				PushDebugMessage("#{ZBQH_130521_21}")
				return
			end
			if PlayerPackage:IsLock(i_index) == 1 then
				PushDebugMessage("#{ZBQH_130521_20}");
				return
			end

			VIP_EquipNewStrengthen_Clear(0)
			local curlevel = LifeAbility:Get_Equip_CurStrengthLevel(i_index)
			VIP_EquipNewStrengthen_Info4:SetText(""..tonumber(curlevel));
			if tonumber(Enchange_Item1) ~= -1 then
				LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
			end

			VIP_EquipNewStrengthen_Object1:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(i_index,1);
			Enchange_Item1 = i_index
		end
	end

	if tonumber(Enchange_Item1) >= 0 and tonumber(Enchange_Item2) >= 0 then
		VIP_EquipNewStrengthen_OK:Enable()
		g_check01 = -1
		g_check02 = -1
		g_check03 = -1
	else
		VIP_EquipNewStrengthen_OK:Disable()
	end

	if tonumber(Enchange_Item1) >= 0 then
		local lv = LifeAbility:Get_Equip_CurStrengthLevel(Enchange_Item1);
		local NeedMoney = lv*5
		if tonumber(NeedMoney) > 100 then
			NeedMoney = 100
		end
		VIP_EquipNewStrengthen_Money : SetProperty("MoneyNumber", tostring(NeedMoney*10000));
	else
		VIP_EquipNewStrengthen_Money : SetProperty("MoneyNumber", "0");
	end
end


function VIP_EquipNewStrengthen_Buttons_Clicked()
	local msg = "";

	--源装备口, 因为提示不一样,所以要和目标装备口分开判断
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	if tonumber(Enchange_Item1) < 0 then
		PushDebugMessage("#{ZBQH_130521_21}")
		return
	end

	local EquipPoint1 = LifeAbility : Get_Equip_Point(Enchange_Item1)
		if EquipPoint1 == -1 then	--如果不是装备,代码里已经有返回的错误信息
			return
		end
	if  EquipPoint1 == 8 or EquipPoint1 == 9 or EquipPoint1 == 10 or EquipPoint1 == 22 or EquipPoint1 > 23 then
			PushDebugMessage("#{ZBQH_130521_21}")	--不是装备
			return
	end

	if PlayerPackage:IsBagItemKFS(Enchange_Item1) ==1 then  --武魂的限制
		PushDebugMessage("#{ZBQH_130521_15}")
		return
	end
	
	--宗门装备暂时关闭
	if EquipPoint1 == 23 then
		PushDebugMessage("#{XWXT_230825_28}")
		return
	end

	local curlevel = LifeAbility:Get_Equip_CurStrengthLevel(Enchange_Item1);
	if tonumber(curlevel) <= 0 then
		PushDebugMessage("#{ZBQH_130521_22}")
		return
	end

	if PlayerPackage:IsLock(Enchange_Item1) == 1 then
		PushDebugMessage("#{ZBQH_130521_20}");
		return
	end

	if tonumber(Enchange_Item2) < 0 then
		PushDebugMessage("#{ZBQH_130521_23}")
		return
	end

	local EquipPoint2 = LifeAbility : Get_Equip_Point(Enchange_Item2)
		if EquipPoint2 == -1 then	--如果不是装备,代码里已经有返回的错误信息
			return
		end
	if EquipPoint2 == 8 or EquipPoint2 == 9 or EquipPoint2 == 10 or EquipPoint2 == 22 or EquipPoint2 > 23 then
			PushDebugMessage("#{ZBQH_130521_23}")	--不是装备 和上边的提示不一样
			return
	end

	if PlayerPackage:IsBagItemKFS(Enchange_Item2) ==1 then  --武魂的限制
		PushDebugMessage("#{ZBQH_130521_15}")
		return
	end
	
	--宗门装备暂时关闭
	if EquipPoint2 == 23 then
		PushDebugMessage("#{XWXT_230825_28}")
		return
	end

	local Equip_Level1 = LifeAbility : Get_Equip_Level(Enchange_Item1);
	local Equip_Level2 = LifeAbility : Get_Equip_Level(Enchange_Item2);
	local curlevel1 = LifeAbility:Get_Equip_CurStrengthLevel(Enchange_Item1);
	local curlevel2 = LifeAbility:Get_Equip_CurStrengthLevel(Enchange_Item2);

	if tonumber(EquipPoint1) ~= tonumber(EquipPoint2) then			--各种恶心提示
		local theAction1 = EnumAction(Enchange_Item1, "packageitem");
		local leftItemName = theAction1:GetName()

		if tonumber(Equip_Level1) < 40 then
			msg =  ScriptGlobal_Format("#{ZBQH_130521_17}",leftItemName, tostring(g_EquipName[EquipPoint1]))
		end

		if tonumber(Equip_Level1) >= 40 then
			msg =  ScriptGlobal_Format("#{ZBQH_130521_18}",leftItemName, tostring(g_EquipName[EquipPoint1]))
		end

		PushDebugMessage(msg)
		return
	end

	if tonumber(Equip_Level1) < 40 and tonumber(Equip_Level2) >= 40 then
		local theAction1 = EnumAction(Enchange_Item1, "packageitem");
		local leftItemName = theAction1:GetName()
		msg =  ScriptGlobal_Format("#{ZBQH_130521_17}",leftItemName, tostring(g_EquipName[EquipPoint1]))
		PushDebugMessage(msg)
		return
	end

	if tonumber(Equip_Level1) >= 40 and tonumber(Equip_Level2) < 40 then
		local theAction1 = EnumAction(Enchange_Item1, "packageitem");
		local leftItemName = theAction1:GetName()
		msg =  ScriptGlobal_Format("#{ZBQH_130521_18}",leftItemName, tostring(g_EquipName[EquipPoint1]))
		PushDebugMessage(msg)
		return
	end

	if tonumber(curlevel1) <= tonumber(curlevel2) then
		msg =  ScriptGlobal_Format("#{ZBQH_130521_19}",curlevel1)
		PushDebugMessage(msg)
		return
	end

	local NeedMoney = curlevel1*5
	if tonumber(NeedMoney) > 100 then
		NeedMoney = 100
	end

	local playerMoney = Player:GetData("MONEY");
	local playerMoney_JZ = Player:GetData("MONEY_JZ");
	if playerMoney+playerMoney_JZ < NeedMoney*10000 then
		PushDebugMessage("#{ZBQH_130521_24}")
		return
	end

	local BindState1 = PlayerPackage:GetItemBindStatusByIndex(tonumber(Enchange_Item1));
	local BindState2 = PlayerPackage:GetItemBindStatusByIndex(tonumber(Enchange_Item2));

	if BindState1 == EB_BINDED and BindState2 ~= EB_BINDED and tonumber(g_check01) ~= 1 then
		--绑定提示
--~ 		if IsUnbindChongLouEquip(PlayerPackage:GetItemTableIndex(tonumber(Enchange_Item2))) == 1 then
--~ 			PushDebugMessage("#{ZBQH_130521_45}")
--~ 			return
--~ 		end

		msg =  ScriptGlobal_Format("#{ZBQH_130521_27}", curlevel1)

		GameProduceLogin : ShowMessageBox( msg, "Close", "-1")
		g_check01 = 1;
		return
	end

	-- 源非绑定重楼 目标不是非绑定的重楼之外的非绑定道具
	local nEquipTableIndex1	= PlayerPackage : GetItemTableIndex( tonumber(Enchange_Item1) )
	local nEquipTableIndex2	= PlayerPackage : GetItemTableIndex( tonumber(Enchange_Item2) )
	if 1 == IsUnbindChongLouEquip(nEquipTableIndex1) 
			and 1 ~= IsUnbindChongLouEquip(nEquipTableIndex2) 
			and EB_BINDED ~= BindState2 
			and tonumber(g_check02) ~= 1 then

		msg =  ScriptGlobal_Format("#{ZBQH_250109_01}", curlevel1)

		GameProduceLogin : ShowMessageBox( msg, "Close", "-1")
		g_check02 = 1;
		return
	end

	if tonumber(curlevel2) > 0 and tonumber(g_check03) ~= 1 then
		--等级覆盖提示
		msg =  ScriptGlobal_Format("#{ZBQH_130521_26}", curlevel1)

		GameProduceLogin : ShowMessageBox( msg, "Close", "-1")
		g_check03 = 1;
		return
	end

	g_check01 = -1;
	g_check02 = -1;
	g_check03 = -1;

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("FinishMoveEnhance");
		Set_XSCRIPT_ScriptID(809262);
		Set_XSCRIPT_Parameter(0,Enchange_Item1);
		Set_XSCRIPT_Parameter(1,Enchange_Item2);
		Set_XSCRIPT_Parameter(2,1);--2015 VIP随身移功能 By YuanPeiLong
		Set_XSCRIPT_ParamCount(3);--2015 VIP随身移功能 By YuanPeiLong
	Send_XSCRIPT();

end

function VIP_EquipNewStrengthen_Clear(pos)
	if tonumber(pos) == 0 then
		if Enchange_Item1 ~= -1 then
			VIP_EquipNewStrengthen_Object1:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
			Enchange_Item1 = -1
		end
		VIP_EquipNewStrengthen_Info4:SetText("");
		VIP_EquipNewStrengthen_Money : SetProperty("MoneyNumber", "0");
	end
	if Enchange_Item2 ~= -1 then
		VIP_EquipNewStrengthen_Object2:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(Enchange_Item2,0);
		Enchange_Item2 = -1
	end
	VIP_EquipNewStrengthen_Info7:SetText("");

	g_check01 = -1;
	g_check02 = -1;
	g_check03 = -1;
	VIP_EquipNewStrengthen_OK:Disable()

	local playerMoney = Player:GetData("MONEY");
	VIP_EquipNewStrengthen_SelfMoney:SetProperty("MoneyNumber", playerMoney);
	VIP_EquipNewStrengthen_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
end

function VIP_EquipNewStrengthen_OnHiden()
	VIP_EquipNewStrengthen_Clear(0);
	this:Hide()
end

function VIP_EquipNewStrengthen_Frame_On_ResetPos()
  VIP_EquipNewStrengthen_Frame:SetProperty("UnifiedPosition", g_VIP_EquipNewStrengthen_Frame_UnifiedPosition);
end

function VIP_EquipNewStrengthen_Object1_RClicked()
			VIP_EquipNewStrengthen_Clear(0);
end

function VIP_EquipNewStrengthen_Object2_RClicked()
			VIP_EquipNewStrengthen_Clear(1);
end

--2015 VIP随身移功能 By YuanPeiLong
function VIP_EquipNewStrengthen_FenYe_Clicked( nIndex )
	
	if not(nIndex==1 or nIndex==2 or nIndex==3 or nIndex==4) then
		return
	end

	local nUI = 0
	if 1 == nIndex then
		nUI = 98760001
	elseif 2 == nIndex then
		return
	elseif 3 == nIndex then
		nUI = 98760003
	elseif 4 == nIndex then
		if Player:GetData("Is2606S") == 1 then
			return
		end
		nUI = 98760004
	else
		return
	end
	if nUI ~= 0 then
		Variable:SetVariable("2014SuiShenUnionPos", VIP_EquipNewStrengthen_Frame:GetProperty("UnifiedPosition"), 1)
		PushEvent("UI_COMMAND", nUI)
		VIP_EquipNewStrengthen_OnHiden()
		this:Hide()
	end	
	
end

function VIP_EquipNewStrengthen_OpenVipZZEquipTransfer()
	if Player:GetData("Is2606S") == 1 then
		return
	end
	Variable:SetVariable("2014SuiShenUnionPos", VIP_EquipNewStrengthen_Frame:GetProperty("UnifiedPosition"), 1)
	VIP_EquipNewStrengthen_OnHiden()
	this:Hide()
	Lua_OpenVipZZEquipTransfer()
end
