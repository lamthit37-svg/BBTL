
local RIGHTBAR_BUTTONS = {};
local RIGHTBAR_BUTTON_NUM = 9;

local COMBOSKILL_RIGHTBAR_FLASH_JUNIOR = {};
local COMBOSKILL_RIGHTBAR_FLASH_SENIOR = {};

function FunctionBarRight_PreLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true);
	this:RegisterEvent("CHANGE_BAR",true);
	this:RegisterEvent("ACTION_UPDATE",false);
	this:RegisterEvent("UNINSTALL_CHAT_ACTION_BAR3",true);
	this:RegisterEvent("CLEAR_CHAT_ACTION_BAR",true);
	this:RegisterEvent("SHOW_TRANSFIGURATION_SKILL",true);
	this:RegisterEvent("FLASH_COMBOSKILL",true);
	this:RegisterEvent("HIDE_THIS_UI",true)				-- 隐藏界面
end

function FunctionBarRight_OnLoad()

	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[41] = FunctionBarRight_Function_Button1_junior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[42] = FunctionBarRight_Function_Button2_junior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[43] = FunctionBarRight_Function_Button3_junior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[44] = FunctionBarRight_Function_Button4_junior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[45] = FunctionBarRight_Function_Button5_junior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[46] = FunctionBarRight_Function_Button6_junior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[47] = FunctionBarRight_Function_Button7_junior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[48] = FunctionBarRight_Function_Button8_junior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[49] = FunctionBarRight_Function_Button9_junior_Flash;
	
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[41] = FunctionBarRight_Function_Button1_senior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[42] = FunctionBarRight_Function_Button2_senior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[43] = FunctionBarRight_Function_Button3_senior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[44] = FunctionBarRight_Function_Button4_senior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[45] = FunctionBarRight_Function_Button5_senior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[46] = FunctionBarRight_Function_Button6_senior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[47] = FunctionBarRight_Function_Button7_senior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[48] = FunctionBarRight_Function_Button8_senior_Flash;
	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[49] = FunctionBarRight_Function_Button9_senior_Flash;
	
	
	RIGHTBAR_BUTTONS[41] = FunctionBarRight_Button_Action1;
	RIGHTBAR_BUTTONS[42] = FunctionBarRight_Button_Action2;
	RIGHTBAR_BUTTONS[43] = FunctionBarRight_Button_Action3;
	RIGHTBAR_BUTTONS[44] = FunctionBarRight_Button_Action4;
	RIGHTBAR_BUTTONS[45] = FunctionBarRight_Button_Action5;
	RIGHTBAR_BUTTONS[46] = FunctionBarRight_Button_Action6;
	RIGHTBAR_BUTTONS[47] = FunctionBarRight_Button_Action7;
	RIGHTBAR_BUTTONS[48] = FunctionBarRight_Button_Action8;
	RIGHTBAR_BUTTONS[49] = FunctionBarRight_Button_Action9;
end

-- OnEvent
function FunctionBarRight_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end

	if ZBS:IsViewerWatching() > 0 then
		this:Hide()
		return
	end
	
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		this:Show();
	elseif( event == "CHANGE_BAR" and arg0 == "mainreset") then	
		local count=tonumber(arg1)+2;
		for i=3,count do
			local nIndex=tonumber(eventTable[i]);
			if( nIndex > 40 and nIndex <50 )  then			
				RIGHTBAR_BUTTONS[nIndex] : SetActionItem(-1);
				RIGHTBAR_BUTTONS[nIndex] : Bright();
			end
			if nIndex > 40 and  nIndex < 50 and RIGHTBAR_BUTTONS[nIndex]:IsVisible() then
				if 	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[nIndex]:IsVisible() then
					COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[nIndex]:Hide()
				end
				if 	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[nIndex]:IsVisible() then
					COMBOSKILL_RIGHTBAR_FLASH_SENIOR[nIndex]:Hide()
				end
			end
		end
	elseif( event == "CHANGE_BAR" and arg0 == "main") then
		Target:UpdateActionButton()
		if( tonumber(arg1) > 40 and tonumber(arg1) <50 )  then
			local nIndex = tonumber(arg1) ;

			RIGHTBAR_BUTTONS[nIndex] : SetActionItem(tonumber(arg2));
			RIGHTBAR_BUTTONS[nIndex] : Bright();
			
			if arg3~=nil then
				
				local pet_num = tonumber(arg3);
				
				if pet_num >= 0 and pet_num < 6 then
					if Pet : IsPresent(pet_num) and Pet : GetIsFighting(pet_num) then
							RIGHTBAR_BUTTONS[nIndex] : Bright();
					else
							RIGHTBAR_BUTTONS[nIndex] : Gloom();
					end
						
				end
				
			end
			
		end
		local nIndex = tonumber(arg1)
		if nIndex > 40 and  nIndex < 50 and RIGHTBAR_BUTTONS[nIndex]:IsVisible() then
			if 	COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[nIndex]:IsVisible() then
				COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[nIndex]:Hide()
			end
			if 	COMBOSKILL_RIGHTBAR_FLASH_SENIOR[nIndex]:IsVisible() then
				COMBOSKILL_RIGHTBAR_FLASH_SENIOR[nIndex]:Hide()
			end
		end				
		
	elseif( event == "ACTION_UPDATE" ) then
		FunctionBarRight_ActionUpdate();

	-- 卸载双人休闲动作包时，同时删除拖动到FunctionBarRight上的按钮信息	
	elseif (event == "UNINSTALL_CHAT_ACTION_BAR3") then
		FunctionBarRight_UnInstallChatActionButton(tonumber(arg0));

	-- 清理过期的双人休闲动作包在主菜单上的按钮
	elseif (event == "CLEAR_CHAT_ACTION_BAR") and (tostring(arg0)== "FunctionBarRight") then
		FunctionBarRight_ClearChatActionButton(tonumber(arg1), tonumber(arg2), tonumber(arg3));
	elseif event == "SHOW_TRANSFIGURATION_SKILL" then
		if arg0 == "2" then
			this:Hide()
		elseif arg0 == "0" then
			this:Show()
		end
	elseif (event == "FLASH_COMBOSKILL") then
		local Index = tonumber(arg0)
		local flash = tonumber(arg1)
		
		if Index > 40 and Index < 50 then
			FunctionBarRight_UpdateComboFlash(Index, flash)
		end		
	elseif event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		else
			this:Show()
		end
	end
	
end

function FunctionBarRight_UpdateComboFlash(Index, flash)
	local nIndex = tonumber(Index)
	local nflash = tonumber(flash)
	if(nflash == 1) then
		if not COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[Index]:IsVisible() then
			COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[Index]:Show()
			COMBOSKILL_RIGHTBAR_FLASH_SENIOR[Index]:Hide()
		end
		elseif (nflash == 2) then
			if not COMBOSKILL_RIGHTBAR_FLASH_SENIOR[Index]:IsVisible() then
				COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[Index]:Hide()
				COMBOSKILL_RIGHTBAR_FLASH_SENIOR[Index]:Show()
			end
		else
			COMBOSKILL_RIGHTBAR_FLASH_JUNIOR[Index]:Hide()
			COMBOSKILL_RIGHTBAR_FLASH_SENIOR[Index]:Hide()
		end	
end


function FunctionBarRight_ActionUpdate()
	for j=1,9 do
		RIGHTBAR_BUTTONS[j+40]:SetNewFlash();
	end
end

function FunctionBarRight_Clicked(nIndex)
	if DataPool:IsCanDoAction() then
		
		RIGHTBAR_BUTTONS[nIndex]:DoAction();
	else
		PushDebugMessage("你不能这么做。")
		return;
	end
end

function FunctionBarRight_UnInstallChatActionButton(index)

	if (index < 0) or (index > 10) then
		return
	end

	-- 得到要卸载的动作包信息
	local actionID, actionValidDate, actionCount, actionMinIndex, actionType = DataPool : Get_RMB_ChatActionInfo(index);
	local realActionID = DataPool : Get_RMB_ChatActionRealID(actionID);
	if realActionID > 0 and actionCount > 0 and actionMinIndex > 0 and actionType > 0 then
		local tmpItem = -1
		-- 清空快捷栏上每一个包含动作包按钮的信息
		for i = 1, RIGHTBAR_BUTTON_NUM do
			-- 得到当前ActionItem在ActionItem总表中的编号
		  tmpItem = RIGHTBAR_BUTTONS[i+40]:GetActionItem();
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
						RIGHTBAR_BUTTONS[i+40] : SetActionItem(-1);							-- 取消按钮上的ActionItem
						DataPool : UnInstall_RMB_ChatAction_BarItem(i+39);			-- 删除MainMenuBar中保存的ActionItem对应记录（编号对应DragName）
					end
				end
		  end
		end
	end	

	-- 接着删除 FunctionBarRight_2 界面上的控件
	DataPool : UnInstall_RMB_ChatAction(index , 4)

end

function FunctionBarRight_ClearChatActionButton(index, nID, nData)

	if (index < 0) or (index > 10) then
		return
	end

	-- 得到要卸载的动作包信息
	local actionID, actionValidDate, actionCount, actionMinIndex, actionType = DataPool : Get_RMB_ChatActionInfo(index);
	--PushDebugMessage ("FunctionBarRight : actionID = "..actionID..", actionCount = "..actionCount..", actionMinIndex = "..actionMinIndex)
	local realActionID = DataPool : Get_RMB_ChatActionRealID(actionID);
	if realActionID > 0 and actionCount > 0 and actionMinIndex > 0 and actionType > 0 then
		local tmpItem = -1
		-- 清空快捷栏上每一个包含动作包按钮的信息
		for i = 1, RIGHTBAR_BUTTON_NUM do
			-- 得到当前ActionItem在ActionItem总表中的编号
		  tmpItem = RIGHTBAR_BUTTONS[i+40]:GetActionItem();
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
						RIGHTBAR_BUTTONS[i+40] : SetActionItem(-1);							-- 取消按钮上的ActionItem
						DataPool : UnInstall_RMB_ChatAction_BarItem(i+39);			-- 删除MainMenuBar中保存的ActionItem对应记录（编号对应DragName）
					end
				end
		  end
		end
	end

	-- 继续清理 FunctionBarRight_2 界面上的动作包按钮
	DataPool : Clear_ChatAction_Bar("FunctionBarRight_2", index, nID, nData);

end