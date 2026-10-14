
--最多显示的效果数量
local MESSAGE_BALL_GUIDS = {0,0,0};
local MESSAGE_BALL_BUTTONS = {};

function NewMessageBall_PreLoad()
	this:RegisterEvent("MSG_BALL_UPDATE");
	this:RegisterEvent("SWITCH_MENU_BUTTON");
	--this:RegisterEvent("UPDATE_FRESHMAN_POSITION");
	--this:RegisterEvent("UPDATE_NEWMESSAGEBALL_POSITION");
	this:RegisterEvent("FRESHMAN_CHANGESTATE");
end

function NewMessageBall_OnLoad()

	MESSAGE_BALL_BUTTONS[1] = NewMessageBall_Button_Action1_Mask;
	MESSAGE_BALL_BUTTONS[2] = NewMessageBall_Button_Action2_Mask;
	MESSAGE_BALL_BUTTONS[3] = NewMessageBall_Button_Action3_Mask;
	MESSAGE_BALL_BUTTONS[4] = NewMessageBall_Button_Action4_Mask;
	MESSAGE_BALL_BUTTONS[5] = NewMessageBall_Button_Action5_Mask;
end

function NewMessageBall_OnEvent(event)

	if ( event == "MSG_BALL_UPDATE" ) then
		NewMsgBallUpadate();
	end
	
	if (event == "SWITCH_MENU_BUTTON") then
		NewMessageBall_UpdatePos(0)
	end

	--if (event == "UPDATE_FRESHMAN_POSITION") then
		--NewMessageBall_UpdatePos(0)
	--end
	
	if (event == "FRESHMAN_CHANGESTATE") then
		NewMessageBall_UpdatePos(0)
	end	
end

function NewMsgBallUpadate()		

		this:Show();
		
		local szIconName = ""
		local szToolTips = "";
		local szIndex	 = 0;
		local msgType	= 0;
		local i = 0;
		local Rt = 0;

		local idx = 1;
		
		MESSAGE_BALL_BUTTONS[1]:Hide()
		MESSAGE_BALL_BUTTONS[2]:Hide()
		MESSAGE_BALL_BUTTONS[3]:Hide()
		MESSAGE_BALL_BUTTONS[4]:Hide()
		MESSAGE_BALL_BUTTONS[5]:Hide()

		for i=0,5 do
			Rt, szIconName = MsgBall("GetStrAttrByIdx", i, "ICON");
			Rt, szToolTips = MsgBall("GetStrAttrByIdx", i, "TOOLTIP");
			Rt, szIndex    = MsgBall("GetNumAttrByIdx", i, "GUID");
			Rt, msgType    = MsgBall("GetTypeByIdx" , i);
			if(Rt == 1 ) then
				if msgType > 0 and msgType < 6 then
					MESSAGE_BALL_BUTTONS[msgType]:SetProperty("Animate", szIconName)
					MESSAGE_BALL_BUTTONS[msgType]:SetToolTip(szToolTips);
					MESSAGE_BALL_BUTTONS[msgType]:Show();
					MESSAGE_BALL_GUIDS[msgType] = szIndex
				end
				
--				if msgType ~= 0  and idx < 4 then
--					MESSAGE_BALL_BUTTONS[idx]:SetProperty("Animate", szIconName)
--					MESSAGE_BALL_BUTTONS[idx]:SetToolTip(szToolTips);
--					MESSAGE_BALL_BUTTONS[idx]:Show();
--					MESSAGE_BALL_GUIDS[idx] = szIndex
--					idx = idx + 1
--				end
--			else
--				if idx < 4 then
--					MESSAGE_BALL_BUTTONS[idx]:Hide();
--					idx = idx + 1
--				end
			end

		end
end

function NewMessageBall_Button_Action1_Mask_Click()
	MsgBall("OnEventByGuid", MESSAGE_BALL_GUIDS[1]);
end

function NewMessageBall_Button_Action2_Mask_Click()
	MsgBall("OnEventByGuid", MESSAGE_BALL_GUIDS[2]);
end

function NewMessageBall_Button_Action3_Mask_Click()
	MsgBall("OnEventByGuid", MESSAGE_BALL_GUIDS[3]);
end

function NewMessageBall_Button_Action4_Mask_Click()
	MsgBall("OnEventByGuid", MESSAGE_BALL_GUIDS[4]);
end

function NewMessageBall_Button_Action5_Mask_Click()
	MsgBall("OnEventByGuid", MESSAGE_BALL_GUIDS[5]);
end

function NewMessageBall_UpdatePos( nValue)--注意：还没添加新人奖励界面及玄灵宝箱界面
	local bValid = 0
	if IsWindowShow("FreshmanWatch") == true or IsWindowShow("PlayerBonus") == true then
		bValid = 1
	end
	if IsWindowShow("MainMenuBar_4") == true and bValid == 1 then		--主快捷栏上有两排快捷栏+玄灵宝箱或新人领奖
		NewMessageBall_Frame:SetProperty("UnifiedPosition", "{{0.500000,-72.000000},{1.000000,-291.000000}}");
	elseif IsWindowShow("MainMenuBar_4") == true and bValid ~= 1 then--主快捷栏上有两排快捷栏，但是没有玄灵宝箱或新人领奖
		NewMessageBall_Frame:SetProperty("UnifiedPosition","{{0.500000,-72.000000},{1.000000,-202.000000}}")
	elseif bValid == 1 and IsWindowShow("MainMenuBar_2") == true then--主快捷栏上有一排快捷栏+玄灵宝箱或新人领奖
    NewMessageBall_Frame:SetProperty("UnifiedPosition", "{{0.500000,-72.000000},{1.000000,-255.000000}}");
  elseif bValid == 1 and IsWindowShow("MainMenuBar_2") == false then--主快捷栏上有玄灵宝箱或新人领奖，但是没有快捷栏
    NewMessageBall_Frame:SetProperty("UnifiedPosition", "{{0.500000,-72.000000},{1.000000,-219.000000}}");
  elseif IsWindowShow("MainMenuBar_2") == true then									--主快捷栏上有一排快捷栏，但是没有玄灵宝箱或新人领奖
    NewMessageBall_Frame:SetProperty("UnifiedPosition", "{{0.500000,-72.000000},{1.000000,-166.000000}}");
	else 																														--主快捷栏上没有快捷栏，也没有玄灵宝箱或新人领奖
		NewMessageBall_Frame:SetProperty("UnifiedPosition","{{0.500000,-72.000000},{1.000000,-130.000000}}")
	end
end
