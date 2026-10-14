local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local GRID_BUTTONS = {};
local ActionButton = {};
local ButtonLock = {};
local BieYeBankIndex = 8
local   g_DescriptionButton= {[1] = "1",[2] = "1",[3] = "1",[4] = "1",[5] = "2",	[6] = "2",	[7] = "2",	[8] = "2",	[9] = "3",	[10] = "3",
						     [11] = "3", [12] = "3",	[13] = "4",	[14] = "4",	[15] = "4",	[16] = "4",	[17] = "5",	[18] = "5",	[19] = "5",	[20] = "5",
						
																}
local objCared = -1;
--页签及其编号
local GRID_BUTTONS_NUM = 20;
local MAX_OBJ_DISTANCE = 3.0;
function BieYeBank_PreLoad()

	this:RegisterEvent("SCENE_TRANSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("OPEN_BIEYE_BANK")
	this:RegisterEvent("UPDATE_BANK")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BEGIN_PACKUP_BANK")
	this:RegisterEvent("END_PACKUP_BANK")
end

function BieYeBank_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYeBank_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYeBank_Frame:GetProperty("UnifiedYPosition");
	
	ActionButton[1] = BieYeBank_ItemSet1_icon;
	ActionButton[2] = BieYeBank_ItemSet2_icon;
	ActionButton[3] = BieYeBank_ItemSet3_icon;
	ActionButton[4] = BieYeBank_ItemSet4_icon;
	ActionButton[5] = BieYeBank_ItemSet5_icon;
	ActionButton[6] = BieYeBank_ItemSet6_icon;
	ActionButton[7] = BieYeBank_ItemSet7_icon;
	ActionButton[8] = BieYeBank_ItemSet8_icon;
	ActionButton[9] = BieYeBank_ItemSet9_icon;
	ActionButton[10] = BieYeBank_ItemSet10_icon;
	ActionButton[11] = BieYeBank_ItemSet11_icon;
	ActionButton[12] = BieYeBank_ItemSet12_icon;
	ActionButton[13] = BieYeBank_ItemSet13_icon;
	ActionButton[14] = BieYeBank_ItemSet14_icon;
	ActionButton[15] = BieYeBank_ItemSet15_icon;
	ActionButton[16] = BieYeBank_ItemSet16_icon;
	ActionButton[17] = BieYeBank_ItemSet17_icon;
	ActionButton[18] = BieYeBank_ItemSet18_icon;
	ActionButton[19] = BieYeBank_ItemSet19_icon;
	ActionButton[20] = BieYeBank_ItemSet20_icon;
	
	ButtonLock[1] = BieYeBank_ItemSet1_locked;
	ButtonLock[2] = BieYeBank_ItemSet2_locked;
	ButtonLock[3] = BieYeBank_ItemSet3_locked;
	ButtonLock[4] = BieYeBank_ItemSet4_locked;
	ButtonLock[5] = BieYeBank_ItemSet5_locked;
	ButtonLock[6] = BieYeBank_ItemSet6_locked;
	ButtonLock[7] = BieYeBank_ItemSet7_locked;
	ButtonLock[8] = BieYeBank_ItemSet8_locked;
	ButtonLock[9] = BieYeBank_ItemSet9_locked;
	ButtonLock[10] = BieYeBank_ItemSet10_locked;
	ButtonLock[11] = BieYeBank_ItemSet11_locked;
	ButtonLock[12] = BieYeBank_ItemSet12_locked;
	ButtonLock[13] = BieYeBank_ItemSet13_locked;
	ButtonLock[14] = BieYeBank_ItemSet14_locked;
	ButtonLock[15] = BieYeBank_ItemSet15_locked;
	ButtonLock[16] = BieYeBank_ItemSet16_locked;
	ButtonLock[17] = BieYeBank_ItemSet17_locked;
	ButtonLock[18] = BieYeBank_ItemSet18_locked;
	ButtonLock[19] = BieYeBank_ItemSet19_locked;
	ButtonLock[20] = BieYeBank_ItemSet20_locked;

	GRID_BUTTONS[1]  = BieYeBank_ItemSet1_othersbk;
	GRID_BUTTONS[2]  = BieYeBank_ItemSet2_othersbk;
	GRID_BUTTONS[3]  = BieYeBank_ItemSet3_othersbk;
	GRID_BUTTONS[4]  = BieYeBank_ItemSet4_othersbk;
	GRID_BUTTONS[5]  = BieYeBank_ItemSet5_othersbk;
	GRID_BUTTONS[6]  = BieYeBank_ItemSet6_othersbk;
	GRID_BUTTONS[7]  = BieYeBank_ItemSet7_othersbk;
	GRID_BUTTONS[8]  = BieYeBank_ItemSet8_othersbk;
	GRID_BUTTONS[9]  = BieYeBank_ItemSet9_othersbk;
	GRID_BUTTONS[10] = BieYeBank_ItemSet10_othersbk;
	GRID_BUTTONS[11] = BieYeBank_ItemSet11_othersbk;
	GRID_BUTTONS[12] = BieYeBank_ItemSet12_othersbk;
	GRID_BUTTONS[13] = BieYeBank_ItemSet13_othersbk;
	GRID_BUTTONS[14] = BieYeBank_ItemSet14_othersbk;
	GRID_BUTTONS[15] = BieYeBank_ItemSet15_othersbk;
	GRID_BUTTONS[16] = BieYeBank_ItemSet16_othersbk;
	GRID_BUTTONS[17] = BieYeBank_ItemSet17_othersbk;
	GRID_BUTTONS[18] = BieYeBank_ItemSet18_othersbk;
	GRID_BUTTONS[19] = BieYeBank_ItemSet19_othersbk;
	GRID_BUTTONS[20] = BieYeBank_ItemSet20_othersbk;

end



function BieYeBank_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BieYeBank_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYeBank_ResetPos()
	--=Disable“整理”
	elseif ( event == "BEGIN_PACKUP_BANK" )   then
		BieYeBank_ZhengLiBtn:Disable()	
	elseif ( event == "END_PACKUP_BANK" )   then
		BieYeBank_ZhengLiBtn:Enable()	
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 891905) then

		BieYeBank_UpdateFrame()
		this:Show()
		
	elseif(event == "UPDATE_BANK"and this:IsVisible()) then
		BieYeBank_UpdateFrame()
	elseif(event == "OPEN_BIEYE_BANK" ) then

		if(IsWindowShow("YouLongKa2")) then
		  CloseWindow("YouLongKa2", true);
		end
		
		if(IsWindowShow("Bank")) then
		  CloseWindow("Bank", true);
		end
		if(IsWindowShow("BigBank")) then
		  CloseWindow("BigBank", true);
		end
		if(IsWindowShow("BieYeFurnitureBank")) then
			PushEvent( "BIEYE_OPEN_MINI" );
		end
			--关心NPC
		objCared = Bank:GetNpcId();
		this:CareObject(objCared, 1, "BieYeBank");
		BieYeBank_UpdateFrame()
		this:Show()	
	elseif (event == "OBJECT_CARED_EVENT") then

		if(tonumber(arg0) ~= objCared) then
			return;
		end		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			--Bank:Close();
			--一旦关闭，则设置为0

			--取消关心
			this:CareObject(objCared, 0, "BieYeBank");
		end
		
	end
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeBank_ResetPos()
	BieYeBank_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYeBank_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BieYeBank_OpenFame()

end


--===============================================
-- 更新界面
--===============================================
function BieYeBank_UpdateFrame()
    local BieYeLevel = BieYeUI:GetBieYeBaseInfo("BuildingLevel",1)
	local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
	local myGuid = Player:GetGUID();
		--婚姻组
	local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()

	local bIsMyBieye = 0
	if isHaveSpouse == 1 then
		if BieYeGuid == myGuid then
			bIsMyBieye = 1
		elseif BieYeGuid == spouseGuid then
			bIsMyBieye = 2 
		end
	else
		if BieYeGuid == myGuid then
			bIsMyBieye = 1			
		end
	end


	--PushDebugMessage("bIsMyBieye="..bIsMyBieye.." isHaveSpouse="..isHaveSpouse.." BieYeGuid="..BieYeGuid.." spouseGuid="..spouseGuid)
	BieYeBank_Info:SetText("#{JYYH_160520_17}")

	Bank:SetCurRentIndex(BieYeBankIndex)
	
	for i=1, GRID_BUTTONS_NUM do
		ActionButton[i]:SetActionItem(-1);
		ActionButton[i]:Enable();
	end

	--从数据池中使用数据填入背包内的物品

	for i=1, GRID_BUTTONS_NUM  do
		GRID_BUTTONS[i]:SetProperty("Visible","false")
		ButtonLock[i]:SetProperty("Visible","false")
		ActionButton[i]:SetProperty("Visible","True")
		--ActionButton[i]:SetToolTip("111111111")
		
		if bIsMyBieye == 1 then
			local str = ScriptGlobal_Format("#{JYYH_160520_20}", g_DescriptionButton[i])
			ButtonLock[i]:SetToolTip(str)
		elseif bIsMyBieye == 2 then
			local str = ScriptGlobal_Format("#{JYYH_160520_21}", g_DescriptionButton[i])
			ButtonLock[i]:SetToolTip(str)			

		end

		--GRID_BUTTONS[i]:SetToolTip("22222222")
	end
	--获得这个背包可以使用的格子数
	local nBeginIndex,nGridNum = Bank:GetRentBoxInfo(BieYeBankIndex);

	--从数据池中使用数据填入背包内的物品

	local nActIndex = nBeginIndex;
	local i=1;
	local Lock_Flag = 0
	for i=1, nGridNum  do
		local theAction, bLocked = Bank:EnumItem(nActIndex);
		if theAction:GetID() ~= 0 then
			ActionButton[i]:SetActionItem(theAction:GetID());
			if(bLocked == true) then
				--ActionButton[i]:Disable();
				Lock_Flag = 1
			else
				ActionButton[i]:Enable();
			end
		else
			ActionButton[i]:SetActionItem(-1);
		end
				
		nActIndex = nActIndex+1;
	end
	if Lock_Flag == 0 then
		BieYeBank_ZhengLiBtn:Enable()
	else
		BieYeBank_ZhengLiBtn:Disable()
	end
	
	
	
--	for i=1, GRID_BUTTONS_NUM  do

--		local theAction = BieYeFurniture:EnumItem( nActVerifyIndex );
--		local nNum  = BieYeFurniture:GetNum( nActVerifyIndex );
--		if theAction:GetID() ~= 0 then
--			ActionButton[i]:SetActionItem(theAction:GetID());
--			if nNum > 0 then
--				GRID_BUTTONS[i]:SetProperty("Visible","false")
--			else
--				GRID_BUTTONS[i]:SetProperty("Visible","true")
--			end
--		else
--			ActionButton[i]:SetActionItem(-1);
--			GRID_BUTTONS[i]:SetProperty("Visible","false")
--		end
--		
--	end
end

function BieYeBank_PackUp_Clicked()
		Bank:PackUpBank(BieYeBankIndex)
end

function BieYeBank_test_Clicked(index)
		--Bank:PackUpBank(BieYeBankIndex)
		ButtonLock[i]:SetProperty("Visible","true")
end
