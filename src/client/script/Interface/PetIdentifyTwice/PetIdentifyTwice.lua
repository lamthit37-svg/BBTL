--0 鉴定装备资质
--1 重新鉴定装备资质
local Current = 0;
local PetIdentify_Item = -1
local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

local Tb_idx = 30008034;
local jingangcuo_id = 30008048;
local g_Object = -1;

local Tjs_idx = 30900061;
local Tjc_idx = 30505267

local g_PetIdentifyTwice_Frame_UnifiedPosition;

local g_IsPetIdentified =0
local g_PetEquipIdentify_Confirm =-1
local g_PetIdentifyTwice_YuanbaoPay = 1

function PetIdentifyTwice_PreLoad()

	this:RegisterEvent("UI_COMMAND")
--	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_PETIDENTIFY_TWICE")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("PETEQUIP_ZIZHI_UPDATE_RECOIN")
	this:RegisterEvent("PETEQUIP_ZIZHI_RECOIN_CONFIRM_OK");

end

function PetIdentifyTwice_OnLoad()

	g_PetIdentifyTwice_Frame_UnifiedPosition=PetIdentifyTwice_Frame:GetProperty("UnifiedPosition");
end

function PetIdentifyTwice_OnEvent(event)

--打开界面
	if ( event == "UI_COMMAND" ) then

		if tonumber(arg0) ~= 20092462 then 
			return;
		end

		if this:IsVisible() then
			PetIdentify_Close();
		end 
		this:Show();
		objCared = -1
		local xx = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(xx);

		if objCared == -1 then
			PushDebugMessage("server传过来的数据有问题。");
			return;
		end
		local playerMoney = Player:GetData("MONEY");
		PetIdentifyTwice_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		PetIdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
		BeginCareObject_PetIdentify(objCared)
		PetIdentifyTwice_Clear(1)
--放入装备
	elseif  ( event == "UPDATE_PETIDENTIFY_TWICE" ) then
		local playerMoney = Player:GetData("MONEY");
		PetIdentifyTwice_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		PetIdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
		if arg0~= nil then
			PetIdentifyTwice_Update(arg0)
		end
--拖拽取消放入
	elseif( event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() ) then

		local playerMoney = Player:GetData("MONEY");
		PetIdentifyTwice_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		--zchw
		PetIdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
		if(arg0~=nil and tonumber(arg0) == 166 ) then
			PetIdentifyTwice_Resume_Equip_Gem(1)
		end
--
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		local playerMoney = Player:GetData("MONEY");
		PetIdentifyTwice_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		--zchw
		PetIdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
		if( arg0~= nil and -1 == tonumber(arg0)) then
			return;
		end

		if( arg0~= nil) then
			if(tonumber(arg0) and PlayerPackage:GetItemTableIndex(tonumber(arg0)) == Tb_idx) then
				if(PlayerPackage:IsLock(tonumber(arg0)) == 1) then
					--push事件干掉msgbox
					LifeAbility:CloseReIdentifyMsgBox();
					return;
				end
			end
			if tonumber(arg0) == PetIdentify_Item then
				PetIdentifyTwice_Update(arg0)
			end
		end
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		PetIdentifyTwice_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	--zchw
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		PetIdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

	elseif (event == "ADJEST_UI_POS" ) then
		PetIdentify_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetIdentify_Frame_On_ResetPos()
--新资质预览
	elseif (event == "PETEQUIP_ZIZHI_UPDATE_RECOIN") then 
		--更新重启的属性
		PetIdentifyTwice_UpDateRecoin()
		--二次确认			
	elseif (event == "PETEQUIP_ZIZHI_RECOIN_CONFIRM_OK") then 
		if tonumber(arg1) == 1 then  
			PetIdentifyTwice_Clear(1) --先把原来的清空了
			PetIdentifyTwice_Update(tonumber(arg0)) --再放上新的~
		elseif tonumber(arg1) == 0 then
			PetIdentifyTwice_Clear(1)
			this:Hide()
		elseif tonumber(arg1) == 2 then
			PetIdentifyTwice_Clear(1) --先把原来的清空了
		end

	end


end

function PetIdentifyTwice_UpDateRecoin()
	 
	local str =  DataPool : GetPetEquipZiZhiNewDesc(PetIdentify_Item);   --待修改

	PetIdentifyTwice_qualityInfo2:SetText("\n"..str)

	PetIdentifyTwice_OK:Enable()
	g_IsPetIdentified = 1
end

function PetIdentifyTwice_OnShown()
	PetIdentifyTwice_Clear();
end


function PetIdentifyTwice_Clear(cleanaction)

	g_IsPetIdentified = 0
	g_PetEquipIdentify_Confirm = -1
	PetIdentifyTwice_qualityInfo1:SetText("")
	PetIdentifyTwice_qualityInfo2:SetText("")
	
	PetIdentifyTwice_Blank_ButtonCheck:SetCheck(1)
	--EquipAttributeChange_CaiLiaoText:SetText("")
	PetIdentifyTwice_Try:Disable()
--	IdentifyTwice_Object2:SetProperty("Image","")
	PetIdentifyTwice_OK:Disable()
	if cleanaction == 1 then
		if PetIdentify_Item ~= -1 then
			PetIdentifyTwice_Object:SetActionItem(-1)
--			PetIdentifyTwice_Object2:SetProperty("Image","")
			LifeAbility:Lock_Packet_Item(PetIdentify_Item, 0)
			PetIdentify_Item = -1
		end
	end
	PetIdentifyTwice_Blank_ButtonCheck:SetCheck(g_PetIdentifyTwice_YuanbaoPay)	
end

function PetIdentifyTwice_Update(Item_index)
	local index = tonumber(Item_index)
	local theAction = EnumAction(index, "packageitem");

	if theAction:GetID() ~= 0 then 
			if PetIdentify_Item ~= -1 and index ~= PetIdentify_Item and  g_IsPetIdentified == 1  then

		     --二次确认框
		     	PetIdentifyTwice_SendConfirm(Item_index,1)
		     -- 如果空格内已经有对应物品了,需要弹一个二次确认……
		     	return 
			end
			-- 检查试图放入的是否为珍兽装备
			local PetEquipPoint = LifeAbility:Is_PetEquip(index)
			if PetEquipPoint ~= 1 then
					PushDebugMessage("#{ZSYH_170111_81}")
					return
			end 

			local havezizhi = IsPetEquipHaveZiZhi(index)
			if havezizhi <= 0 then
				PushDebugMessage("#{ZSYH_170111_83}")
				return
			end 
			
			local haveIndentify = IsIdentifyPetEquipZiZhi(index)
			if haveIndentify ~= 1 then
				PushDebugMessage("#{ZZCX_11119_08}")
				return
			end
			
			PetIdentifyTwice_Clear(1)

			if PetIdentify_Item ~= -1 then
				LifeAbility : Lock_Packet_Item(PetIdentify_Item,0);
			end
			--push事件干掉msgbox
			LifeAbility:CloseReIdentifyMsgBox();
			PetIdentifyTwice_Object:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(index,1);

			local icon =  tostring(LifeAbility : Get_Item_Icon_Name(index))
 
			 
			PetIdentify_Item = index 
			
			local Equip_Level = LifeAbility : Get_PetEquip_Level(index);
			local NeedMoney  
				NeedMoney = Equip_Level * 20 + 50;   
			
			PetIdentifyTwice_DemandMoney : SetProperty("MoneyNumber", tostring(NeedMoney));
			local desc = DataPool:GetPetEquipZiZhiDesc(index) 
			PetIdentifyTwice_qualityInfo1:SetText("\n"..desc)
			PetIdentifyTwice_Try:Enable()

	else
			PetIdentifyTwice_Object:SetActionItem(-1); 
			LifeAbility : Lock_Packet_Item(PetIdentify_Item,0);
			PetIdentify_Item = -1;
			--push事件干掉msgbox
			LifeAbility:CloseReIdentifyMsgBox();
			PetIdentifyTwice_qualityInfo1:SetText("")
			PetIdentifyTwice_qualityInfo2:SetText("")
	end

end
local EB_FREE_BIND = 0;				-- 无绑定限制
local EB_BINDED = 1;				-- 已经绑定
local	EB_GETUP_BIND =2			-- 拾取绑定
local	EB_EQUIP_BIND =3			-- 装备绑定
function PetIdentifyTwice_Buttons_Clicked()
	--判断电话密保和二级密码保护2012.6.11-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	-- 判断是否为安全时间2012.6.11-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZCX_11119_15}")
		return
	end
	--没有放入装备
	if PetIdentify_Item == -1 or PlayerPackage : GetItemTableIndex( PetIdentify_Item ) == -1 then
		PushDebugMessage("#{ZZCX_11119_14}")
		return
	end 
	local havezizhi = IsPetEquipHaveZiZhi(PetIdentify_Item)
	if havezizhi <= 0 then
		PushDebugMessage("#{ZZCX_11119_07}")
		return
	end
 	 
	local haveIndentify = IsIdentifyPetEquipZiZhi(PetIdentify_Item)
	if haveIndentify ~= 1 then
		PushDebugMessage("#{ZZCX_11119_17}")
		return
	end 
 	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	 
	local isExist1 = IsItemExist_NoLimit(tonumber(Tjs_idx))
	if isExist1 ~= 1  then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Pet_Equip_BuyTianJingSha" )
			Set_XSCRIPT_ScriptID( 809268 )
			Set_XSCRIPT_Parameter( 0, PetIdentify_Item )
			Set_XSCRIPT_Parameter( 1, g_PetIdentifyTwice_YuanbaoPay ) 
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
		return
	end
 
	local index,BindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(Tjs_idx));
	if index == -1  then
		PushDebugMessage("#{ZSZB_090421_35}");
		return
	end
	if BindState == EB_BINDED then
		--如果已绑定
		local tmp = PlayerPackage:GetItemBindStatusByIndex(PetIdentify_Item);
		if(tmp == EB_BINDED)then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("FinishReAdjust");
				Set_XSCRIPT_ScriptID(809268);
				Set_XSCRIPT_Parameter(0,PetIdentify_Item);
				Set_XSCRIPT_ParamCount(1);
			Send_XSCRIPT();
		else
			PlayerPackage:OpenPetEquipReIdentifyMsgBox(tonumber(PetIdentify_Item));
		end
	else
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("FinishReAdjust");
			Set_XSCRIPT_ScriptID(809268);
			Set_XSCRIPT_Parameter(0,PetIdentify_Item);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end
		
end

function PetIdentifyTwice_Close()
	--关闭前也要来个二次确认

	if PetIdentify_Item ~= -1 and g_IsPetIdentified == 1  then
		PetIdentifyTwice_SendConfirm(PetIdentify_Item,0)
		return
	end
	PetIdentifyTwice_Clear(1)
	this:Hide()
end



function PetIdentifyTwice_OnHiden()
	StopCareObject_PetIdentify(objCared)
	PetIdentifyTwice_Clear(1)
	return
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_PetIdentify(objCaredId)

	g_Object = objCaredId;

	this:CareObject(g_Object, 1, "PetIdentify");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_PetIdentify(objCaredId)
	this:CareObject(objCaredId, 0, "PetIdentify");
	g_Object = -1;

end

function PetIdentifyTwice_Resume_Equip_Gem(nIndex)

	if( this:IsVisible() ) then
		if nIndex == 1 then
			if PetIdentify_Item ~= -1 and g_IsPetIdentified == 1  then
				PetIdentifyTwice_SendConfirm(nIndex,2)
				return
			end
			if(PetIdentify_Item ~= -1) then
				LifeAbility : Lock_Packet_Item(PetIdentify_Item,0);
				PetIdentifyTwice_Object : SetActionItem(-1); 
				PetIdentify_Item	= -1;
				PetIdentifyTwice_DemandMoney : SetProperty("MoneyNumber", 0);
				--push事件干掉msgbox
				LifeAbility:CloseReIdentifyMsgBox();
				PetIdentifyTwice_qualityInfo1:SetText("")
				PetIdentifyTwice_qualityInfo2:SetText("")
				PetIdentifyTwice_Try:Disable()
			end
		end
	end

end

function PetIdentify_Frame_On_ResetPos()
--  Identify_Frame:SetProperty("UnifiedPosition", g_Identify_Frame_UnifiedPosition);
end


function PetIdentifyTwice_SaveChange_Clicked()

	if g_IsPetIdentified ==1 then

 		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("DoRefreshEquipZiZhi");
			Set_XSCRIPT_ScriptID(809268);
			Set_XSCRIPT_Parameter(0,PetIdentify_Item);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

		--设置重洗状态
	g_IsPetIdentified =0

	PetIdentifyTwice_Clear(0)
	PetIdentifyTwice_Update(PetIdentify_Item)
end

--二次确认
--发送二次确认
function PetIdentifyTwice_SendConfirm(nIndex,keepopen)
	PushEvent("PETEQUIP_ZIZHI_RECOIN_CONFIRM",tostring(nIndex),tostring(keepopen))
end

function PetIdentifyTwice_Blank_ButtonClick() 
	g_PetIdentifyTwice_YuanbaoPay = PetIdentifyTwice_Blank_ButtonCheck:GetCheck();
end