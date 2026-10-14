function SoftKeyBoard_PreLoad()
	this:RegisterEvent("OPEN_WINDOW",true);
	this:RegisterEvent("CLOSE_WINDOW",false);
	this:RegisterEvent("TOGGLE_WINDOW",true);
	this:RegisterEvent("SET_SOFTKEY_AIM",false);
end

-- 注册onLoad事件
function SoftKeyBoard_OnLoad()
end

function SoftKeyBoard_OnEvent(event)
    if( event == "OPEN_WINDOW" ) then
     	if( arg0 == "SoftKeyBoard" ) then
			SoftKeyBoard_Show();
		end
	elseif( event == "SET_SOFTKEY_AIM" ) then
     	SoftKeyBoard_SoftKey:SetAimEditBox( arg0 );
	-- 打开帐号输入界面
 	elseif( event == "CLOSE_WINDOW" ) then
		if( arg0 == "SoftKeyBoard" ) then
			SoftKeyBoard_Close();
		end
	elseif( event == "TOGGLE_WINDOW" ) then
		if( arg0 == "SoftKeyBoard" ) then
			if( this:IsVisible() ) then
				SoftKeyBoard_Close();
			else
				SoftKeyBoard_Show();
			end
		end
	end
	
end

function SoftKeyBoard_Show()

	this:Show();
end

function SoftKeyBoard_Close()

	this:Hide();
end
