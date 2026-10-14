
local g_ShengJie_WeaponIndex = -1;	--	契合神器背包中的索引
local SHENGQI_EQUIPSLOT;		--	契合物品框
local SHENGQI_MONEYREQ;
local SHENGQI_JIAOZICUR;
local SHENGQI_MONEYCUR;

local SHENGQI_EQUIPJIE;
local SHENGQI_MATSLOT;
local SHENGQI_MATCNT_REQ;
local g_SuperWeapon9_ShengJie_UnifiedPos;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;


function SuperWeapon9_ShengJie_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SUPERWEAPON9_SHENGJIE");--放入
	this:RegisterEvent("SUPERWEAPON9_DRAGEND");--挪出
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
end

function SuperWeapon9_ShengJie_OnLoad()
	SHENGQI_EQUIPSLOT = SuperWeapon9_ShengJie_Item1;
	SHENGQI_MONEYREQ = SuperWeapon9_ShengJie_CashNum;
	SHENGQI_JIAOZICUR = SuperWeapon9_ShengJie_JiaoZiNum;
	SHENGQI_MONEYCUR = SuperWeapon9_ShengJie_CashMoney;
	SHENGQI_EQUIPJIE = SuperWeapon9_ShengJie_Explain6;
	SHENGQI_MATSLOT = SuperWeapon9_ShengJie_Item2;
	SHENGQI_MATCNT_REQ = SuperWeapon9_ShengJie_Explain7;
	g_SuperWeapon9_ShengJie_UnifiedPos = SuperWeapon9_ShengJie_Frame:GetProperty("UnifiedPosition");
	
	--【九星神器引导任务】神器锻灵
	SuperWeapon9_ShengJie_Item1_Animate:Play(false)
	SuperWeapon9_ShengJie_OK_Animate:Play(false)	
end

function SuperWeapon9_ShengJie_OnEvent(event)

	if event == "UI_COMMAND" then
		if tonumber(arg0) == 7020062 then
			local bOpen = Get_XParam_INT(0);
			if bOpen==1 then
				local TargetServerID = Get_XParam_INT(1);
				g_ObjCared = DataPool:GetNPCIDByServerID(TargetServerID);
				if g_ObjCared==-1 then
					return
				end
				this:CareObject(g_ObjCared, 1, "SuperWeapon9_ShengJie");
				SuperWeapon9_ShengJie_ResetActionSlot();
				SuperWeapon9_ShengJie_UpdataMoney()
				
				--【九星神器引导任务】神器锻灵
				if DataPool:Lua_IsHaveMission(1951) > 0 then
					CloseFreshManGuide()
					local misIndex = DataPool:GetPlayerMissionIndexByID(1951)
					local Have_JiHuo = 0
					if DataPool:GetPlayerMission_Variable(misIndex, 1) == 1 then
						Have_JiHuo = 1
					end					
					local HaveItem = SHENGQI_EQUIPSLOT:GetActionItem()
					if HaveItem < 0 then
						if Have_JiHuo == 0 then
							local fX, fY = this:GetChildOffset("SuperWeapon9_ShengJie_Item1")			
							OpenFreshManGuide(1, 195, fX+30, fY, "SuperWeapon9_ShengJie", "northeast")
							SuperWeapon9_ShengJie_Item1_Animate:Play(true)
							SuperWeapon9_ShengJie_OK_Animate:Play(false)
						end
					else
						if Have_JiHuo == 0 then
							local fX, fY = this:GetChildOffset("SuperWeapon9_ShengJie_OK")			
							OpenFreshManGuide(1, 196, fX+20, fY, "SuperWeapon9_ShengJie", "northeast")
							SuperWeapon9_ShengJie_Item1_Animate:Play(false)
							SuperWeapon9_ShengJie_OK_Animate:Play(true)					
						end
					end
				end
				
				this:Show()
			elseif bOpen==2 then
				SuperWeapon9_ShengJie_ResetActionSlot();
			elseif bOpen==0 then--关闭界面
				SuperWeapon9_ShengJie_CancleEvent();
			end
		return;
		end
	end

	
	if event == "SUPERWEAPON9_SHENGJIE" and this:IsVisible() then
		if arg0 ~= nil then
			local nIndex = tonumber(arg0);
			SuperWeapon9_ShengJie_UpDataSlot(nIndex)			
			return;
		end
	elseif event =="SUPERWEAPON9_DRAGEND" and this:IsVisible() then
		if arg0 ~= nil and tonumber(arg0)==18 then
			SuperWeapon9_ShengJie_ResetActionSlot()
		end
	end

	if event == "OBJECT_CARED_EVENT" then
		if(g_ObjCared ~= objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			--取消关心
			this:CareObject(g_ObjCared, 0, "SuperWeapon9_ShengJie");
			g_ObjCared = -1;
		end
	end

	if event == "ADJEST_UI_POS" and this:IsVisible() then
		SuperWeapon9_ShengJie_ResetWindow();
	elseif event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible() then
		SuperWeapon9_ShengJie_ResetWindow()
	elseif event == "MONEY_CHANGE_EX" and this:IsVisible() then
		SuperWeapon9_ShengJie_UpdataMoney()
	elseif event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		SuperWeapon9_ShengJie_UpdataMoney()
	end

	if event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then
		if arg0==nil or tonumber(arg0)==-1 then
			return
		end
		if tonumber(arg0)==g_ShengJie_WeaponIndex then
			local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(g_ShengJie_WeaponIndex));
			if nByQual>100 then
				local nFit = math.mod(nByQual,100)
				if nFit>=20 then
					SuperWeapon9_ShengJie_ResetActionSlot()
					return
				end
			end
		end

--		SuperWeapon9_ShengJie_UpdataFrame();
		SuperWeapon9_ShengJie_UpdataMat()
		return;
	end

end

function SuperWeapon9_ShengJie_ResetActionSlot()
	if g_ShengJie_WeaponIndex > -1 then
		LifeAbility : Lock_Packet_Item(g_ShengJie_WeaponIndex, 0)
		SHENGQI_EQUIPSLOT:SetActionItem(-1);
		g_ShengJie_WeaponIndex = -1;
		--【九星神器引导任务】神器锻灵
		if DataPool:Lua_IsHaveMission(1951) > 0 then
			CloseFreshManGuide()
			local misIndex = DataPool:GetPlayerMissionIndexByID(1951)
			local Have_JiHuo = 0
			if DataPool:GetPlayerMission_Variable(misIndex, 1) == 1 then
				Have_JiHuo = 1
			end					
			local HaveItem = SHENGQI_EQUIPSLOT:GetActionItem()
			if HaveItem < 0 then
				if Have_JiHuo == 0 then
					local fX, fY = this:GetChildOffset("SuperWeapon9_ShengJie_Item1")			
					OpenFreshManGuide(1, 195, fX+30, fY, "SuperWeapon9_ShengJie", "northeast")
					SuperWeapon9_ShengJie_Item1_Animate:Play(true)
					SuperWeapon9_ShengJie_OK_Animate:Play(false)
				end
			else
				if Have_JiHuo == 0 then
					local fX, fY = this:GetChildOffset("SuperWeapon9_ShengJie_OK")			
					OpenFreshManGuide(1, 196, fX+20, fY, "SuperWeapon9_ShengJie", "northeast")
					SuperWeapon9_ShengJie_Item1_Animate:Play(false)
					SuperWeapon9_ShengJie_OK_Animate:Play(true)					
				end
			end
		end			
	end
	SuperWeapon9_ShengJie_UpdataMat()
end

function SuperWeapon9_ShengJie_CancleEvent()
	SuperWeapon9_ShengJie_ResetActionSlot()
	SuperWeapon9_ShengJie_UpdataMat()
	this:CareObject(g_ObjCared, 0, "SuperWeapon9_ShengJie");
	g_ObjCared = -1;

	--【九星神器引导任务】神器锻灵
	CloseFreshManGuide() 
	SuperWeapon9_ShengJie_Item1_Animate:Play(false)
	SuperWeapon9_ShengJie_OK_Animate:Play(false)
	
	this:Hide();
end

function SuperWeapon9_ShengJie_OK()
	if g_ShengJie_WeaponIndex < 0 then
		PushDebugMessage("#{JXSQ_170804_39}")
		return
	end

	--mission check server

	if SuperWeapon9_ShengJie_SuperWeaponCheck(g_ShengJie_WeaponIndex)==0 then
		return
	end
	--道具检测
	--所需材料数量
	local nMaterialCount = PlayerPackage:GetSuperWeaponAdvanceMaterialCount(g_ShengJie_WeaponIndex);
	local nPlayerItemNum=0
	for i=1,6 do
		local nMaterialID = PlayerPackage:GetSuperWeaponAdvanceMaterialID(g_ShengJie_WeaponIndex, i-1);
		if nMaterialID>0 then
			nPlayerItemNum = nPlayerItemNum + PlayerPackage:CountAvailableItemByIDTable(nMaterialID)
		end
	end
	if  nPlayerItemNum < nMaterialCount then
		local str = ScriptGlobal_Format("#{JXSQ_170804_43}", nMaterialCount)
		PushDebugMessage(str)
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeapon9Up")
		Set_XSCRIPT_ScriptID(702006)
		Set_XSCRIPT_Parameter(0, 2)
		Set_XSCRIPT_Parameter(1, g_ShengJie_WeaponIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	--【九星神器引导任务】神器锻灵
	CloseFreshManGuide() 
	SuperWeapon9_ShengJie_Item1_Animate:Play(false)
	SuperWeapon9_ShengJie_OK_Animate:Play(false)	
end

function SuperWeapon9_ShengJie_UpdataMoney()
	--	玩家身上的钱
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")

	SHENGQI_JIAOZICUR:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
	SHENGQI_MONEYCUR:SetProperty("MoneyNumber", nPlayerCashMoney);
end

function SuperWeapon9_ShengJie_UpdataMat()
	if g_ShengJie_WeaponIndex < 0 then
		SHENGQI_MONEYREQ:SetProperty("MoneyNumber", 0);
		SHENGQI_EQUIPJIE:SetText("")
		SHENGQI_MATSLOT:SetActionItem(-1);
		SHENGQI_MATCNT_REQ:SetProperty("Text", "")
		return
	end

	local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(g_ShengJie_WeaponIndex))
	local nFit = math.mod(nByQual,100);
	SHENGQI_EQUIPJIE:SetText(nFit .. "/20")
	if nFit>=20 then
		SHENGQI_MONEYREQ:SetProperty("MoneyNumber", 0);
		SHENGQI_EQUIPJIE:SetText("")
		SHENGQI_MATSLOT:SetActionItem(-1);
		SHENGQI_MATCNT_REQ:SetProperty("Text", "")
		return
	end
	--获取契合金钱
	local nCashCount = PlayerPackage:GetSuperWeaponAdvanceCashCost(g_ShengJie_WeaponIndex);
	SHENGQI_MONEYREQ:SetProperty("MoneyNumber", nCashCount);
	--所需材料数量
	local nMaterialCount = PlayerPackage:GetSuperWeaponAdvanceMaterialCount(g_ShengJie_WeaponIndex);
	local nPlayerItemNum=0
	for i=1,6 do
		local nMaterialID = PlayerPackage:GetSuperWeaponAdvanceMaterialID(g_ShengJie_WeaponIndex, i-1);
		if nMaterialID>0 then
			nPlayerItemNum = nPlayerItemNum + PlayerPackage:CountAvailableItemByIDTable(nMaterialID)
		end
	end
	if nMaterialCount > nPlayerItemNum then
		--strMaterialCount = "#cFF0000"
		SHENGQI_MATCNT_REQ:SetProperty("TextColor", "ffff0000")
	else
		--strMaterialCount = "#cFFFFFF"
		SHENGQI_MATCNT_REQ:SetProperty("TextColor", "ff00ff00")--绿色
	end
--	SHENGQI_MATCNT_REQ:SetText(nMaterialCount)
	SHENGQI_MATCNT_REQ:SetProperty("Text", nMaterialCount )

	--	获取材料物品ID
	local nMaterialID = PlayerPackage:GetSuperWeaponAdvanceMaterialID(g_ShengJie_WeaponIndex, 0);
	--虚拟道具
	local ProductAction = DoubleGem:UpdateProductAction(nMaterialID)
	if ProductAction and ProductAction:GetID() ~= 0 then
		SHENGQI_MATSLOT:SetActionItem(ProductAction:GetID());
	end
end

function SuperWeapon9_ShengJie_SuperWeaponCheck(nIndex)
	if nIndex < 0 then
		return 0
	end

	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() == 0 then
		PushDebugMessage("#{JXSQ_170804_39}")
		return 0
	end
	--检测
	local EquipPoint = LifeAbility:Get_Equip_Point(nIndex)
	if EquipPoint~=0 then
		PushDebugMessage("#{JXSQ_170804_39}")
		return 0
	end
	--	检测物品等级
	local nEquipLevel = LifeAbility : Get_Equip_Level(nIndex);
	if nEquipLevel ~= 102 then
		PushDebugMessage("#{JXSQ_170804_39}")
		return 0
	end
	--	检测物品星级（品质）
	local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
	if nByQual>100 then
		--local starNum = 8
		local nFit = math.mod(nByQual,100)
		if nFit>=20 then
			PushDebugMessage("#{JXSQ_170804_42}")
			return 0
		end
	else
		PushDebugMessage("#{JXSQ_170804_39}")
		return 0
	end
	--	检测物品是否可契合
	local ret = LifeAbility : CheckSuperWeaponCanAdvance(nIndex)
	if ret < 0 then
		PushDebugMessage("#{JXSQ_170804_39}")
		return 0
	end
	return 1
end

function SuperWeapon9_ShengJie_UpDataSlot(nIndex)

	if SuperWeapon9_ShengJie_SuperWeaponCheck(nIndex)==0 then
		return
	end

	--可以放入了
	--	设置物品并锁定
	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() == 0 then
		return
	end
	SHENGQI_EQUIPSLOT:SetActionItem(theAction:GetID());
	if g_ShengJie_WeaponIndex > -1 then
		LifeAbility : Lock_Packet_Item(g_ShengJie_WeaponIndex, 0)
	end
	g_ShengJie_WeaponIndex = nIndex;
	LifeAbility : Lock_Packet_Item(g_ShengJie_WeaponIndex, 1)

	SuperWeapon9_ShengJie_UpdataMat()

	--【九星神器引导任务】神器锻灵
	if DataPool:Lua_IsHaveMission(1951) > 0 then
		CloseFreshManGuide()
		local misIndex = DataPool:GetPlayerMissionIndexByID(1951)
		local Have_JiHuo = 0
		if DataPool:GetPlayerMission_Variable(misIndex, 1) == 1 then
			Have_JiHuo = 1
		end	
		if Have_JiHuo == 0 then
			local fX, fY = this:GetChildOffset("SuperWeapon9_ShengJie_OK")			
			OpenFreshManGuide(1, 196, fX+20, fY, "SuperWeapon9_ShengJie", "northeast")
			SuperWeapon9_ShengJie_Item1_Animate:Play(false)
			SuperWeapon9_ShengJie_OK_Animate:Play(true)	
		end
	end		
end

function SuperWeapon9_ShengJie_ResetWindow()
	SuperWeapon9_ShengJie_Frame:SetProperty("UnifiedPosition", g_SuperWeapon9_ShengJie_UnifiedPos);
end

--【九星神器引导任务】神器锻灵
function SuperWeapon9_ShengJie_OnMoved()
   if "SuperWeapon9_ShengJie" == GetFreshManGuideOwner() then
        OpenFreshManGuide(2, -1, -1, -1)
   end
end
