--0 鉴定装备资质
--1 重新鉴定装备资质
local Current = 0;
local Identify_Item = -1
local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

local Tb_idx = 30008034;
local jingangcuo_id = 30008048;
local g_Object = -1;

local g_Identify_Frame_UnifiedPosition;

local g_IsIdentified =0
local g_EquipIdentify_Confirm =-1
local g_IdentifyComfirm = false

local g_NewItem = true

local g_Arrow_Hong = "set:UIIcons1 image:ZizhiHong";
local g_Arrow_Lv = "set:UIIcons1 image:ZizhiLv";

local g_IdentifyTwice_YuanBaoPay = 1

local g_ZiZhiName =
{
	[0] = "外攻资质", --物理攻击
	[1] = "外防资质", --物理防御
	[2] = "内攻资质", --魔法攻击
	[3] = "内防资质", --魔法防御
	[4] = "闪避资质", --闪避
	[5] = "命中资质", --命中
}

function IdentifyTwice_PreLoad()

	this:RegisterEvent("UI_COMMAND")
--	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_IDENTIFY_TWICE")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("EQUIP_ZIZHI_UPDATE_RECOIN")
	this:RegisterEvent("EQUIP_ZIZHI_RECOIN_CONFIRM_OK");
	this:RegisterEvent("IDENTIFYTWICEQUEST_CONFIRM_RET")

end

function IdentifyTwice_OnLoad()

	--g_Identify_Frame_UnifiedPosition=Identify_Frame:GetProperty("UnifiedPosition");
	g_IdentifyTwice_YuanBaoPay = 1;
end

function IdentifyTwice_OnEvent(event)

--打开界面
	if ( event == "UI_COMMAND" ) then

		if tonumber(arg0) ~= 112233 then

			return;
		end

		if this:IsVisible() then
			Identify_Close();
		end

		if g_IdentifyTwice_YuanBaoPay == 1 or g_IdentifyTwice_YuanBaoPay == 0 then
			IdentifyTwice_YuanBaoPay:SetCheck(g_IdentifyTwice_YuanBaoPay)
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
		IdentifyTwice_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		IdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
		BeginCareObject_Identify(objCared)
		IdentifyTwice_Clear(1)
		IdentifyTwice_UpDateTiXing()
--放入装备
	elseif  ( event == "UPDATE_IDENTIFY_TWICE" ) then
		local playerMoney = Player:GetData("MONEY");
		IdentifyTwice_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		IdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
		if arg0~= nil then
			local nret = IdentifyTwice_Update(arg0)
			if(nret ~= 0) then
				IdentifyTwice_UpDateTiXing()
			end
		end
--拖拽取消放入
	elseif( event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() ) then

		local playerMoney = Player:GetData("MONEY");
		IdentifyTwice_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		--zchw
		IdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
		if(arg0~=nil and tonumber(arg0) == 166 ) then
			IdentifyTwice_Resume_Equip_Gem(1)
		end
--
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		local playerMoney = Player:GetData("MONEY");
		IdentifyTwice_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		--zchw
		IdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
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
			if tonumber(arg0) == Identify_Item then
				IdentifyTwice_Update(arg0)
			end
		end
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		IdentifyTwice_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	--zchw
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		IdentifyTwice_DemandJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

	elseif (event == "ADJEST_UI_POS" ) then
		Identify_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Identify_Frame_On_ResetPos()
--新资质预览
	elseif (event == "EQUIP_ZIZHI_UPDATE_RECOIN") then
		--更新重启的属性
		IdentifyTwice_UpDateRecoin()
		g_NewItem = false
		g_IdentifyComfirm = false
		--二次确认
	elseif (event == "EQUIP_ZIZHI_RECOIN_CONFIRM_OK") then
		if tonumber(arg1) == 1 then
--		PushDebugMessage("arg0="..arg0)

			IdentifyTwice_Clear(1) --先把原来的清空了
			IdentifyTwice_Update(tonumber(arg0)) --再放上新的~
			IdentifyTwice_UpDateTiXing()
		elseif tonumber(arg1) == 0 then
			IdentifyTwice_Clear(1)
			g_IdentifyTwice_YuanBaoPay = IdentifyTwice_YuanBaoPay:GetCheck();
			this:Hide()
		elseif tonumber(arg1) == 2 then
			IdentifyTwice_Clear(1) --先把原来的清空了
		end
	elseif(event == "IDENTIFYTWICEQUEST_CONFIRM_RET") then
		if(tonumber(arg0) == 1) then
			--替换资质
			IdentifyTwice_SaveChange_Clicked()
		else
			--取消
			g_IdentifyComfirm = true
		end
	end


end

function IdentifyTwice_UpDateRecoin()

	local str =  DataPool : GetEquipZiZhiRefreshDesc(Identify_Item);

	IdentifyTwice_qualityInfo2:SetText("\n"..str)
	IdentifyTwice_Arrow1:SetProperty("Image","")
	IdentifyTwice_Arrow2:SetProperty("Image","")
	IdentifyTwice_Arrow3:SetProperty("Image","")
	local type1,value1,type2,value2 = DataPool : GetEquipZiZhiCompare(Identify_Item);
	if(type1 ~= nil and type1 >= 0 and type2 ~= nil and type2 >= 0) then
		if(value1 > 0) then
			IdentifyTwice_Arrow3:SetProperty("Image",g_Arrow_Lv)
		end
		if(value1 < 0) then
			IdentifyTwice_Arrow3:SetProperty("Image",g_Arrow_Hong)
		end
		if(value2 > 0) then
			IdentifyTwice_Arrow1:SetProperty("Image",g_Arrow_Lv)
		end
		if(value2 < 0) then
			IdentifyTwice_Arrow1:SetProperty("Image",g_Arrow_Hong)
		end
	else
		if(type1 ~= nil and type1 >= 0) then
			if(value1 > 0) then
				IdentifyTwice_Arrow2:SetProperty("Image",g_Arrow_Lv)
			end
			if(value1 < 0) then
				IdentifyTwice_Arrow2:SetProperty("Image",g_Arrow_Hong)
			end
		end
	end
	IdentifyTwice_OK:Enable()
	g_IsIdentified = 1
end

function IdentifyTwice_UpDateTiXing()
	IdentifyTwice_SearchMode:ResetList()
	local nCount = 0
	IdentifyTwice_SearchMode:ComboBoxAddItem("不提醒",nCount)
	nCount = nCount + 1
	if(Identify_Item ~= -1) then
		local type1,value1,type2,value2 = DataPool : GetEquipZiZhi(Identify_Item);
		if(type1 ~= nil and type1 >= 0) then
			local str = string.format("高于原有%s",g_ZiZhiName[type1])
			IdentifyTwice_SearchMode:ComboBoxAddItem(str,nCount)
			nCount = nCount + 1
		end
		if(type2 ~= nil and type2 >= 0) then
			local str1 = string.format("高于原有%s",g_ZiZhiName[type2])
			IdentifyTwice_SearchMode:ComboBoxAddItem(str1,nCount)
			nCount = nCount + 1
		end
		if(nCount >= 3) then
			--local str2 = string.format("两者均大于等于原有资质提醒")
			IdentifyTwice_SearchMode:ComboBoxAddItem("全部高于等于原有资质",nCount)
			nCount = nCount + 1
		end
	end
	IdentifyTwice_SearchMode:SetCurrentSelect(0)
end

function IdentifyTwice_IsMaxValue(item)
	if(item ~= nil and item ~= -1) then
		local type1,value1,type2,value2 = DataPool : GetEquipZiZhi(item)
		if(type1 ~= nil and type1 >= 0) then
			if(value1 < 60) then
				return 0
			end
		end
		if(type2 ~= nil and type2 >=0) then
			if(value2 < 60) then
				return 0
			end
		end
		if(type1 == nil and type2 == nil) then
			return 0
		end
		return 1
	end
	return 0
end

function IdentifyTwice_OnShown()
	IdentifyTwice_Clear();
end


function IdentifyTwice_Clear(cleanaction)

	g_IsIdentified = 0
	g_EquipIdentify_Confirm = -1
	IdentifyTwice_qualityInfo1:SetText("")
	IdentifyTwice_qualityInfo2:SetText("")
	IdentifyTwice_Arrow1:SetProperty("Image","")
	IdentifyTwice_Arrow2:SetProperty("Image","")
	IdentifyTwice_Arrow3:SetProperty("Image","")
	g_IdentifyComfirm = false
	--EquipAttributeChange_CaiLiaoText:SetText("")
	IdentifyTwice_Try:Disable()
--	IdentifyTwice_Object2:SetProperty("Image","")
	IdentifyTwice_OK:Disable()
	if cleanaction == 1 then
		if Identify_Item ~= -1 then
			IdentifyTwice_Object1:SetActionItem(-1)
			IdentifyTwice_Object2:SetProperty("Image","")
			LifeAbility:Lock_Packet_Item(Identify_Item, 0)
			Identify_Item = -1
		end
	end
end

function IdentifyTwice_Update(Item_index)
	local index = tonumber(Item_index)
	local theAction = EnumAction(index, "packageitem");

	if theAction:GetID() ~= 0 then

			if Identify_Item ~= -1 and index ~= Identify_Item and  g_IsIdentified == 1  then

		--二次确认框
			IdentifyTwice_SendConfirm(Item_index,1)
		-- 如果空格内已经有对应物品了,需要弹一个二次确认……
			return 0

			end
			-- 检查试图放入的是否为珍兽装备
			local PetEquipPoint = LifeAbility:Is_PetEquip(index)
			if PetEquipPoint ~= -1 then
					PushDebugMessage("#{ZSZB_0629_05}")
					return 0
			end


			local EquipPoint = LifeAbility : Get_Equip_Point(index)
			if EquipPoint == -1 or EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10
			or PlayerPackage:IsBagItemKFS(index) ==1 then --武魂的限制
				if EquipPoint ~= -1 then
					PushDebugMessage("不能放入这种装备。")
					return 0
				end

			end


			local havezizhi = IsHaveEquipZiZhi(index)
			if havezizhi <= 0 then
				PushDebugMessage("#{ZZCX_11119_07}")
				return 0
			end



			local haveIndentify = IsIdentifyEquipZiZhi(index)
			if haveIndentify ~= 1 then
				PushDebugMessage("#{ZZCX_11119_08}")
				return 0
			end
			if(IdentifyTwice_IsMaxValue(index) == 1) then
				PushDebugMessage("#{ZBZZYH_170526_12}")
				IdentifyTwice_Clear(1)
				return 0
			end
			IdentifyTwice_Clear(1)

			if Identify_Item ~= -1 then
				LifeAbility : Lock_Packet_Item(Identify_Item,0);
			end
			--push事件干掉msgbox
			LifeAbility:CloseReIdentifyMsgBox();
			IdentifyTwice_Object1:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(index,1);

			local icon =  tostring(LifeAbility : Get_Item_Icon_Name(index))
			IdentifyTwice_Object2:SetProperty("Image",icon)
			Identify_Item = index
			local Equip_Level = LifeAbility : Get_Equip_Level(index);
			local NeedMoney = Equip_Level * 20 + 50;

			IdentifyTwice_DemandMoney : SetProperty("MoneyNumber", tostring(NeedMoney));
			local desc = DataPool:GetEquipZiZhiDesc(index)
			IdentifyTwice_qualityInfo1:SetText("\n"..desc)
			IdentifyTwice_Try:Enable()
			g_NewItem = true
			g_IdentifyComfirm = false
			return 1
	else
			IdentifyTwice_Object1:SetActionItem(-1);
			IdentifyTwice_Object2:SetProperty("Image","")
			LifeAbility : Lock_Packet_Item(Identify_Item,0);
			Identify_Item = -1;
			--push事件干掉msgbox
			LifeAbility:CloseReIdentifyMsgBox();
			IdentifyTwice_qualityInfo1:SetText("")
			IdentifyTwice_qualityInfo2:SetText("")
			IdentifyTwice_Arrow1:SetProperty("Image","")
			IdentifyTwice_Arrow2:SetProperty("Image","")
			IdentifyTwice_Arrow3:SetProperty("Image","")
			return 1
	end
	return 0
end
local EB_FREE_BIND = 0;				-- 无绑定限制
local EB_BINDED = 1;				-- 已经绑定
local	EB_GETUP_BIND =2			-- 拾取绑定
local	EB_EQUIP_BIND =3			-- 装备绑定
function IdentifyTwice_Buttons_Clicked()
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
	if Identify_Item == -1 or PlayerPackage : GetItemTableIndex( Identify_Item ) == -1 then
		PushDebugMessage("#{ZZCX_11119_14}")
		return
	end

	local havezizhi = IsHaveEquipZiZhi(Identify_Item)
			if havezizhi <= 0 then
				PushDebugMessage("#{ZZCX_11119_07}")
				return
			end



			local haveIndentify = IsIdentifyEquipZiZhi(Identify_Item)
			if haveIndentify ~= 1 then
				PushDebugMessage("#{ZZCX_11119_17}")
				return
			end
			if(IdentifyTwice_IsMaxValue(Identify_Item) == 1) then
				PushDebugMessage("#{ZBZZYH_170526_12}")
				return
			end
			--二次确认提醒
			local ___,nMode = IdentifyTwice_SearchMode:GetCurrentSelect()
			if(g_NewItem == true or g_IdentifyComfirm == true) then
				nMode = 0
			end
			-- if(0 ~= nMode and g_NewItem ~= true and g_IdentifyComfirm ~= true) then
				-- local bTip = false
				-- local type1,value1,type2,value2 = DataPool : GetEquipZiZhiCompare(Identify_Item);
				-- if(nMode == 1 and value1 ~= nil and value1 > 0 )then
					-- bTip = true
				-- end
				-- if(nMode == 2 and value2 ~= nil and value2 > 0) then
					-- bTip = true
				-- end
				-- if(nMode == 3 and value1 ~= nil and value1 > 0 and value2 ~= nil and value2 > 0) then
					-- bTip = true
				-- end
				-- if(bTip) then
					-- PushEvent("IDENTIFYTWICEQUEST_CONFIRM",Identify_Item)
					-- return
				-- end
			-- end



			local index,BindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(Tb_idx));
			local index2,BindState2 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(jingangcuo_id));
			if(index == -1 and index2 == -1)then
				--local str = "缺少#{_ITEM"..Tb_idx.."}或#{_ITEM"..jingangcuo_id.."}，或者它们被加锁。";
				--PushDebugMessage(str);
				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("FinishReAdjust");
					Set_XSCRIPT_ScriptID(809261);
					Set_XSCRIPT_Parameter(0,Identify_Item);
					Set_XSCRIPT_Parameter(1,nMode);
					Set_XSCRIPT_Parameter(2,tonumber(IdentifyTwice_YuanBaoPay:GetCheck()));
					Set_XSCRIPT_ParamCount(3);
				Send_XSCRIPT();
				g_IdentifyComfirm = false;
				return
			end
			if(BindState == EB_BINDED or BindState2 == EB_BINDED)then
				--如果已绑定
				local tmp = PlayerPackage:GetItemBindStatusByIndex(Identify_Item);
				if(tmp == EB_BINDED)then
					Clear_XSCRIPT();
						Set_XSCRIPT_Function_Name("FinishReAdjust");
						Set_XSCRIPT_ScriptID(809261);
						Set_XSCRIPT_Parameter(0,Identify_Item);
						Set_XSCRIPT_Parameter(1,nMode);
						Set_XSCRIPT_Parameter(2,tonumber(IdentifyTwice_YuanBaoPay:GetCheck()));
						Set_XSCRIPT_ParamCount(3);
					Send_XSCRIPT();
					g_IdentifyComfirm = false;
				else
					PlayerPackage:OpenReIdentifyMsgBox(tonumber(Identify_Item));
				end
			else
				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("FinishReAdjust");
					Set_XSCRIPT_ScriptID(809261);
					Set_XSCRIPT_Parameter(0,Identify_Item);
					Set_XSCRIPT_Parameter(1,nMode);
					Set_XSCRIPT_Parameter(2,tonumber(IdentifyTwice_YuanBaoPay:GetCheck()));
					Set_XSCRIPT_ParamCount(3);
				Send_XSCRIPT();
				g_IdentifyComfirm = false;
			end
end

function IdentifyTwice_Close()
	--关闭前也要来个二次确认

	if Identify_Item ~= -1 and g_IsIdentified == 1  then
		IdentifyTwice_SendConfirm(Identify_Item,0)
		return
	end
	IdentifyTwice_Clear(1)
	g_IdentifyTwice_YuanBaoPay = IdentifyTwice_YuanBaoPay:GetCheck();
	this:Hide()
end



function IdentifyTwice_OnHiden()
	g_IdentifyTwice_YuanBaoPay = IdentifyTwice_YuanBaoPay:GetCheck();
	StopCareObject_Identify(objCared)
	IdentifyTwice_Clear(1)
	return
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_Identify(objCaredId)

	g_Object = objCaredId;

	this:CareObject(g_Object, 1, "Identify");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_Identify(objCaredId)
	this:CareObject(objCaredId, 0, "Identify");
	g_Object = -1;

end

function IdentifyTwice_Resume_Equip_Gem(nIndex)

	if( this:IsVisible() ) then
		if nIndex == 1 then
			if Identify_Item ~= -1 and g_IsIdentified == 1  then
				IdentifyTwice_SendConfirm(nIndex,2)
				return
			end
			if(Identify_Item ~= -1) then
				LifeAbility : Lock_Packet_Item(Identify_Item,0);
				IdentifyTwice_Object1 : SetActionItem(-1);
				IdentifyTwice_Object2:SetProperty("Image","")
				Identify_Item	= -1;
				IdentifyTwice_DemandMoney : SetProperty("MoneyNumber", 0);
				--push事件干掉msgbox
				LifeAbility:CloseReIdentifyMsgBox();
				IdentifyTwice_qualityInfo1:SetText("")
				IdentifyTwice_qualityInfo2:SetText("")
				IdentifyTwice_Arrow1:SetProperty("Image","")
				IdentifyTwice_Arrow2:SetProperty("Image","")
				IdentifyTwice_Arrow3:SetProperty("Image","")
				IdentifyTwice_Try:Disable()
			end
			IdentifyTwice_UpDateTiXing()
		end
	end

end

function Identify_Frame_On_ResetPos()
--  Identify_Frame:SetProperty("UnifiedPosition", g_Identify_Frame_UnifiedPosition);
end


function IdentifyTwice_SaveChange_Clicked()

	if g_IsIdentified ==1 then

 		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("DoRefreshEquipZiZhi");
			Set_XSCRIPT_ScriptID(809261);
			Set_XSCRIPT_Parameter(0,Identify_Item);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

		--设置重洗状态
	g_IsIdentified =0

	IdentifyTwice_Clear(0)
	IdentifyTwice_Update(Identify_Item)
end

--二次确认
--发送二次确认
function IdentifyTwice_SendConfirm(nIndex,keepopen)
	PushEvent("EQUIP_ZIZHI_RECOIN_CONFIRM",tostring(nIndex),tostring(keepopen))
end
