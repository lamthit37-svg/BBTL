

function FangDaohao_PreLoad()
	this:RegisterEvent("OPENDLG_FANGDAOHAO");
	this:RegisterEvent("CLOSEDLG_FANGDAOHAO");
end

function FangDaohao_OnLoad()
end

function FangDaohao_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	--PushDebugMessage("server传过来的数据有问题。");
	if ( event == "OPENDLG_FANGDAOHAO") then
		local SetMode = tonumber(arg0);
		if SetMode == 1 then 
			-- 1 is man set, 2 is auto set
			FangDaohao_Self_Text:SetText("#{DHMB_091109_01}");
		else
			FangDaohao_Self_Text:SetText("#{DHMB_8821_26}");
		end
		this:Show();
	elseif( event == "CLOSEDLG_FANGDAOHAO" ) then
		this:Hide();
	end
end

function FangDaohao_Update()
end

function FangDaohao_gotoWeb()
	GameProduceLogin:OpenURL(GetWeblink("WEB_FANGDAO"))
end

function FangDaohao_Close()
	--this:Hide()
end
