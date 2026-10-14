-- ***************************************************************
--
-- 电话密保的错误提示界面
--
-- ***************************************************************


-- 注册onLoad事件
function TelMiBaoErrMsg_PreLoad()
	
	-- 打开界面
	this:RegisterEvent("OPEN_WINDOW");
	
	-- 关闭界面
	this:RegisterEvent("CLOSE_WINDOW");
	
end

-- OnLoad
function TelMiBaoErrMsg_OnLoad()	
	-- 设置总是在最上层显示
	TelMiBaoErrMsg_Frame_sub:SetProperty("AlwaysOnTop", "True");
end

-- 重新设置界面尺寸
function TelMiBaoErrMsg_UpdateRect()
	local nWidth, nHeight = TelMiBaoErrMsg_InfoWindow:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 25;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	TelMiBaoErrMsg_Frame_sub:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );	
end

-- OnEvent
function TelMiBaoErrMsg_OnEvent(event)
	
	-- 打开界面
	if (event == "OPEN_WINDOW") then		
		if( arg0 == "TelMiBaoErrMsg") then
			TelMiBaoErrMsg_Open();			
		end
		
	-- 关闭界面
	elseif (event == "CLOSE_WINDOW") then
		if( arg0 == "TelMiBaoErrMsg") then
			TelMiBaoErrMsg_Frame_OnHiden();
		end
	end

end

-- 打开界面
function TelMiBaoErrMsg_Open()		
	TelMiBaoErrMsg_InfoWindow:SetText("#{DHMB_90417_14}");
	TelMiBaoErrMsg_InfoWindow:Show();
	TelMiBaoErrMsg_UpdateRect();	
	this:Show();
end

-- “确定”按钮点击事件
function TelMiBaoErrMsg_BnClick()
	TelMiBaoErrMsg_InfoWindow:SetText("");	
	this:Hide();
end

-- 隐藏界面
function TelMiBaoErrMsg_Frame_OnHiden()
	TelMiBaoErrMsg_InfoWindow:SetText("");	
	this:Hide();
end