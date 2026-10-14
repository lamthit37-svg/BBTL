--SpringFestival_RedPacket.lua
local g_SpringFestival_RedPacket_Frame_UnifiedPosition;

local g_SpringFestival_RedPacket_bright = {};
local g_SpringFestival_RedPacket_disable = {};
local g_SpringFestival_RedPacket_HuoDongTips={};


function SpringFestival_RedPacket_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function SpringFestival_RedPacket_OnLoad()
	g_SpringFestival_RedPacket_Frame_UnifiedPosition=SpringFestival_RedPacket:GetProperty("UnifiedPosition");
	
	g_SpringFestival_RedPacket_bright[1] = SpringFestival_RedPacket1;
	g_SpringFestival_RedPacket_bright[2] = SpringFestival_RedPacket2;
	g_SpringFestival_RedPacket_bright[3] = SpringFestival_RedPacket3;
	g_SpringFestival_RedPacket_bright[4] = SpringFestival_RedPacket4;
	g_SpringFestival_RedPacket_bright[5] = SpringFestival_RedPacket5;
	g_SpringFestival_RedPacket_bright[6] = SpringFestival_RedPacket6;
	g_SpringFestival_RedPacket_bright[7] = SpringFestival_RedPacket7;
	g_SpringFestival_RedPacket_bright[8] = SpringFestival_RedPacket8;
	
	g_SpringFestival_RedPacket_disable[1] = SpringFestival_RedPacket1_Dis;
	g_SpringFestival_RedPacket_disable[2] = SpringFestival_RedPacket2_Dis;
	g_SpringFestival_RedPacket_disable[3] = SpringFestival_RedPacket3_Dis;
	g_SpringFestival_RedPacket_disable[4] = SpringFestival_RedPacket4_Dis;
	g_SpringFestival_RedPacket_disable[5] = SpringFestival_RedPacket5_Dis;
	g_SpringFestival_RedPacket_disable[6] = SpringFestival_RedPacket6_Dis;
	g_SpringFestival_RedPacket_disable[7] = SpringFestival_RedPacket7_Dis;
	g_SpringFestival_RedPacket_disable[8] = SpringFestival_RedPacket8_Dis;
	
	g_SpringFestival_RedPacket_HuoDongTips[1] = { notget="#{CJHB_181207_10}", get="#{CJHB_181207_11}" };
	g_SpringFestival_RedPacket_HuoDongTips[2] = { notget="#{CJHB_181207_51}", get="#{CJHB_181207_61}" };
	g_SpringFestival_RedPacket_HuoDongTips[3] = { notget="#{CJHB_181207_52}", get="#{CJHB_181207_62}" };
	g_SpringFestival_RedPacket_HuoDongTips[4] = { notget="#{CJHB_181207_53}", get="#{CJHB_181207_63}" };
	g_SpringFestival_RedPacket_HuoDongTips[5] = { notget="#{CJHB_181207_54}", get="#{CJHB_181207_64}" };
	g_SpringFestival_RedPacket_HuoDongTips[6] = { notget="#{CJHB_181207_55}", get="#{CJHB_181207_65}" };
	g_SpringFestival_RedPacket_HuoDongTips[7] = { notget="#{CJHB_181207_56}", get="#{CJHB_181207_66}" };
	g_SpringFestival_RedPacket_HuoDongTips[8] = { notget="#{CJHB_181207_49}", get="#{CJHB_181207_67}" };
	
	for i=1, 8 do
		g_SpringFestival_RedPacket_bright[i]:Hide();
		g_SpringFestival_RedPacket_disable[i]:Show();
	end
end

function SpringFestival_RedPacket_OnEvent(event)
	if (event == "UI_COMMAND") and (arg0 == "89302502") then
		if Get_XParam_INT(0) == 1 then
			this:Show()
		else
			this:Hide()
		end
		--二维码的内容
		if Get_XParam_INT(1) == 1 then
			SpringFestival_RedPacket_QRText:SetText("#{CJHB_181207_15}");
		else
			SpringFestival_RedPacket_QRText:SetText("#{CJHB_181207_16}");
		end
		--红包种类个数
		local nCount = 0;
		for i=1, 8 do
			local nState = Get_XParam_INT(i+1)
			local nActive = math.floor(nState / 100);
			local nItemCount = math.mod( nState, 100 );
			if nActive > 0 then
				nCount = nCount + 1;
				-- 已激活
				g_SpringFestival_RedPacket_bright[i]:Show()
				g_SpringFestival_RedPacket_disable[i]:Hide()
			else
				--未激活
				g_SpringFestival_RedPacket_bright[i]:Hide()
				g_SpringFestival_RedPacket_disable[i]:Show()
			end
			
			if nItemCount > 0 then
				local szTips = g_SpringFestival_RedPacket_HuoDongTips[i];
				if szTips ~= nil then
					g_SpringFestival_RedPacket_disable[i]:SetToolTip(szTips.get);
				end
			else
				--未获取此红包
				local szTips = g_SpringFestival_RedPacket_HuoDongTips[i];
				if szTips ~= nil then
					g_SpringFestival_RedPacket_disable[i]:SetToolTip(szTips.notget);
				end
			end
		end
		local strMsg = ScriptGlobal_Format("#{CJHB_181207_14}", nCount)
		SpringFestival_RedPacket_Collect:SetText(strMsg);
		
	elseif (event == "ADJEST_UI_POS" ) then
		SpringFestival_RedPacket_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_RedPacket_Frame_On_ResetPos()
	
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		SpringFestival_RedPacket_Close()
		
	end
end

function SpringFestival_RedPacket_Help()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ShowAboutWXSpringHongBao");
		Set_XSCRIPT_ScriptID(893025);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

function SpringFestival_RedPacket_Close()
	this:Hide()
end

function SpringFestival_RedPacket_Frame_On_ResetPos()
  SpringFestival_RedPacket:SetProperty("UnifiedPosition", g_SpringFestival_RedPacket_Frame_UnifiedPosition);
end