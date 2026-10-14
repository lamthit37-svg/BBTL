local g_SuperWeaponSoulless_WeaponSlot;
local g_SuperWeaponSoulless_WeaponIndex = -1;

local g_SuperWeaponSoulless_CashCost;
local g_SuperWeaponSoulless_PlayerCashJiaoZi;
local g_SuperWeaponSoulless_PlayerCash;

local g_SuperWeaponSoulless_Frame_DefaultPos;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;
local g_TargetServerID = -1;
local g_IsConfirm = -1;			--	是否二次确认过

-- 神器区段
local g_EQUIP_SHENQI_BEGIN = 10300000
local g_EQUIP_SHENQI_END = 10399999

function SuperWeaponSoulless_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SUPERWEAPONSOULLESS_PUTWEAPON");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	--	进场景关闭界面
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("SUPERWEAPONSOULLESS_SENDMSG");
end

function SuperWeaponSoulless_OnLoad()
	g_SuperWeaponChange_Fram_UnifiedPosition = SuperWeaponSoulless_Frame:GetProperty("UnifiedPosition");
	g_SuperWeaponSoulless_WeaponSlot = SuperWeaponSoulless_Object;
	g_SuperWeaponSoulless_CashCost = SuperWeaponSoulless_DemandMoney;
	g_SuperWeaponSoulless_PlayerCashJiaoZi = SuperWeaponSoulless_SelfJiaozi;
	g_SuperWeaponSoulless_PlayerCash = SuperWeaponSoulless_SelfMoney;
end

function SuperWeaponSoulless_OnEvent(event)
	local objCared = DataPool:GetCurDialogNpcId();
	if event == "UI_COMMAND" then
		if tonumber(arg0) == 201208098 then	
			g_ObjCared = objCared;	
			g_TargetServerID = Get_XParam_INT(0);
			-- 借用一下这个UICommand加二次确认逻辑 第二个参数0为关闭，1为刷新打开，2为二次确认
			local nParam2 = Get_XParam_INT(1)
			if nil ~= nParam2 and 0 == nParam2 then
				SuperWeaponSoulless_CancleEvent()
				return
			end
			
			if nil ~= nParam2 and 2 == nParam2 and g_SuperWeaponSoulless_WeaponIndex >= 0 then
				nXuanBingStoneNum = PlayerPackage:GetSuperWeaponQualityDownMaterialNum(g_SuperWeaponSoulless_WeaponIndex, 2);
				PushEvent("SUPERWEAPONSOULLESS_CONFIRM", nXuanBingStoneNum)
				return
			end
			this:CareObject(objCared, 1, "SuperWeaponSoulless");
			SuperWeaponSoulless_UpdataFrame();
			this:Show();
			return;
		end

		SuperWeaponSoulless_CancleEvent();
		return;
	end
	
	if event == "SUPERWEAPONSOULLESS_PUTWEAPON" then
		if arg0 ~= nil then
			local nSlot = tonumber(arg0);
			local nIndex = tonumber(arg1);
			SuperWeaponSoulless_UpDataSlot(nSlot, nIndex);
			SuperWeaponSoulless_UpdataFrame();
		end
		return;
	end

	if event == "OBJECT_CARED_EVENT" then
		if g_ObjCared ~= objCared then
			return;
		end

		if (arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1 == "destroy") then
			SuperWeaponSoulless_CancleEvent();
		end
		return;
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		SuperWeaponSoulless_CancleEvent();
		return;
	end

	if event == "MONEY_CHANGE_EX" then
		SuperWeaponSoulless_UpdataFrame();
		return;
	end

	if event == "MONEYJZ_CHANGE_EX" then
		SuperWeaponSoulless_UpdataFrame();
		return;
	end

	if event == "ADJEST_UI_POS" then
		SuperWeaponSoulless_Frame:SetProperty("UnifiedPosition", g_SuperWeaponChange_Fram_UnifiedPosition);
		return;
	end

	if event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeaponSoulless_Frame:SetProperty("UnifiedPosition", g_SuperWeaponChange_Fram_UnifiedPosition);
		return;
	end

	if event == "SUPERWEAPONSOULLESS_SENDMSG" then
		g_IsConfirm = 1;
		return;
	end
end

function SuperWeaponSoulless_ResetWeaponSlot()
	g_IsConfirm = -1;
	if g_SuperWeaponSoulless_WeaponIndex > -1 then
		LifeAbility : Lock_Packet_Item(g_SuperWeaponSoulless_WeaponIndex, 0);
		g_SuperWeaponSoulless_WeaponSlot:SetActionItem(-1);
		g_SuperWeaponSoulless_WeaponIndex = -1;
	end

	SuperWeaponSoulless_UpdataFrame()
end

function SuperWeaponSoulless_SendConfirmMsg()
	if g_SuperWeaponSoulless_WeaponIndex < 0 then
		PushDebugMessage("#{SQSX_120806_85}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeaponStartUpAction")
		Set_XSCRIPT_ScriptID(890009)
		Set_XSCRIPT_Parameter(0, 5)
		Set_XSCRIPT_Parameter(1, g_SuperWeaponSoulless_WeaponIndex)
		Set_XSCRIPT_Parameter(2, g_TargetServerID)
		Set_XSCRIPT_Parameter(3, g_IsConfirm)
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT()
end

function SuperWeaponSoulless_OKEvent()
	if g_SuperWeaponSoulless_WeaponIndex < 0 then
		g_IsConfirm = -1;
		PushDebugMessage("#{SQSX_120806_85}")
		return
	end

	--	你们就玩我吧，娘的。每次都死按照文档的要求来，就不知道想明白？
	local nMoneyCost = PlayerPackage:GetSuperWeaponQualityDownMoneyCost(g_SuperWeaponSoulless_WeaponIndex);
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")
	if nMoneyCost > nPlayerCashJiaoZi + nPlayerCashMoney then
		PushDebugMessage("#{SQSX_120806_79}")
		return
	end
	
	SuperWeaponSoulless_SendConfirmMsg()

	--	该死的二次确认流程。。。。。。
	--	哥们真后悔啊
	-- if g_IsConfirm < 0 then
		-- nXuanBingStoneNum = PlayerPackage:GetSuperWeaponQualityDownMaterialNum(g_SuperWeaponSoulless_WeaponIndex, 2);
		-- PushEvent("SUPERWEAPONSOULLESS_CONFIRM", nXuanBingStoneNum)
		-- return
	-- end

	-- if g_IsConfirm > 0 then
		-- SuperWeaponSoulless_SendConfirmMsg()
	-- end
end

function SuperWeaponSoulless_CancleEvent()
	SuperWeaponSoulless_ResetWeaponSlot();
	SuperWeaponSoulless_UpdataFrame();
	this:CareObject(g_ObjCared, 0, "SuperWeaponSoulless");
	g_ObjCared = -1;
	g_TargetServerID = -1;
	this:Hide();
end

function SuperWeaponSoulless_UpdataMoney()
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")
	local nMoneyCost = 0;

	g_SuperWeaponSoulless_PlayerCashJiaoZi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
	g_SuperWeaponSoulless_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);

	if g_SuperWeaponSoulless_WeaponIndex > -1 then
		nMoneyCost = PlayerPackage:GetSuperWeaponQualityDownMoneyCost(g_SuperWeaponSoulless_WeaponIndex);
		if nMoneyCost < 0 then
			nMoneyCost = 0;
		end
	end

	g_SuperWeaponSoulless_CashCost:SetProperty("MoneyNumber", nMoneyCost);
end

function SuperWeaponSoulless_UpdataFrame()
	SuperWeaponSoulless_UpdataMoney();

	--	更新石头数量
	local nXuanBingStoneNum = 0
	local nJuLingStoneNum = 0

	if g_SuperWeaponSoulless_WeaponIndex > -1 then
		nXuanBingStoneNum = PlayerPackage:GetSuperWeaponQualityDownMaterialNum(g_SuperWeaponSoulless_WeaponIndex, 2);
		nJuLingStoneNum = PlayerPackage:GetSuperWeaponQualityDownMaterialNum(g_SuperWeaponSoulless_WeaponIndex, 1);

		if nXuanBingStoneNum < 0 then
			nXuanBingStoneNum = 0;
		end

		if nJuLingStoneNum < 0 then
			nJuLingStoneNum = 0;
		end
	end

	SuperWeaponSoulless_Explain_Text3:SetProperty("Text", nXuanBingStoneNum)
	SuperWeaponSoulless_Explain_Text5:SetProperty("Text", nJuLingStoneNum)
end

function SuperWeaponSoulless_ItemCheck(nIndex)

	local nItemTableIndex = PlayerPackage:GetItemTableIndex(nIndex)
	local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex))
	-- 神器 
	if nItemTableIndex >= g_EQUIP_SHENQI_BEGIN and nItemTableIndex <= g_EQUIP_SHENQI_END then
		-- 九星神器和解蒙神器判断 开蒙8星为[101,120],九星为9
		if (nByQual >= 101 and nByQual <= 120) or 9 == nByQual then
			PushDebugMessage("#{JXSQ_170829_286}")
			return 0
		end
	else
		-- 不是神器
		PushDebugMessage("#{SQSX_120806_75}")
		return 0
	end

	--	是否是神器  --- 这是一个假的接口，不是纯正的神器判断，只是一部分配表中的神器，其他地方不要借鉴和使用
	local ret = PlayerPackage : CheckIsSuperWeapon(nIndex)
	if ret < 0 then
		PushDebugMessage("#{SQSX_120806_75}")
		return 0
	end
	
	--	是否通灵
	if nByQual > 100 then
		PushDebugMessage("#{SQSX_120806_75}")
		return 0
	end
	if nByQual < 10 then
		PushDebugMessage("#{SQSX_120806_76}")
		return 0
	end
	--	是否加锁
	if (PlayerPackage:IsLock(nIndex) == 1) then
		PushDebugMessage("#{SQSX_120806_77}")
		return 0
	end
	
	--	是否安全时间
	ret = DataPool:GetLeftProtectTime()
	if ret > 0 then
		PushDebugMessage("#{SQSX_120806_78}")
		return 0
	end
	--	电话密保
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return 0
	end

	--	判断玩家金钱	操，加了再去掉，说了不加，就是不听
--	local nMoneyCost = PlayerPackage:GetSuperWeaponQualityDownMoneyCost(nIndex);
--	local nPlayerCashMoney = Player:GetData("MONEY");
--	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")
--	if nMoneyCost > nPlayerCashJiaoZi + nPlayerCashMoney then
--		PushDebugMessage("#{SQSX_120806_79}")
--		return 0
--	end	

	return 1
end

function SuperWeaponSoulless_UpDataSlot(nSlot, nIndex)
	if nSlot ~= 9 then
		return
	end

	if nIndex < 0 then
		return
	end

	local ret = SuperWeaponSoulless_ItemCheck(nIndex)
	if ret < 1 then
		return
	end

	g_IsConfirm = -1;
	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));

		if g_SuperWeaponSoulless_WeaponIndex > -1 then
			LifeAbility : Lock_Packet_Item(g_SuperWeaponSoulless_WeaponIndex, 0)
		end

		--	设置物品并锁定
		g_SuperWeaponSoulless_WeaponSlot:SetActionItem(theAction:GetID());
		g_SuperWeaponSoulless_WeaponIndex = nIndex;
		LifeAbility : Lock_Packet_Item(g_SuperWeaponSoulless_WeaponIndex, 1)
	end
end
