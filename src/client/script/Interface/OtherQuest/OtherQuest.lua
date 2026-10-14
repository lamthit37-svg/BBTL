local g_strforShow2;
local g_FrameVar2 = 0
local FrameInfoList2 = {
	QUENE_QUIT_COMFIRM 			= 1,			--排队相关提示
}
local g_FrameInfo2 = -1
local g_Type = 0;

function OtherQuest_PreLoad()
	this:RegisterEvent("QUENEQUIT_SELECT")
end

function OtherQuest_OnLoad()
	OtherQuest_Frame:SetProperty("AlwaysOnTop", "True");
end

function OtherQuestUpdateRect()
	local nWidth, nHeight = OtherQuest_Window:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 25;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	OtherQuest_Window:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

function OtherQuest_OnEvent(event)
	if (event == "QUENEQUIT_SELECT") then
		local nIndex =tonumber(arg0)
		g_strforShow2 = arg1;
		OtherQuest_Open_Window_QueneQuitConfirm(nIndex)
	end
end

function OtherQuest_Frame_OnHiden()
	DataPool:SetCanUseHotKey(1);
	g_FrameVar2 = 0
	g_FrameInfo2 = -1
end

function OtherQuest_Open_Window_QueneQuitConfirm(nIndex)
	g_FrameVar2 = nIndex
	if (nIndex == 234) then
		OtherQuest_Text:SetText( "#{XFPD_120216_03}");	-- 设置内容
		g_Type = 0;
	--elseif (nIndex == 134) then
	--	OtherQuest_Text:SetText( "#{XFPD_120216_04}");	-- 设置内容
	--	g_Type = 0;
	elseif (nIndex == 135) then
		OtherQuest_Text:SetText( "#{XFPD_120216_04}");	-- 设置内容
		g_Type = 1;
	end
	g_FrameInfo2 = FrameInfoList2.QUENE_QUIT_COMFIRM
	OtherQuest_OK_Button:Show()
	OtherQuest_OK_Button:SetText("#{INTERFACE_XML_557}");  --确定
	OtherQuest_Cancel_Button:Show()
	OtherQuest_Cancel_Button:SetText("#{INTERFACE_XML_542}");  --取消
	--OtherQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function OtherQuest__Ok_Clicked()
	if (g_FrameInfo == FrameInfoList.QUENE_QUIT_COMFIRM) then
		OtherQuest_Open_Window_Clicked(g_FrameVar2)
	end
	this:Hide()
end

function OtherQuest_Cancel_Clicked()
	if (1 == g_Type) then
		if (g_FrameInfo2 == FrameInfoList2.QUENE_QUIT_COMFIRM) then
			PushEvent("GAMELOGIN_SHOW_QUEUEMSG_ASK_PHONE", g_strforShow2, "ShowButton")
			g_strforShow2 = nil
		end
	else
		if (g_FrameInfo2 == FrameInfoList2.QUENE_QUIT_COMFIRM) then
			PushEvent("GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON", g_strforShow2, "ShowButton")
			g_strforShow2 = nil
		end
	end
	
	this:Hide()
end

function OtherQuest_Open_Window_Clicked(nIndex)
	GameProduceLogin:SendQueneQuitMsg()
	
	--if nIndex == 134 then
	--	GameProduceLogin:ExitToSelectServer()
	--elseif nIndex == 234 then
	if nIndex == 234 then
		GameProduceLogin:EnterRecommendServerSelect()
	elseif nIndex == 135 then
		GameProduceLogin:EnterRecommendServerSelect()
	end
end