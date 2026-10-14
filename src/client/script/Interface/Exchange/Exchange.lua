local g_InitiativeClose = 0;

--主动关闭窗口的一个标志
local g_CloseSign;		-- 

--button的个数
local BUTTON_NUMBER = 5;
--自己的
local SELF_BUTTON = {};
local SELF_TEXT = {};
--对方的
local OTHER_BUTTON = {};
local OTHER_TEXT = {};

local objCared = -1;
local MAX_OBJ_DISTANCE = 6.0;

--交易能放入的最多的宠物数量
local MAX_PET_NUM  = 5;
local g_nSelfPetID = {};				--宠物ID表
local g_nOtherPetID = {};				--宠物ID表

local g_LastLockTime = 0;
local LOCK_TIME_DIFF = 10000           --10秒

local g_money_modify_num = 0;
local g_money_modify_num_other = 0;

local g_Exchange_Frame_UnifiedPosition;

--窗口最初的高度
local g_Exchange_Frame_UnifedSize_Original;
local g_Exchange_Frame_Height_Kserver = "{0.0,320}";

--===============================================
-- OnLoad()
--===============================================
function Exchange_PreLoad()

	this:RegisterEvent("OPEN_EXCHANGE_FRAME",true);
	this:RegisterEvent("UPDATE_EXCHANGE",false);
	this:RegisterEvent("CANCEL_EXCHANGE",false);
	this:RegisterEvent("SUCCEED_EXCHANGE_CLOSE",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("RELIVE_SHOW",false);
	this:RegisterEvent("ACCELERATE_KEYSEND",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("EXCHANGE_ENABLE_ACCBTN",false);	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("EXCHANGE_OPTIMIZATION",false)
	this:RegisterEvent("EXCHANGE_OPTIMIZATION_MONEY",false)
	this:RegisterEvent("TRADE_CONFIRMED",false)

end

function Exchange_OnLoad()
	
	SELF_BUTTON[1] = Self_Exchange_Item1;
	SELF_BUTTON[2] = Self_Exchange_Item2;
	SELF_BUTTON[3] = Self_Exchange_Item3;
	SELF_BUTTON[4] = Self_Exchange_Item4;
	SELF_BUTTON[5] = Self_Exchange_Item5;
	SELF_BUTTON[6] = Self_Exchange_Item6;
	
	SELF_TEXT[1] = Self_Exchange_Item_Text1;
	SELF_TEXT[2] = Self_Exchange_Item_Text2;
	SELF_TEXT[3] = Self_Exchange_Item_Text3;
	SELF_TEXT[4] = Self_Exchange_Item_Text4;
	SELF_TEXT[5] = Self_Exchange_Item_Text5;
	SELF_TEXT[6] = Self_Exchange_Item_Text6;
	
	OTHER_BUTTON[1] = Other_Exchange_Item1;
	OTHER_BUTTON[2] = Other_Exchange_Item2;
	OTHER_BUTTON[3] = Other_Exchange_Item3;
	OTHER_BUTTON[4] = Other_Exchange_Item4;
	OTHER_BUTTON[5] = Other_Exchange_Item5;
	OTHER_BUTTON[6] = Other_Exchange_Item6;

	OTHER_TEXT[1] = Other_Exchange_Item_Text1;
	OTHER_TEXT[2] = Other_Exchange_Item_Text2;
	OTHER_TEXT[3] = Other_Exchange_Item_Text3;
	OTHER_TEXT[4] = Other_Exchange_Item_Text4;
	OTHER_TEXT[5] = Other_Exchange_Item_Text5;
	OTHER_TEXT[6] = Other_Exchange_Item_Text6;
	
	for i=0, MAX_PET_NUM    do
		g_nSelfPetID[i] = -1;
		g_nOtherPetID[i] = -1
	end
	
	 g_Exchange_Frame_UnifiedPosition=Exchange_Frame:GetProperty("UnifiedPosition");
	 g_Exchange_Frame_UnifedSize_Original = Exchange_Frame:GetProperty("UnifiedSize")

end

--===============================================
-- OnEvent()
--===============================================
function Exchange_OnEvent(event)

	if(event == "OPEN_EXCHANGE_FRAME") then
		--关心NPC
		objCared = tonumber(arg0);
		this:CareObject(objCared, 1, "Exchange");
		ExchangeValidate_StopWatch1:SetProperty("Timer", "300");
		g_InitiativeClose = 0;
		--ajustFrame according to Kserver or not
		local isKvKSever = tonumber(arg1)
		Exchange_UpdateFrame_AjustFrame(isKvKSever)
		--Update
		Exchange_UpdateFrame();
		Exchange_Checkbox_other_Locked:Disable();
		Exchange_Frame:SetProperty("UnifiedXPosition","{0.0,0}");
		Exchange_Frame:SetProperty("UnifiedYPosition","{0.12,0}");
		CloseWindow("Packet_Temporary", true)		
		this:Show();
		
	elseif(event == "UPDATE_EXCHANGE") then
		Exchange_UpdateFrame();
		
	elseif(evnet == "CANCEL_EXCHANGE") then
		g_InitiativeClose = 1;
		Exchange_Optimise_Close_Window()
		this:Hide();
		Exchange:CloseExchangeInfo();
		--取消关心
		this:CareObject(objCared, 0, "Exchange");
		
	elseif(event == "SUCCEED_EXCHANGE_CLOSE") then
		g_InitiativeClose = 1;
		Exchange_Optimise_Close_Window()
		this:Hide();
		Exchange:CloseExchangeInfo();
		--取消关心
		this:CareObject(objCared, 0, "Exchange");
	
	--死亡的时候需要取消交易
	elseif(event == "RELIVE_SHOW" and this:IsVisible()) then
		g_InitiativeClose = 1;
		Exchange_Optimise_Close_Window()
		this:Hide();
		Exchange:CloseExchangeInfo();
		--取消关心
		this:CareObject(objCared, 0, "Exchange");
		
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			g_InitiativeClose = 1;
			Exchange_Optimise_Close_Window()
			this:Hide();
			Exchange:CloseExchangeInfo();
			
			--取消关心
			this:CareObject(objCared, 0, "Exchange");
		end
	
	elseif( event == "ACCELERATE_KEYSEND" and this:IsVisible()) then
		Exchange_Optimise_Close_Window()
		this:Hide();
		Exchange:CloseExchangeInfo();
		--取消关心
		this:CareObject(objCared, 0, "Exchange");
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Exchange_Optimise_Close_Window()
		this:Hide();
		Exchange:CloseExchangeInfo();
		--取消关心
		this:CareObject(objCared, 0, "Exchange");
	end

	if event == "EXCHANGE_ENABLE_ACCBTN" then	--服务端返回验证是否通过....

		if not this:IsVisible() then
			return;
		end
		Exchange_UpdateFrame();
	end
	
	if (event == "ADJEST_UI_POS" ) then
		Exchange_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Exchange_Frame_On_ResetPos()
	end

	if ( event == "EXCHANGE_OPTIMIZATION" ) then
		Exchange_Update_OptimizeText(arg0)
	end

	if ( event == "EXCHANGE_OPTIMIZATION_MONEY" ) then
		Exchange_Update_OptimizeText_Money(arg0)
	end
	
	if ( event == "TRADE_CONFIRMED" ) then
		Trade_Accept_Button_Clicked(0)
	end
	
end

--===============================================
-- 更新界面
--===============================================
function Exchange_UpdateFrame()

	--交易双方的名字
	--自己的
	Exchange_SelfName:SetText(Player:GetName());
	
	--对方的
	Exchange_OtherName:SetText("#b#c0000FF#effffff"..Exchange:GetOthersName());
	
	-- 门派
	local menpai = Exchange:GetOthersInfo("menpai")
	local strMenpai = "";

	-- 得到门派名称.
	if(0 == menpai) then
		strMenpai = "#{WJJY_231123_02}";

	elseif(1 == menpai) then
		strMenpai = "#{WJJY_231123_03}";

	elseif(2 == menpai) then
		strMenpai = "#{WJJY_231123_04}";

	elseif(3 == menpai) then
		strMenpai = "#{WJJY_231123_23}";

	elseif(4 == menpai) then
		strMenpai = "#{WJJY_231123_05}";

	elseif(5 == menpai) then
		strMenpai = "#{WJJY_231123_06}";

	elseif(6 == menpai) then
		strMenpai = "#{WJJY_231123_07}";

	elseif(7 == menpai) then
		strMenpai = "#{WJJY_231123_08}";

	elseif(8 == menpai) then
		strMenpai = "#{WJJY_231123_09}";

	elseif(9 == menpai) then
		strMenpai = "无门派";

	elseif(10== menpai) then
		strMenpai = "#{WJJY_231123_10}";

	elseif(11== menpai) then
		strMenpai = "#{WJJY_231123_11}";
		
	elseif(12== menpai) then
		strMenpai = "#{WJJY_231123_12}";
		
	elseif(13== menpai) then
		strMenpai = "#{WJJY_231123_13}";--桃花岛
	
	elseif(14== menpai) then
		strMenpai = "#{WJJY_231123_14}";	
	elseif(15== menpai) then--menpai15 mptodo
		strMenpai = "#{WJJY_231123_24}";	
	end

	Other_Exchange_ItemInfo_MP:SetText(ScriptGlobal_Format("#{WJJY_231123_01}",strMenpai))
	Other_Exchange_ItemInfo_DJ:SetText(ScriptGlobal_Format("#{WJJY_231123_16}",Exchange:GetOthersInfo("level")))

	if Exchange:GetOthersInfo("guildid") < 0 then
		Other_Exchange_ItemInfo_BH:SetText(ScriptGlobal_Format("#{WJJY_231123_17}", "#{WJJY_231123_18}"))
	else
		Other_Exchange_ItemInfo_BH:SetText(ScriptGlobal_Format("#{WJJY_231123_17}", Exchange:GetOthersInfo("guildname")))
	end 
	
	--对方的锁定按钮，（一直不可用）
	Exchange_Other_Locked_Button:Disable();
	--自己的交易按钮，（双方锁定后可用）
	Trade_Accept_Button:Disable();
	
	--======================
	--处理金钱
	local nMoney;
	local nGoldCoin;	
	local nSilverCoin;
	local nCopperCoin;

	--对方的金钱数字
	nMoney,nGoldCoin,nSilverCoin,nCopperCoin = Exchange:GetMoney("other");
	Exchange_Other_Money:SetProperty("MoneyNumber", tostring(nMoney));

	--自己的金钱数字
	nMoney,nGoldCoin,nSilverCoin,nCopperCoin = Exchange:GetMoney("self");
	Exchange_Slfe_Money:SetProperty("MoneyNumber", tostring(nMoney));

	--=======================
	--处理物品
	--自己的
	local nSelfTotalNum = GetActionNum("ex_self");
	--AxTrace(0, 0, "Exchange:nSelfTotalNum =  " .. nSelfTotalNum);
	
	for i=0, BUTTON_NUMBER-1  do

		local theAction = EnumAction(i, "ex_self");

		--AxTrace(0, 0, "Exchange:nActIndex =  " .. i);

		if theAction:GetID() ~= 0 then
			SELF_BUTTON[i+1]:SetActionItem(theAction:GetID());
			SELF_TEXT[i+1]:SetText(theAction:GetName());
		else
			SELF_BUTTON[i+1]:SetActionItem(-1);
			SELF_TEXT[i+1]:SetText("");
		end
	
	end

	--对方的
	local nOtherTotalNum = GetActionNum("ex_other");
	--AxTrace(0, 0, "Exchange:nOtherTotalNum =  " .. nOtherTotalNum);

	for i=0, BUTTON_NUMBER-1  do

		local theAction = EnumAction(i, "ex_other");

		--AxTrace(0, 0, "Bank:nActIndex =  " .. i);

		if theAction:GetID() ~= 0 then
			OTHER_BUTTON[i+1]:SetActionItem(theAction:GetID());
			OTHER_TEXT[i+1]:SetText(theAction:GetName());
		else
			OTHER_BUTTON[i+1]:SetActionItem(-1);
			OTHER_TEXT[i+1]:SetText("");
		end

	end
	
	--=======================
	--处理锁定状态,从数据池获得数据，然后通知界面表现出来
	local bIsSelfLocked = Exchange:IsLocked("self");
	local bIsOtherLocked = Exchange:IsLocked("other");

	--自己的交易按钮，（双方锁定后可用）
	if( bIsSelfLocked == true ) then
		if( bIsOtherLocked == true ) then
			Trade_Accept_Button:Enable();
		end
	end
	
	--自己的
	local bIsSelfLocked = Exchange:IsLocked("self");
	if( bIsSelfLocked == true ) then
		Exchange_Checkbox_Locked:SetCheck(1);
		g_LastLockTime = Exchange:GetTickCount()
		Exchange_Locked_Button:SetText("取消锁定");
	elseif ( bIsSelfLocked == false) then
		Exchange_Checkbox_Locked:SetCheck(0);
		Exchange_Locked_Button:SetText("锁定交易");
	end
	
	--对方的
	if( bIsOtherLocked == true ) then
		Exchange_Checkbox_other_Locked:SetCheck(1);
		Exchange_Other_Locked_Button:SetText("已经锁定");
	elseif ( bIsOtherLocked == false) then
		Exchange_Checkbox_other_Locked:SetCheck(0);
		Exchange_Other_Locked_Button:SetText("尚未锁定");
	end
	
	--=======================
	--处理宠物
	--自己的
	Exchange_Self_PetList:ClearListBox();
	
	--local nNum = Exchange:GetPetNum("self");
	local nIndex = 0;
	for i=1, MAX_PET_NUM     do
		local szPetName = Exchange:EnumPet("self", i-1);
		if( szPetName ~= "" )then
			Exchange_Self_PetList:AddItem(szPetName, nIndex);
			g_nSelfPetID[nIndex] = i-1;
			nIndex = nIndex + 1;
		end
	end
	
	--对方的
	Exchange_Other_PetList:ClearListBox();
	nIndex = 0;
	--local nNum = Exchange:GetPetNum("other");
	for i=1, MAX_PET_NUM      do
		local szPetName = Exchange:EnumPet("other", i-1);
		if( szPetName ~= "" )  then
			Exchange_Other_PetList:AddItem(szPetName, nIndex);
			g_nOtherPetID[nIndex] = i-1;
			nIndex = nIndex+1;
		end
	end

end

--===============================================
-- 窗口关闭执行的   Hidden
--===============================================
function Exchange_Cancel()
	Exchange_Optimise_Close_Window()
	
	Exchange:ExchangeCancel();
	
	Exchange:CloseExchangeInfo()
	--取消关心
	this:CareObject(objCared, 0, "Exchange");

end

function Exchange_ShowDetail()
	Exchange:SetMainTargetOthers();
	Target:Close_Before_TargetEquip_UI();
	Target:SendAskDetail(); 
	--缓存主目标信息
	CacheMainTarget();
	
end
--===============================================
-- 点击锁定
--===============================================
function Exchange_Lock_Button_Clicked()

	local nNowTickCount = Exchange:GetTickCount();
	local bSelfIsLock = Exchange:IsLocked("self");
	
	if (bSelfIsLock == true) then	    --原来是锁定，准备取消锁定
		g_LastLockTime = nNowTickCount;		
	else                               --原来未锁定，准备锁定
		if(g_LastLockTime >0 and (nNowTickCount - g_LastLockTime) < LOCK_TIME_DIFF) then
			Exchange_Checkbox_Locked:SetCheck(0);
			PushDebugMessage("#{JYTX_090303_1}");
			return;
		end
	end
	
	--授权安全模式下需要验证 [7/25/2013 shh][TT]
	if GetAuthorizedSafeFlag() == 1 then
		--角色当前是否要将金钱、珍兽或道具交易给其他玩家 [7/25/2013 shh][TT]
		local isExist = Exchange:IsSendSelfToDest();
		if isExist == 1 and CheckPhoneMibaoAndMinorPassword() == 0 then	--需要验证
			--验证没通过则取消交易
			Exchange_Cancel()
			return
		end
	end

	if bSelfIsLock ~= true then
		Exchange_TradeExchange_Text:Hide()
	end
	
	Exchange:LockExchange();
end


--===============================================
-- 点击交易（同意交易）
--===============================================
function Trade_Accept_Button_Clicked(isconfirm)

	if isconfirm == 1 then
		PushEvent("TRADE_CONFIRM", 1)
		return
	end
	-- local ret = Exchange:BeForbidden()
	-- if ret == 1 then
		-- Exchange_Cancel()
		-- return
	-- end

	--角色当前是否要将金钱、珍兽或道具交易给其他玩家 [7/25/2013 shh][TT]
	local isExist = Exchange:IsSendSelfToDest();
	if isExist == 1 then	--有物品一定验证
		if CheckPhoneMibaoAndMinorPassword() == 0 or Exchange:BeForbidden() == 1 then	--有物品就需要验证
			--验证没通过则取消交易
			Exchange_Cancel()
			return
		end
	else 									--没有物品
		if GetAuthorizedSafeFlag() == 0 and CheckPhoneMibaoAndMinorPassword() == 0 then	--非授权安全模式下需要验证
			--验证没通过则取消交易
			Exchange_Cancel()
			return
		end
	end
	
	Trade_Accept_Button:Disable();
	Exchange:AcceptExchange();

end


--===============================================
-- 打开金钱对话框
--===============================================
function Exchange_Open_InputMoney_Clicked()
	--授权安全模式下需要安全验证 [7/25/2013 shh][TT]
	if GetAuthorizedSafeFlag() == 1 and CheckPhoneMibaoAndMinorPassword() == 0 then	
		return
	end

	Exchange:OpenPetFrame();

end

--===============================================
-- 删除选中的宠物
--===============================================
function Trade_DeletePet_Button_Clicked()
	
	local nIndex = Exchange_Self_PetList:GetFirstSelectItem();
	if(nIndex == -1)    then
		return ;
	end
	Exchange:DelSelectPet(g_nSelfPetID[nIndex]);
	
end 

--===============================================
-- 右键点击
--===============================================
function Exchange_Other_PetList_RClick()
	local nIndex = Exchange_Other_PetList:GetFirstSelectItem();
	
	if(nIndex == -1) then
		return ;
	end
	
	Exchange:ViewPetDesc("other",g_nOtherPetID[nIndex]);
end

--===============================================
-- 右键点击
--===============================================
function Exchange_Self_PetList_RClick()
	local nIndex = Exchange_Self_PetList:GetFirstSelectItem();

	if(nIndex == -1) then
		return ;
	end

	Exchange:ViewPetDesc("self",g_nSelfPetID[nIndex]);	
end

function ExchangeValidate_TimeReach1()
    PushDebugMessage("交易超时，请重新交易。");
    Exchange_Cancel();
	ExchangeValidate_StopWatch1:SetProperty("Timer", "-1"); 

	PushEvent("TRADE_CONFIRM", 0)	
end

function Exchange_Frame_On_ResetPos()
  Exchange_Frame:SetProperty("UnifiedPosition", g_Exchange_Frame_UnifiedPosition);
end

--调整界面
function Exchange_UpdateFrame_AjustFrame(isKvKSever)
	--if isKvKSever~= nil and isKvKSever == 1 then
		--KServer交易需要隐藏珍兽交易格，调整整个界面高度
		--Exchange_Other_Pet:Hide()
		--Exchange_Other_PetList:Hide()
		--Exchange_Self_Pet:Hide()
		--Exchange_Self_PetList:Hide()
		--Exchange_PetCheck:Hide()
		--Trade_DeletePet_Button:Hide()
		--Exchange_Frame:SetProperty("UnifiedHeight", g_Exchange_Frame_Height_Kserver)
	--else
		Exchange_Other_Pet:Show()
		Exchange_Other_PetList:Show()
		Exchange_Self_Pet:Show()
		Exchange_Self_PetList:Show()
		Exchange_PetCheck:Show()
		Trade_DeletePet_Button:Show()
		Exchange_Frame:SetProperty("UnifiedSize", g_Exchange_Frame_UnifedSize_Original)
	--end
end

function Exchange_Update_OptimizeText(isMySelf)
	if isMySelf == "0" then
		Exchange_TradeExchange_Text:Show()
	end

	--if isMySelf == "1" then
		g_LastLockTime = Exchange:GetTickCount()
	--end

	if isMySelf == "1" then
		PushDebugMessage("#{JSJY_160612_8}");
	end
end

function Exchange_Update_OptimizeText_Money(isMySelf)
	if isMySelf == "1" and g_money_modify_num ~= 0 then
		PushDebugMessage("#{JSJY_160612_8}");
		g_LastLockTime = Exchange:GetTickCount()
		return
	end

	if isMySelf == "0" and g_money_modify_num_other ~= 0 then
		Exchange_TradeExchange_Text:Show()
		g_LastLockTime = Exchange:GetTickCount()
		PushEvent("EXCHANGE_OPTIMIZATION_MONEY", 2)
		return
	end

	if isMySelf == "1" and g_money_modify_num == 0 and g_money_modify_num_other == 0 then
		g_money_modify_num = g_money_modify_num + 1
		return
	end

	if isMySelf == "0" and g_money_modify_num == 0 and g_money_modify_num_other == 0 then
		g_money_modify_num_other = g_money_modify_num_other + 1
		return
	end

	if isMySelf == "1" and g_money_modify_num == 0 and g_money_modify_num_other == 1 then
		g_money_modify_num = g_money_modify_num + 1
		return
	end

	if isMySelf == "0" and g_money_modify_num == 1 and g_money_modify_num_other == 0 then
		g_money_modify_num_other = g_money_modify_num_other + 1
		return
	end
end

function Exchange_Optimise_Close_Window()
	Exchange_TradeExchange_Text:Hide()
	g_money_modify_num = 0
	g_money_modify_num_other = 0	
	PushEvent("TRADE_CONFIRM", 0)	
end

