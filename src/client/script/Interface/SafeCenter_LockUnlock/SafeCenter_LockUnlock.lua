--安全中心-加锁解锁-- Manda 2013-8-10

-- 界面的默认相对位置

local PET_MAX_NUMBER = 6+4	--最大珍兽携带上限(包括兽栏)

local g_CurSelect = -1; 
local g_PetIndex = {};

local g_nTheTabIndex = 0;--0：道具栏 1：材料栏
local PACKAGE_BUTTONS_NUM = 60;
local PACKAGE_BUTTONS = {};
local	LOCK_ICON = {};

local g_SafeCenter_LockUnlock_Frame_UnifiedXPosition;
local g_SafeCenter_LockUnlock_Frame_UnifiedYPosition;

function SafeCenter_LockUnlock_PreLoad()
	this:RegisterEvent("OPEN_SAFECENTER_LOCKUNLOCK");
	--刷新背包
	this:RegisterEvent("OPEN_ITEM_COFFER"); --打开锁定物品界面
   	--背包中物品改变
   	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false); 
   	--更新锁定物品界面
   	this:RegisterEvent("UPDATE_ITEM_COFFER"); --更新界面
   	--更新珍兽列表
   	this:RegisterEvent("UPDATE_PET_LIST");    -- 更新珍兽列表
   	--包裹重置大小发生改变
   	this:RegisterEvent("RESET_EXT_BAG");      --重置背包
   	this:RegisterEvent("UI_COMMAND");     
	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end	

function SafeCenter_LockUnlock_OnLoad()
	-- 保存界面的默认相对位置
	g_SafeCenter_LockUnlock_Frame_UnifiedXPosition	= SafeCenter_LockUnlock_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_LockUnlock_Frame_UnifiedYPosition	= SafeCenter_LockUnlock_Frame : GetProperty("UnifiedYPosition");
		
	PACKAGE_BUTTONS = {
		SafeCenter_LockUnlock_2_ItemBox_1, SafeCenter_LockUnlock_2_ItemBox_2, SafeCenter_LockUnlock_2_ItemBox_3, SafeCenter_LockUnlock_2_ItemBox_4, SafeCenter_LockUnlock_2_ItemBox_5, 
		SafeCenter_LockUnlock_2_ItemBox2_1, SafeCenter_LockUnlock_2_ItemBox2_2, SafeCenter_LockUnlock_2_ItemBox2_3, SafeCenter_LockUnlock_2_ItemBox2_4, SafeCenter_LockUnlock_2_ItemBox2_5,
		SafeCenter_LockUnlock_2_ItemBox_6, SafeCenter_LockUnlock_2_ItemBox_7, SafeCenter_LockUnlock_2_ItemBox_8, SafeCenter_LockUnlock_2_ItemBox_9, SafeCenter_LockUnlock_2_ItemBox_10, 
		SafeCenter_LockUnlock_2_ItemBox2_6, SafeCenter_LockUnlock_2_ItemBox2_7, SafeCenter_LockUnlock_2_ItemBox2_8, SafeCenter_LockUnlock_2_ItemBox2_9, SafeCenter_LockUnlock_2_ItemBox2_10,
		SafeCenter_LockUnlock_2_ItemBox_11, SafeCenter_LockUnlock_2_ItemBox_12, SafeCenter_LockUnlock_2_ItemBox_13, SafeCenter_LockUnlock_2_ItemBox_14, SafeCenter_LockUnlock_2_ItemBox_15, 
		SafeCenter_LockUnlock_2_ItemBox2_11, SafeCenter_LockUnlock_2_ItemBox2_12, SafeCenter_LockUnlock_2_ItemBox2_13, SafeCenter_LockUnlock_2_ItemBox2_14, SafeCenter_LockUnlock_2_ItemBox2_15,
		SafeCenter_LockUnlock_2_ItemBox_16, SafeCenter_LockUnlock_2_ItemBox_17, SafeCenter_LockUnlock_2_ItemBox_18, SafeCenter_LockUnlock_2_ItemBox_19, SafeCenter_LockUnlock_2_ItemBox_20, 
		SafeCenter_LockUnlock_2_ItemBox2_16, SafeCenter_LockUnlock_2_ItemBox2_17, SafeCenter_LockUnlock_2_ItemBox2_18, SafeCenter_LockUnlock_2_ItemBox2_19, SafeCenter_LockUnlock_2_ItemBox2_20,
		SafeCenter_LockUnlock_2_ItemBox_21, SafeCenter_LockUnlock_2_ItemBox_22, SafeCenter_LockUnlock_2_ItemBox_23, SafeCenter_LockUnlock_2_ItemBox_24, SafeCenter_LockUnlock_2_ItemBox_25, 
		SafeCenter_LockUnlock_2_ItemBox2_21, SafeCenter_LockUnlock_2_ItemBox2_22, SafeCenter_LockUnlock_2_ItemBox2_23, SafeCenter_LockUnlock_2_ItemBox2_24, SafeCenter_LockUnlock_2_ItemBox2_25,
		SafeCenter_LockUnlock_2_ItemBox_26, SafeCenter_LockUnlock_2_ItemBox_27, SafeCenter_LockUnlock_2_ItemBox_28, SafeCenter_LockUnlock_2_ItemBox_29, SafeCenter_LockUnlock_2_ItemBox_30, 
		SafeCenter_LockUnlock_2_ItemBox2_26, SafeCenter_LockUnlock_2_ItemBox2_27, SafeCenter_LockUnlock_2_ItemBox2_28, SafeCenter_LockUnlock_2_ItemBox2_29, SafeCenter_LockUnlock_2_ItemBox2_30,
	}

	LOCK_ICON = {
		SafeCenter_LockUnlock_2_ItemBoxIcon_1, SafeCenter_LockUnlock_2_ItemBoxIcon_2, SafeCenter_LockUnlock_2_ItemBoxIcon_3, SafeCenter_LockUnlock_2_ItemBoxIcon_4, SafeCenter_LockUnlock_2_ItemBoxIcon_5,
		SafeCenter_LockUnlock_2_ItemBox2Icon_1, SafeCenter_LockUnlock_2_ItemBox2Icon_2, SafeCenter_LockUnlock_2_ItemBox2Icon_3, SafeCenter_LockUnlock_2_ItemBox2Icon_4, SafeCenter_LockUnlock_2_ItemBox2Icon_5,
		SafeCenter_LockUnlock_2_ItemBoxIcon_6, SafeCenter_LockUnlock_2_ItemBoxIcon_7, SafeCenter_LockUnlock_2_ItemBoxIcon_8, SafeCenter_LockUnlock_2_ItemBoxIcon_9, SafeCenter_LockUnlock_2_ItemBoxIcon_10,
		SafeCenter_LockUnlock_2_ItemBox2Icon_6, SafeCenter_LockUnlock_2_ItemBox2Icon_7, SafeCenter_LockUnlock_2_ItemBox2Icon_8, SafeCenter_LockUnlock_2_ItemBox2Icon_9, SafeCenter_LockUnlock_2_ItemBox2Icon_10,
		SafeCenter_LockUnlock_2_ItemBoxIcon_11, SafeCenter_LockUnlock_2_ItemBoxIcon_12, SafeCenter_LockUnlock_2_ItemBoxIcon_13, SafeCenter_LockUnlock_2_ItemBoxIcon_14, SafeCenter_LockUnlock_2_ItemBoxIcon_15,
		SafeCenter_LockUnlock_2_ItemBox2Icon_11, SafeCenter_LockUnlock_2_ItemBox2Icon_12, SafeCenter_LockUnlock_2_ItemBox2Icon_13, SafeCenter_LockUnlock_2_ItemBox2Icon_14, SafeCenter_LockUnlock_2_ItemBox2Icon_15,
		SafeCenter_LockUnlock_2_ItemBoxIcon_16, SafeCenter_LockUnlock_2_ItemBoxIcon_17, SafeCenter_LockUnlock_2_ItemBoxIcon_18, SafeCenter_LockUnlock_2_ItemBoxIcon_19, SafeCenter_LockUnlock_2_ItemBoxIcon_20,
		SafeCenter_LockUnlock_2_ItemBox2Icon_16, SafeCenter_LockUnlock_2_ItemBox2Icon_17, SafeCenter_LockUnlock_2_ItemBox2Icon_18, SafeCenter_LockUnlock_2_ItemBox2Icon_19, SafeCenter_LockUnlock_2_ItemBox2Icon_20,
		SafeCenter_LockUnlock_2_ItemBoxIcon_21, SafeCenter_LockUnlock_2_ItemBoxIcon_22, SafeCenter_LockUnlock_2_ItemBoxIcon_23, SafeCenter_LockUnlock_2_ItemBoxIcon_24, SafeCenter_LockUnlock_2_ItemBoxIcon_25,
		SafeCenter_LockUnlock_2_ItemBox2Icon_21, SafeCenter_LockUnlock_2_ItemBox2Icon_22, SafeCenter_LockUnlock_2_ItemBox2Icon_23, SafeCenter_LockUnlock_2_ItemBox2Icon_24, SafeCenter_LockUnlock_2_ItemBox2Icon_25,
		SafeCenter_LockUnlock_2_ItemBoxIcon_26, SafeCenter_LockUnlock_2_ItemBoxIcon_27, SafeCenter_LockUnlock_2_ItemBoxIcon_28, SafeCenter_LockUnlock_2_ItemBoxIcon_29, SafeCenter_LockUnlock_2_ItemBoxIcon_30,
		SafeCenter_LockUnlock_2_ItemBox2Icon_26, SafeCenter_LockUnlock_2_ItemBox2Icon_27, SafeCenter_LockUnlock_2_ItemBox2Icon_28, SafeCenter_LockUnlock_2_ItemBox2Icon_29, SafeCenter_LockUnlock_2_ItemBox2Icon_30,
	}

end

function SafeCenter_LockUnlock_OnEvent(event)

	if ( event == "OPEN_SAFECENTER_LOCKUNLOCK") then
		if( this:IsVisible() ) then
			return;
		else
			SafeCenter_LockUnlock_Open();
		end
	elseif ( event == "OPEN_ITEM_COFFER") then
		if( this:IsVisible() ) then
			return;
		else
			if tonumber(arg0) == 1 then
				g_nTheTabIndex = 1
			else
				g_nTheTabIndex = 0
			end
			SafeCenter_LockUnlock_Open();
		end
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" ) then
		 	SafeCenter_LockUnlock_UpdateFrame()
         SafeCenter_LockUnlock_Pet_UpdateFrame() 

    elseif ( event == "UPDATE_ITEM_COFFER" )  or
    	   ( event == "UPDATE_PET_LIST" )  or
    	   ( event == "RESET_EXT_BAG" )  then

    	 SafeCenter_LockUnlock_UpdateFrame()
         SafeCenter_LockUnlock_Pet_UpdateFrame() 

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
	    SafeCenter_LockUnlock_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		SafeCenter_LockUnlock_Frame_On_ResetPos();

	elseif (event == "UI_COMMAND" ) then
		if ( tonumber(arg0) == 5421 ) then
			this:Show();
			g_nTheTabIndex = tonumber(0);
			g_CurSelect = -1;
	    	SafeCenter_LockUnlock_UpdateFrame()
       		SafeCenter_LockUnlock_Pet_UpdateFrame() 
		end
	end


end	
--===============================================
-- 					切换界面
--===============================================
function SafeCenter_LockUnlock_OpenSafeScore()  --安全中心的起始界面(也就是安全评分界面)
      Variable:SetVariable("SelfUnionPos", SafeCenter_LockUnlock_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeScore();
end
function SafeCenter_LockUnlock_OpenSafePattern()  --安全模式界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_LockUnlock_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafePattern();
end


function SafeCenter_LockUnlock_OpenMobilePhone()  --手机认证
      Variable:SetVariable("SelfUnionPos", SafeCenter_LockUnlock_Frame:GetProperty("UnifiedPosition"), 1);
      OpenMobilePhone();
end
function SafeCenter_LockUnlock_OpenSafeTime()  --安全时间
      Variable:SetVariable("SelfUnionPos", SafeCenter_LockUnlock_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeTime();
end
function SafeCenter_LockUnlock_OpenAccountProtection() --账号密保
      Variable:SetVariable("SelfUnionPos", SafeCenter_LockUnlock_Frame:GetProperty("UnifiedPosition"), 1);
      OpenAccountProtection();
end
function SafeCenter_LockUnlock_OpenSecondPassword() --二级密码 
      Variable:SetVariable("SelfUnionPos", SafeCenter_LockUnlock_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSecondPassword();
end
function SafeCenter_LockUnlock_OpenSafeCheck() --安全验证
      Variable:SetVariable("SelfUnionPos", SafeCenter_LockUnlock_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeCheck();
end
function SafeCenter_LockUnlock_Open() --加锁解锁
	CloseWindow("SafeCenter_SafeScore", true) 	 
	CloseWindow("SafeCenter_SafePattern", true) 
	CloseWindow("SafeCenter_MobilePhone", true)
	CloseWindow("SafeCenter_SafeTime", true)
	CloseWindow("SafeCenter_AccountProtection", true)
	CloseWindow("SafeCenter_SecondPassword", true)
	CloseWindow("SafeCenter_SafeCheck", true)
	CloseWindow("SafeCenter_LockUnlock", true)	  
	CloseWindow("SafeCenter_MessageBox", true)
	
	if GameProduceLogin:IsWeGameClient() > 0 then
		SafeCenter_LockUnlock_WeGame_BackgroundRight_Frame:Show()
		SafeCenter_LockUnlock_BackgroundRight_Frame:Hide();
		SafeCenter_LockUnlock_MainButton_SafeScore:Disable();
		SafeCenter_LockUnlock_MainButton_SafePattern:Disable();
		SafeCenter_LockUnlock_MainButton_AccountProtection:Disable();
		SafeCenter_LockUnlock_MainButton_SafeCheck:Disable();
	else
		SafeCenter_LockUnlock_WeGame_BackgroundRight_Frame:Hide()
		SafeCenter_LockUnlock_BackgroundRight_Frame:Show();
	end
	
	     SafeCenter_LockUnlock_Update();
	     SafeCenter_LockUnlock_UpdateButtonSelected();
	     SafeCenter_LockUnlock_MainButton_LockUnlock:SetProperty("Selected", "True");
	     SafeCenter_LockUnlock_MainButton_LockUnlock:SetProperty("RiseOnClick", "Flase");
	     this:Show();
	     SafeCenter_LockUnlock_InitDlg();
end
--------------------------------------------------
function SafeCenter_LockUnlock_InitDlg()

   local isSetMinorPwd = IsMinorPwdSetup();
   local isSetAppWareProSetup = IsAppWareProtectSetup();

    if(tonumber(isSetAppWareProSetup) == 1 or
  	    tonumber(isSetMinorPwd) == 1 ) then
    	--加锁解锁界面显示
         SafeCenter_LockUnlock_Chief_Frame()
         g_CurSelect = -1;                            --鼠标选择初始化
         SafeCenter_LockUnlock_UpdateFrame()     --物品栏更新界面
         SafeCenter_LockUnlock_Pet_UpdateFrame() --珍兽栏更新界面
	else
		--二级密码设置界面显示
		SafeCenter_LockUnlock_Setting_SecondPassword_Frame()

	end

end

--更新界面按钮
function SafeCenter_LockUnlock_UpdateButtonSelected()
	 SafeCenter_LockUnlock_MainButton_LockUnlock:SetProperty("Selected", "False");
	 SafeCenter_LockUnlock_MainButton_SafePattern:SetProperty("Selected", "False");
	 SafeCenter_LockUnlock_MainButton_MobilePhone:SetProperty("Selected", "False");
	 SafeCenter_LockUnlock_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_LockUnlock_MainButton_AccountProtection:SetProperty("Selected", "False");
	 SafeCenter_LockUnlock_MainButton_SecondPassword:SetProperty("Selected", "False");	 
	 SafeCenter_LockUnlock_MainButton_SafeCheck:SetProperty("Selected", "False");
	 SafeCenter_LockUnlock_MainButton_LockUnlock:SetProperty("Selected", "False");	 	 
end

--更新主界面位置
function SafeCenter_LockUnlock_Frame_On_ResetPos()
	-- body
	SafeCenter_LockUnlock_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_LockUnlock_Frame_UnifiedXPosition);
	SafeCenter_LockUnlock_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_LockUnlock_Frame_UnifiedYPosition);
end

--得到当前UI位置
function SafeCenter_LockUnlock_Update()
	-- body
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_LockUnlock_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
end
--===============================================
--二级密码相关
--===============================================
function SafeCenter_LockUnlock_Setting_SecondPassword_Frame()
	    --二级密码设置部分
	    SafeCenter_LockUnlock_1_BackgroundDown_Frame8:SetProperty("Visible" , "True" )    
	    SafeCenter_LockUnlock_1_Lace1_SimpleText:SetText( "#{AQZX_130812_95}"  );     
        --主要部分(加锁解锁)
	    SafeCenter_LockUnlock_2_BackgroundDown_Frame9:SetProperty("Visible" , "False" )   
	    SafeCenter_LockUnlock_1_Frame8_EditText1:SetText( "" );
	    SafeCenter_LockUnlock_1_Frame8_EditText2:SetText( "" );

	    SafeCenter_LockUnlock_1_Frame8_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_LockUnlock_1_Frame8_EditText1" );         
	-- body
end

--输入时触发
function SafeCenter_LockUnlock_SecondPassword_Input_OnActive()
	SafeCenter_LockUnlock_1_Frame8_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_LockUnlock_1_Frame8_EditText1" );
end
--确认时触发
function SafeCenter_LockUnlock_SecondPassword_Confirm_OnActive()
	SafeCenter_LockUnlock_1_Frame8_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_LockUnlock_1_Frame8_EditText2" );
end

--设置按钮
function SafeCenter_LockUnlock_OK_Click()

	local strPassword1 = SafeCenter_LockUnlock_1_Frame8_EditText1:GetText();
	local strPassword2 = SafeCenter_LockUnlock_1_Frame8_EditText2:GetText();
	
	-- 如果密码不一致
	if(strPassword1 ~= strPassword2) then
		ShowSystemTipInfo("密码输入不一致！");
		SafeCenter_LockUnlock_1_Frame8_EditText1:SetText( "" );
		SafeCenter_LockUnlock_1_Frame8_EditText2:SetText( "" );
		return
	end
	
	local iLen = string.len(strPassword1);
	if(iLen < 4) then
		ShowSystemTipInfo("新密码不能少于4个字符！");
		return;
	end;
	
	-- 如果密码不一致。发送改变密码消息。
	SendSetMinorPassword(tostring(strPassword1));
	this:Hide();

end
--===============================================
-- 加锁解锁相关
--===============================================
function SafeCenter_LockUnlock_Chief_Frame()
	    SafeCenter_LockUnlock_1_BackgroundDown_Frame8:SetProperty("Visible" , "False" )         
        --主要部分(加锁解锁)
	    SafeCenter_LockUnlock_2_BackgroundDown_Frame9:SetProperty("Visible" , "True" )            
	  	--界面初始化
	-- body
end

--===============================================
-- 换页
--===============================================
function SafeCenter_LockUnlock_ChangeTabIndex(nIndex)
	if nIndex < 0 or nIndex > 1 then 
		return 
	end
	if g_nTheTabIndex == nIndex then
		return
	end
	g_nTheTabIndex = nIndex
	SafeCenter_LockUnlock_UpdateFrame()
end

--===============================================
-- 更新界面
--===============================================
function SafeCenter_LockUnlock_UpdateFrame()
		if g_nTheTabIndex == 0 then
			SafeCenter_LockUnlock_Base_UpdateFrame()
		elseif g_nTheTabIndex == 1 then
			SafeCenter_LockUnlock_Material_UpdateFrame()
		end
end

--道具栏更新界面
function SafeCenter_LockUnlock_Base_UpdateFrame()
	
	--先隐藏所有图标
	for i=1 ,PACKAGE_BUTTONS_NUM   do
		LOCK_ICON[i]:Hide();
	end
	
	local i=1;
	local szPacketName = "";
	local CurrNum = 20;
	local BaseNum = 20;
	local MaxNum = 60;

	--SafeCenter_LockUnlock_2_Frame9_Box1:Hide();

	CurrNum = DataPool:GetBaseBag_Num();
	BaseNum = DataPool:GetBaseBag_BaseNum();
	MaxNum = DataPool:GetBaseBag_RealMaxNum();

	szPacketName = "base";
	SafeCenter_LockUnlock_2_Frame9_Lace1:SetCheck(1);

	for i=1 ,BaseNum  do
		PACKAGE_BUTTONS[i]:Show();
	end	
	i = 1;
	while i <= CurrNum-BaseNum do
		PACKAGE_BUTTONS[BaseNum+i]:Enable();
		PACKAGE_BUTTONS[BaseNum+i]:Show();
		i = i + 1;
	end		
	i = CurrNum-BaseNum+1; --i=0 or 10
	while i <= MaxNum-BaseNum do
		PACKAGE_BUTTONS[BaseNum+i]:Hide();
		PACKAGE_BUTTONS[BaseNum+i]:Disable();
		i = i + 1;
	end
	--SafeCenter_LockUnlock_2_Frame9_Box1:Show();
	SafeCenter_LockUnlock_UpDateItem(szPacketName);
end

--材料栏更新界面
function SafeCenter_LockUnlock_Material_UpdateFrame()

  --先隐藏所有图标
	for i=1 ,PACKAGE_BUTTONS_NUM   do
		LOCK_ICON[i]:Hide();
	end
	
	local i=1;
	local szPacketName = "";
	local CurrNum = 20;
	local BaseNum = 20;
	local MaxNum = 60;

	    --SafeCenter_LockUnlock_2_Frame9_Box2:Hide();

		CurrNum = DataPool:GetMatBag_Num();
		BaseNum = DataPool:GetMatBag_BaseNum();
		MaxNum = DataPool:GetMatBag_RealMaxNum();

		szPacketName = "material";
		SafeCenter_LockUnlock_2_Frame9_Lace2:SetCheck(1);
		
		for i=1 ,BaseNum  do
			PACKAGE_BUTTONS[i]:Show();
		end

		i = 1;
		while i <= CurrNum-BaseNum do
			PACKAGE_BUTTONS[BaseNum+i]:Enable();
			PACKAGE_BUTTONS[BaseNum+i]:Show();
			i = i + 1;
		end
		i = CurrNum-BaseNum+1;
		while i <= MaxNum-BaseNum do
			PACKAGE_BUTTONS[BaseNum+i]:Hide();
			PACKAGE_BUTTONS[BaseNum+i]:Disable();
			i = i + 1;
		end
		--SafeCenter_LockUnlock_2_Frame9_Box2:Show();
		SafeCenter_LockUnlock_UpDateItem(szPacketName);

	-- body
end
--宠物栏更新界面
function SafeCenter_LockUnlock_Pet_UpdateFrame(  )

	local szPacketName = "pet";
	SafeCenter_LockUnlock_UpDatePet();

end
--更新加锁界面中道具栏、材料栏的显示
function SafeCenter_LockUnlock_UpDateItem( szPacketName )
	
	local nPosIndex = -1;

    local i=1;
	while i<=PACKAGE_BUTTONS_NUM do 
		local theAction,bLocked,bProtect,nUnlockElapsedTime = PlayerPackage:EnumItem(szPacketName, i-1);
		if theAction:GetID() ~= 0 then
			PACKAGE_BUTTONS[i]:SetActionItem(theAction:GetID());
			if( g_CurSelect == i )   then 
				PACKAGE_BUTTONS[i]:SetPushed(1);
			else
				PACKAGE_BUTTONS[i]:SetPushed(0);
			end
		else
			PACKAGE_BUTTONS[i]:SetActionItem(-1);
		end

		if bLocked == 1 then    --没有物品的时候不可用
			PACKAGE_BUTTONS[i]:Disable();
		else                     --有物品可用
			PACKAGE_BUTTONS[i]:Enable();
		end
		
		if( bProtect == 1 )   then   --有锁  锁的状态
			LOCK_ICON[i]:Show();
			
			if( nUnlockElapsedTime == 0 ) then
				LOCK_ICON[i]:SetProperty("Image","set:UIIcons image:Icon_Lock");
			else
				LOCK_ICON[i]:SetProperty("Image","set:CommonFrame6 image:NewLock");
			end
		end
		i = i+1;
	end
end

--更新珍兽，更新珍兽栏的每一个格子
function SafeCenter_LockUnlock_UpDatePet()
	SafeCenter_ItemCoffer_PetList:ClearListBox();
	local nPetCount = Pet:GetPet_Count();
	local PetInListIndex = 0;
	for	i=1, PET_MAX_NUMBER do	--modify by xindefeng
		local szPetName,szOn = Pet:GetPetList_Appoint(i-1);
		local strToolTips = "";
		if(szPetName ~= "")   then
			if( szOn ~= "on_packa" )  then 

				szPetName = "#c808080" .. szPetName;
			end
			if(PlayerPackage:IsPetLock(i-1) == 1)    then
				local nUnlockElapsedTime = PlayerPackage:GetPUnlockElapsedTime_Pet(i-1);

				if( nUnlockElapsedTime == 0 ) then
					szPetName = szPetName.. "  #-05";
					
					strToolTips =  "已加锁" ;
				else
					szPetName = szPetName.. "  #-10";
					
					local strLeftTime = g_GetUnlockingStr(nUnlockElapsedTime);			
					strToolTips = strLeftTime ;
				end
			end
		
			SafeCenter_ItemCoffer_PetList:AddItem(szPetName, PetInListIndex);
			
			SafeCenter_ItemCoffer_PetList:SetItemTooltip( PetInListIndex, strToolTips );
			
			g_PetIndex[PetInListIndex] = i-1;
			PetInListIndex = PetInListIndex + 1 ;
		end	
	end

end

--选中
function SafeCenter_LockUnlock_Chose_Clicked(nIndex)

	 g_CurSelect = nIndex;
	 SafeCenter_LockUnlock_UpdateFrame()
	 SafeCenter_LockUnlock_Pet_UpdateFrame() 

end

--加锁
function SafeCenter_LockUnlock_Lock_Clicked()

	local nPetIndex = SafeCenter_ItemCoffer_PetList:GetFirstSelectItem()

	--什么都没选
	if( tonumber(nPetIndex) == -1 and g_CurSelect ==-1) then
		 PushDebugMessage("#{AQZX_130812_120}")
		 return
	end
	--选中的是物品 
	if(tonumber(nPetIndex) == -1 and g_CurSelect ~= -1) then
		local szPacketName = "";
		local LockUnLockPosIndex = "";
    	if g_nTheTabIndex == 0 then
    		szPacketName = "base";
    	elseif g_nTheTabIndex == 1 then
    		szPacketName = "material";    		
    	end
    	local theAction,bLocked,bProtect,nUnlockElapsedTime = PlayerPackage:EnumItem(szPacketName, g_CurSelect-1);

   		if theAction:GetID() ~= 0 then			
   		   PlayerPackage:Lock("lock", "item", g_nTheTabIndex*DataPool:GetBaseBag_MaxNum() + g_CurSelect-1);
   		else
   		   PushDebugMessage("#{AQZX_130812_120}")
   		end	
   		return
   	end	

   	--选中的是珍兽
   	if( tonumber(nPetIndex) ~= -1) then
		PlayerPackage:Lock("lock", "pet", g_PetIndex[nPetIndex]);
	end

end


-- 解锁
function SafeCenter_LockUnlock_Clicked()

	local nPetIndex = SafeCenter_ItemCoffer_PetList:GetFirstSelectItem()

	--什么都没选
	if( tonumber(nPetIndex) == -1 and g_CurSelect ==-1) then
		 PushDebugMessage("#{AQZX_130812_127}")
		 return
	end

	--选中的是物品 
	if(tonumber(nPetIndex) == -1 and g_CurSelect ~= -1) then

		local szPacketName = "";
		local LockUnLockPosIndex = "";
    	if g_nTheTabIndex == 0 then
    		szPacketName = "base";
    	elseif g_nTheTabIndex == 1 then
    		szPacketName = "material";    		
    	end
    	local theAction,bLocked,bProtect,nUnlockElapsedTime = PlayerPackage:EnumItem(szPacketName, g_CurSelect-1);

   		if theAction:GetID() ~= 0 then			
   		   PlayerPackage:Lock("unlock", "item", g_nTheTabIndex*DataPool:GetBaseBag_MaxNum() + g_CurSelect-1);
   		else
   		   PushDebugMessage("#{AQZX_130812_127}")
   		end	

   		return

   	end	

   	--选中的是珍兽
   	if( tonumber(nPetIndex) ~= -1) then
		PlayerPackage:Lock("unlock", "pet", g_PetIndex[nPetIndex]);
	end

end


--右键选中珍兽
function SafeCenter_LockUnlock_ShowTargetPet()

	g_CurSelect = -1
    SafeCenter_LockUnlock_UpdateFrame()
	local nIndex = SafeCenter_ItemCoffer_PetList:GetFirstSelectItem();

	if( -1 == nIndex ) then
		return;
	end
	Pet:ShowTargetPet(g_PetIndex[nIndex]);

end

--左键选中珍兽
function SafeCenter_LockUnlock_RefreshBaseAndMat( )

	g_CurSelect = -1
    SafeCenter_LockUnlock_UpdateFrame()

end
--function SafeCenter_LockUnlock_AllLock()
--	Variable:SetVariable("SelfUnionPos", SafeCenter_LockUnlock_Frame:GetProperty("UnifiedPosition"), 1);
--	PushEvent( "ONCE_ALL_LOCK")
--end
-- 超链 安全中心官网
function SafeCenter_LockUnlock_GW_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_GW"))
end

-- 超链 账号平台
function SafeCenter_LockUnlock_ZHPT_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZHPT"))
end

-- 超链 客服中心
function SafeCenter_LockUnlock_KFZX_Clicked()
	if GameProduceLogin:IsWeGameClient() > 0 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_ANQUANZHONGXIN_KFZX"))
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_KFZX"))
	end
end


--added by Manda for 加锁解锁
function SafeCenter_LockUnlock_HaveProtection()

end
