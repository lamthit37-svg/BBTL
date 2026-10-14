
local RIGHTBAR_2_BUTTONS = {};
local RIGHTBAR_2_BUTTON_NUM = 9;

local COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR = {};
local COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR = {};

function FunctionBarRight_2_PreLoad()

	this:RegisterEvent("CHANGE_BAR");
	this:RegisterEvent("ACTION_UPDATE");
	this:RegisterEvent("UNINSTALL_CHAT_ACTION_BAR4");
	this:RegisterEvent("CLEAR_CHAT_ACTION_BAR");
	this:RegisterEvent("OPEN_RIGHT_BAR_2");
	this:RegisterEvent("FLASH_COMBOSKILL",true);
	this:RegisterEvent("HIDE_THIS_UI")				-- 隐藏界面
end

function FunctionBarRight_2_OnLoad()

	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[61] = FunctionBarRight_2_Function_Button1_junior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[62] = FunctionBarRight_2_Function_Button2_junior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[63] = FunctionBarRight_2_Function_Button3_junior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[64] = FunctionBarRight_2_Function_Button4_junior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[65] = FunctionBarRight_2_Function_Button5_junior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[66] = FunctionBarRight_2_Function_Button6_junior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[67] = FunctionBarRight_2_Function_Button7_junior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[68] = FunctionBarRight_2_Function_Button8_junior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[69] = FunctionBarRight_2_Function_Button9_junior_Flash

	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[61] = FunctionBarRight_2_Function_Button1_senior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[62] = FunctionBarRight_2_Function_Button2_senior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[63] = FunctionBarRight_2_Function_Button3_senior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[64] = FunctionBarRight_2_Function_Button4_senior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[65] = FunctionBarRight_2_Function_Button5_senior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[66] = FunctionBarRight_2_Function_Button6_senior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[67] = FunctionBarRight_2_Function_Button7_senior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[68] = FunctionBarRight_2_Function_Button8_senior_Flash
	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[69] = FunctionBarRight_2_Function_Button9_senior_Flash
	
	
	
	RIGHTBAR_2_BUTTONS[61] = FunctionBarRight_2_Button_Action1;
	RIGHTBAR_2_BUTTONS[62] = FunctionBarRight_2_Button_Action2;
	RIGHTBAR_2_BUTTONS[63] = FunctionBarRight_2_Button_Action3;
	RIGHTBAR_2_BUTTONS[64] = FunctionBarRight_2_Button_Action4;
	RIGHTBAR_2_BUTTONS[65] = FunctionBarRight_2_Button_Action5;
	RIGHTBAR_2_BUTTONS[66] = FunctionBarRight_2_Button_Action6;
	RIGHTBAR_2_BUTTONS[67] = FunctionBarRight_2_Button_Action7;
	RIGHTBAR_2_BUTTONS[68] = FunctionBarRight_2_Button_Action8;
	RIGHTBAR_2_BUTTONS[69] = FunctionBarRight_2_Button_Action9;
end

-- OnEvent
function FunctionBarRight_2_OnEvent(event)
	if event == "OPEN_RIGHT_BAR_2" then
		if arg0 == "1" and DataPool:GetTrans() ~= 1 then
			this:Show()
		else
			this:Hide()
		end
	elseif( event == "CHANGE_BAR" and arg0 == "mainreset") then	
		local count=tonumber(arg1)+2;
		for i=3,count do
			local nIndex=tonumber(eventTable[i]);
			if( nIndex > 60 and nIndex < 70 )  then			
				RIGHTBAR_2_BUTTONS[nIndex] : SetActionItem(-1);
				RIGHTBAR_2_BUTTONS[nIndex] : Bright();							
			end
			if nIndex > 60 and  nIndex < 70 and RIGHTBAR_2_BUTTONS[nIndex]:IsVisible() then
			if 	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[nIndex]:IsVisible() then
				COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[nIndex]:Hide()
			end
			if 	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[nIndex]:IsVisible() then
				COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[nIndex]:Hide()
			end
		end	
		end
	elseif( event == "CHANGE_BAR" and arg0 == "main") then
		if( tonumber(arg1) > 60 and tonumber(arg1) < 70 )  then
			local nIndex = tonumber(arg1) ;
			Target:UpdateActionButton()
			RIGHTBAR_2_BUTTONS[nIndex] : SetActionItem(tonumber(arg2));
			RIGHTBAR_2_BUTTONS[nIndex] : Bright();
			
			if arg3~=nil then
				
				local pet_num = tonumber(arg3);
				
				if pet_num >= 0 and pet_num < 6 then
					if Pet : IsPresent(pet_num) and Pet : GetIsFighting(pet_num) then
							RIGHTBAR_2_BUTTONS[nIndex] : Bright();
					else
							RIGHTBAR_2_BUTTONS[nIndex] : Gloom();
					end
						
				end
				
			end
			
		end
		local nIndex = tonumber(arg1)
		if nIndex > 60 and  nIndex < 70 and RIGHTBAR_2_BUTTONS[nIndex]:IsVisible() then
			if 	COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[nIndex]:IsVisible() then
				COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[nIndex]:Hide()
			end
			if 	COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[nIndex]:IsVisible() then
				COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[nIndex]:Hide()
			end
		end	
	elseif( event == "ACTION_UPDATE" ) then
		FunctionBarRight_2_ActionUpdate();

	-- 卸载双人休闲动作包时，同时删除拖动到FunctionBarRight_2上的按钮信息	
	elseif (event == "UNINSTALL_CHAT_ACTION_BAR4") then
		FunctionBarRight_2_UnInstallChatActionButton(tonumber(arg0));

	-- 清理过期的双人休闲动作包在主菜单上的按钮
	elseif (event == "CLEAR_CHAT_ACTION_BAR") and (tostring(arg0)== "FunctionBarRight_2") then
		FunctionBarRight_2_ClearChatActionButton(tonumber(arg1), tonumber(arg2), tonumber(arg3));
	elseif (event == "FLASH_COMBOSKILL") then
		local Index = tonumber(arg0)
		local flash = tonumber(arg1)
		
		if Index > 60 and Index < 70 then
			FunctionBarRight_2_UpdateComboFlash(Index, flash)
		end	
	elseif event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		else
			this:Show()
		end
	end
	
end

function FunctionBarRight_2_UpdateComboFlash(Index, flash)
	local nIndex = tonumber(Index)
	local nflash = tonumber(flash)
	if(nflash == 1) then
		if not COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[Index]:IsVisible() then
			COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[Index]:Show()
			COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[Index]:Hide()
		end
		elseif (nflash == 2) then
			if not COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[Index]:IsVisible() then
				COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[Index]:Hide()
				COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[Index]:Show()
			end
		else
			COMBOSKILL_RIGHTBAR_2_FLASH_JUNIOR[Index]:Hide()
			COMBOSKILL_RIGHTBAR_2_FLASH_SENIOR[Index]:Hide()
		end	
end




function FunctionBarRight_2_ActionUpdate()
	for j=1,9 do
		RIGHTBAR_2_BUTTONS[j+60]:SetNewFlash();
	end
end

function FunctionBarRight_2_Clicked(nIndex)
	if DataPool:IsCanDoAction() then
		
		RIGHTBAR_2_BUTTONS[nIndex]:DoAction();
	else
		PushDebugMessage("你不能这么做。")
		return;
	end
end

function FunctionBarRight_2_UnInstallChatActionButton(index)

	if (index < 0) or (index > 10) then
		return
	end

	-- 得到要卸载的动作包信息
	local actionID, actionValidDate, actionCount, actionMinIndex, actionType = DataPool : Get_RMB_ChatActionInfo(index);
	local realActionID = DataPool : Get_RMB_ChatActionRealID(actionID);
	if realActionID > 0 and actionCount > 0 and actionMinIndex > 0 and actionType > 0 then
		local tmpItem = -1
		-- 清空快捷栏上每一个包含动作包按钮的信息
		for i = 1, RIGHTBAR_2_BUTTON_NUM do
			-- 得到当前ActionItem在ActionItem总表中的编号
		  tmpItem = RIGHTBAR_2_BUTTONS[i+60]:GetActionItem();
		  if (tmpItem ~= -1) then
		  	-- 遍历当前动作包中的每一个ActionItem，看看是否有和当前ActionItem的ID相等的。
		  	for j = 1, actionCount do
					local theAction = nil
					if actionType == 2 then
						theAction = Talk : EnumDoubleChatMood(actionMinIndex + j - 2);
					else 
						theAction = Talk : EnumChatMood(actionMinIndex + j - 2);
					end
					if (theAction:GetID() ~= 0) and (theAction:GetID() == tmpItem) then
						RIGHTBAR_2_BUTTONS[i+60] : SetActionItem(-1);				-- 取消按钮上的ActionItem
						DataPool : UnInstall_RMB_ChatAction_BarItem(i+59);			-- 删除MainMenuBar中保存的ActionItem对应记录（编号对应DragName）
					end
				end
		  end
		end
	end	

	-- 彻底卸载该动作包
	DataPool : UnInstall_RMB_ChatAction(index , 5)

end

function FunctionBarRight_2_ClearChatActionButton(index, nID, nData)

	if (index < 0) or (index > 10) then
		return
	end

	-- 得到要卸载的动作包信息
	local actionID, actionValidDate, actionCount, actionMinIndex, actionType = DataPool : Get_RMB_ChatActionInfo(index);
	--PushDebugMessage ("FunctionBarRight_2 : actionID = "..actionID..", actionCount = "..actionCount..", actionMinIndex = "..actionMinIndex)
	local realActionID = DataPool : Get_RMB_ChatActionRealID(actionID);
	if realActionID > 0 and actionCount > 0 and actionMinIndex > 0 and actionType > 0 then
		local tmpItem = -1
		-- 清空快捷栏上每一个包含动作包按钮的信息
		for i = 1, RIGHTBAR_2_BUTTON_NUM do
			-- 得到当前ActionItem在ActionItem总表中的编号
		  tmpItem = RIGHTBAR_2_BUTTONS[i+60]:GetActionItem();
		  if (tmpItem ~= -1) then
		  	-- 遍历当前动作包中的每一个ActionItem，看看是否有和当前ActionItem的ID相等的。
		  	for j = 1, actionCount do
					local theAction = nil
					if actionType == 2 then
						theAction = Talk : EnumDoubleChatMood(actionMinIndex + j - 2);
					else 
						theAction = Talk : EnumChatMood(actionMinIndex + j - 2);
					end
					if (theAction:GetID() ~= 0) and (theAction:GetID() == tmpItem) then
						RIGHTBAR_2_BUTTONS[i+60] : SetActionItem(-1);							-- 取消按钮上的ActionItem
						DataPool : UnInstall_RMB_ChatAction_BarItem(i+59);			-- 删除MainMenuBar中保存的ActionItem对应记录（编号对应DragName）
					end
				end
		  end
		end
	end
	
	-- 继续清理 FunctionBarRight 界面上的动作包按钮
	DataPool : Clear_ChatAction_Bar("MainMenuBar_4", index, nID, nData);

end